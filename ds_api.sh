#!/bin/bash

# Replace with your API key
API_KEY="your_api_key"

# Initialize conversation history
HISTORY_FILE="$HOME/deepseek/conversation.json"

# System message
SYSTEM_MESSAGE="your_system_prompt"

# Initialize conversation history
if [[ -f "$HISTORY_FILE" ]]; then
    CONVO_HISTORY=$(cat "$HISTORY_FILE")
else
    CONVO_HISTORY='[
        {"role": "system", 
    "content": "'"$SYSTEM_MESSAGE"'"}
    ]'
    mkdir -p "$HOME/deepseek"
    echo "$CONVO_HISTORY" > "$HISTORY_FILE"
fi

echo "Chatbot; type 'exit' to quit"
while true; do
    read -p ">> " user_input
    [[ "$user_input" == "exit" ]] && break

    # Add user message to history
    CONVO_HISTORY=$(echo "$CONVO_HISTORY" | jq --arg msg "$user_input" '. += [{"role": "user", "content": $msg}]')
    echo "$CONVO_HISTORY" > "$HISTORY_FILE"

    # Call API WITH ACTUAL HISTORY
    response=$(curl -s https://api.deepseek.com/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d @- <<EOF
        {
            "model": "deepseek-reasoner",
            "max_tokens": 2000,
            "messages": $CONVO_HISTORY,
            "stream": false
        }
EOF
    )

    # Extract assistant reply
    assistant_reply=$(echo "$response" | jq -r '.choices[0].message.content')
   
    # Check for null response
    if [[ "$assistant_reply" == "null" ]]; then
        echo -e "\nMEMORY FULL: Please delete the memory file and restart:"
        echo "$HISTORY_FILE"
        exit 1 
    fi

    echo "*** $assistant_reply"

    # Add assistant reply to history
    CONVO_HISTORY=$(echo "$CONVO_HISTORY" | jq --arg msg "$assistant_reply" '. += [{"role": "assistant", "content": $msg}]')
    echo "$CONVO_HISTORY" > "$HISTORY_FILE"
done
