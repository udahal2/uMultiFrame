<#
Copyright Ujjwol © 2025
This script is designed for project management, including running, updating, and exiting applications.
Optimized for efficiency and enhanced with caching and additional functionality.
#>

param(
    $rule = "default"
)

<# NOTE: Update these variables to target different files with this script. #>
$MAIN = "src.app"
$CP_DELIM = ";"
if ( $IsMacOS -or $IsLinux ) {
    $CP_DELIM = ":" # changes to : for Mac or Linux
}

# Cache file for storing last updated or successful build branch
$cacheFile = ".build_cache.json"

# Function to get the current branch name
function Get-CurrentBranch {
    $branch = git rev-parse --abbrev-ref HEAD
    return $branch
}

# Function to cache build information
function CacheBuildInfo {
    param (
        [string]$branch
    )
    $cacheData = @{
        LastSuccessfulBranch = $branch
    }
    $cacheData | ConvertTo-Json | Set-Content -Path $cacheFile -Encoding UTF8
}

# Function to get cached build information
function GetCachedBuildInfo {
    if (Test-Path $cacheFile) {
        return (Get-Content -Path $cacheFile -Raw | ConvertFrom-Json).LastSuccessfulBranch
    }
    return $null
}

# ======================================================================== #

# Default rule handling (if no rule is passed)
if ( $rule -eq "" -or $rule -eq "default" ) {
    Write-Output "Default rule: Running update and exit in sequence."
    & $MyInvocation.MyCommand.Path "update"
    & $MyInvocation.MyCommand.Path "exit"
}

elseif ( $rule -eq "update" ) {
    Write-Output "Updating the application..."
    
    git add .
    $commitMessage = if ($args.Length -gt 0) { $args[0] } else { "updated" }
    git commit -m "$commitMessage"
    Write-Debug " ** committed ** "
    
    $currentBranch = Get-CurrentBranch
    git fetch origin $currentBranch
    git pull origin $currentBranch
    git push origin $currentBranch
    Write-Output " ** Pushing to GitHub in $currentBranch done..."

    # Cache the current branch as the last successful build
    CacheBuildInfo -branch $currentBranch
}

elseif ( $rule -eq "run" ) {
    Write-Output "Running the application..."

    # Check if it's a Python project
    if (Test-Path "requirements.txt") {
        Write-Output "Python project detected, starting Gunicorn server..."
        Start-Process "gunicorn" -ArgumentList "runner:app", "--bind", "0.0.0.0:10000"
        Start-Process "cmd.exe" -ArgumentList "/c start http://localhost:10000"
    }
    else {
        Write-Output "No Python project detected. Please specify 'run nodejs' if you want to run a Node.js project."
    }
}

elseif ( $rule -eq "run nodejs" ) {
    Write-Output "Running Node.js project..."

    if (Test-Path "package.json") {
        Write-Output "Starting existing Node.js application..."
        Start-Process "node" -ArgumentList "app.js"
    }
    else {
        Write-Output "Node.js project not found. Please initialize it first."
    }
}

elseif ( $rule -eq "exit" ) {
    Write-Output "Updating the application first..."
    Invoke-Expression "& { $($MyInvocation.MyCommand.Path) update }"

    Write-Output "Closing network ports and processes started by the project..."
    Get-Process | Where-Object { $_.ProcessName -match "gunicorn" } | Stop-Process -Force

    $port = 10000
    $netstatOutput = netstat -ano | FindStr $port
    if ($netstatOutput) {
        $pid = ($netstatOutput -split "\s+")[-1]
        if ($pid) {
            Stop-Process -Id $pid -Force
            Write-Output "Closed port $port and killed process with PID $pid."
        } else {
            Write-Output "No process found for port $port."
        }
    }
    Write-Output "Exiting the script. Goodbye!"
}

elseif ( $rule -eq "CTLFS" ) {
    Write-Output "Checking for last successful branch..."
    $lastBranch = GetCachedBuildInfo
    if ($lastBranch) {
        Write-Output "Switching to last successful branch: $lastBranch"
        git checkout $lastBranch
        git pull origin $lastBranch
        Write-Output "Branch updated successfully."
    } else {
        Write-Output "No cached branch found. Please ensure a successful build is cached."
    }
}

else {
    Write-Output "build: *** No rule to make target '$rule'.  Stop."
}
