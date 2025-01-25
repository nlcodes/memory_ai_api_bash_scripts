#!/bin/bash

# Replace with your api key
API_KEY="your_api_key_here"

# Initialize conversation history
HISTORY_FILE="$HOME/deepseek/ds_api_conversation.json"

# Initialize conversation history
if [[ -f "$HISTORY_FILE" ]]; then
    CONVO_HISTORY=$(cat "$HISTORY_FILE")
else
    CONVO_HISTORY='[
        {"role": "system", "content": "You are my personal ai helper; assist me"}
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

    # Call deepseek r1 model with api
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
    echo "*** $assistant_reply"

    # Add assistant reply to history
    CONVO_HISTORY=$(echo "$CONVO_HISTORY" | jq --arg msg "$assistant_reply" '. += [{"role": "assistant", "content": $msg}]')
    echo "$CONVO_HISTORY" > "$HISTORY_FILE"
done
