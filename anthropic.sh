#!/bin/bash

# Replace with your Anthropic API key
API_KEY="your_api_key"

# Initialize conversation history
HISTORY_FILE="$HOME/anthropic/conversation.json"

# Initialize conversation history
if [[ -f "$HISTORY_FILE" ]]; then
    CONVO_HISTORY=$(cat "$HISTORY_FILE")
else
    CONVO_HISTORY='[]'  # Start with an empty array
    mkdir -p "$HOME/anthropic"
    echo "$CONVO_HISTORY" > "$HISTORY_FILE"
fi

# System message (top-level parameter)
SYSTEM_MESSAGE="your_system_prompt"

echo "Chatbot; type 'exit' to quit"
while true; do
    read -p ">> " user_input
    [[ "$user_input" == "exit" ]] && break

    # Add user message to history
    CONVO_HISTORY=$(echo "$CONVO_HISTORY" | jq --arg msg "$user_input" '. += [{"role": "user", "content": $msg}]')
    echo "$CONVO_HISTORY" > "$HISTORY_FILE"

    # Call Anthropic API with Claude 3.5 Sonnet
    response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d @- <<EOF
        {
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 2000,
            "system": "$SYSTEM_MESSAGE",
            "messages": $CONVO_HISTORY
        }
EOF
    )

    # Extract assistant reply
    assistant_reply=$(echo "$response" | jq -r '.content[0].text // "Error: Invalid response"')
    echo "*** $assistant_reply"

    # Add assistant reply to history
    CONVO_HISTORY=$(echo "$CONVO_HISTORY" | jq --arg msg "$assistant_reply" '. += [{"role": "assistant", "content": $msg}]')
    echo "$CONVO_HISTORY" > "$HISTORY_FILE"
done
