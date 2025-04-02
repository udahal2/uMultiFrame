import os
from camel.societies import RolePlaying
from camel.utils import print_text_animated

# Ensure the OpenAI API key is set
assert 'OPENAI_API_KEY' in os.environ, "Please set the OPENAI_API_KEY environment variable."

def main():
    # Define the task prompt
    task_prompt = "Analyze the latest trends in renewable energy and provide insights."

    # Initialize the RolePlaying session with two agents
    role_play_session = RolePlaying(
        assistant_role_name="Energy Analyst",
        user_role_name="Environmental Journalist",
        task_prompt=task_prompt,
    )

    # Reset the session
    role_play_session.reset()

    # Define a chat turn limit
    chat_turn_limit, chat_turn = 10, 0

    # Start the conversation loop
    while chat_turn < chat_turn_limit:
        # Step the conversation
        result = role_play_session.step()
        if result.terminated:
            print("Conversation ended.")
            break
        chat_turn += 1

    # Introduce an element of surprise: Generate a creative story based on the analysis
    surprise_prompt = (
        "Based on the insights provided by the Energy Analyst, craft a compelling short story "
        "about a future world powered entirely by renewable energy."
    )
    story = role_play_session.assistant_agent.model.generate(surprise_prompt)
    print_text_animated(f"\nSurprise Story:\n{story}")

if __name__ == "__main__":
    main()
