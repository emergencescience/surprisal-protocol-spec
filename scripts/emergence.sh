#!/bin/bash

# Emergence CLI Tool - Secure Version
# Distribution: curl -L https://emergence.science/scripts/emergence -o emergence && chmod +x emergence

VERSION="1.2.0"
CONFIG_DIR="$HOME/.emergence"
CONFIG_FILE="$CONFIG_DIR/credentials.json"
API_URL=${EMERGENCE_API_URL:-"https://api.emergence.science"}

# Helper: Read value from JSON config
get_config_val() {
    local key=$1
    if [ -f "$CONFIG_FILE" ]; then
        python3 -c "import json, os; print(json.load(open('$CONFIG_FILE')).get('$key', ''))" 2>/dev/null
    fi
}

# Resolve API_KEY: priority Env Var > Config File
API_KEY=${EMERGENCE_API_KEY:-$(get_config_val "api_key")}

# Helper: JSON escape a string
json_escape() {
    python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}

# Helper: Generate a UUID
generate_uuid() {
    python3 -c 'import uuid; print(uuid.uuid4())'
}

show_help() {
    echo "Emergence CLI v$VERSION"
    echo "Usage: emergence [command] [options]"
    echo ""
    echo "Commands:"
    echo "  auth init               Initialize credentials"
    echo "  render <engine> <code>  Render a diagram (mermaid, d2, graphviz, tikz)"
    echo "  bounties list           List available bounties"
    echo "  bounties get <id>       Get bounty details"
    echo "  bounties create <title> <desc> <reward> [template] [spec]"
    echo "  bounties submit <id> <solution> [commentary]"
    echo "  bounties mine           List your submissions"
    echo "  bounties solution <id>  View solution for a bounty"
    echo "  balance                 Check your credit balance"
    echo "  transactions            View transaction history"
    echo "  version                 Show version info"
    echo "  update                  Self-update the CLI tool"
    echo ""
    echo "Options:"
    echo "  --format <ext>          Output format (png, svg, pdf). Default: png"
    echo ""
    echo "Environment:"
    echo "  EMERGENCE_API_KEY       Override stored API key"
}

check_auth() {
    if [ -z "$API_KEY" ]; then
        echo "Error: API Key not found."
        echo "Run 'emergence auth init' or set EMERGENCE_API_KEY environment variable."
        exit 1
    fi
}

auth_init() {
    mkdir -p "$CONFIG_DIR"
    echo "Enter your Emergence API Key:"
    read -s KEY
    if [ -z "$KEY" ]; then
        echo "Error: Key cannot be empty."
        exit 1
    fi
    echo "{\"api_key\": \"$KEY\"}" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "Credentials saved to $CONFIG_FILE"
}

render() {
    check_auth
    ENGINE=$1
    CODE=$2
    FORMAT=${3:-"png"}

    if [ -z "$ENGINE" ] || [ -z "$CODE" ]; then
        echo "Usage: emergence render <engine> <code>"
        exit 1
    fi

    echo "Rendering $ENGINE diagram..." >&2

    RESPONSE=$(curl -s -X POST "$API_URL/tools/render" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"engine\": \"$ENGINE\",
            \"code\": \"$(printf '%s' "$CODE" | json_escape)\",
            \"format\": \"$FORMAT\"
        }")

    STATUS=$(echo "$RESPONSE" | jq -r '.status')

    if [ "$STATUS" == "success" ]; then
        echo "$RESPONSE" | jq -r '.data.image_base64' | base64 -d > "output.$FORMAT"
        echo "Success! Saved to output.$FORMAT"
        echo "$RESPONSE" | jq -r '.billing'
    else
        echo "Error: $(echo "$RESPONSE" | jq -r '.detail')"
        exit 1
    fi
}

# Helper: Read from file if exists, otherwise return string
read_if_file() {
    if [ -n "$1" ] && [ -f "$1" ]; then
        cat "$1"
    else
        echo "$1"
    fi
}

bounties() {
    SUB=$1
    shift
    case "$SUB" in
        list)
            STATUS=${1:-"open"}
            curl -s "$API_URL/bounties?status=$STATUS" | jq .
            ;;
        get)
            ID=$1
            if [ -z "$ID" ]; then echo "Usage: emergence bounties get <id>"; exit 1; fi
            curl -s "$API_URL/bounties/$ID" | jq .
            ;;
        create)
            check_auth
            TITLE=$1
            DESC=$(read_if_file "$2")
            REWARD=$3
            TEMPLATE=$(read_if_file "$4")
            SPEC=$(read_if_file "$5")
            if [ -z "$TITLE" ] || [ -z "$DESC" ] || [ -z "$REWARD" ]; then
                echo "Usage: emergence bounties create <title> <desc> <reward> [template] [spec]"
                exit 1
            fi
            
            PAYLOAD="{
                \"title\": \"$(printf '%s' "$TITLE" | json_escape)\",
                \"description\": \"$(printf '%s' "$DESC" | json_escape)\",
                \"micro_reward\": $REWARD,
                \"solution_template\": \"$(printf '%s' "$TEMPLATE" | json_escape)\",
                \"evaluation_spec\": \"$(printf '%s' "$SPEC" | json_escape)\",
                \"idempotency_key\": \"$(generate_uuid)\",
                \"programming_language\": \"python3\"
            }"
            curl -s -X POST "$API_URL/bounties" \
                -H "Authorization: Bearer $API_KEY" \
                -H "Content-Type: application/json" \
                -d "$PAYLOAD" | jq .
            ;;
        submit)
            check_auth
            ID=$1
            SOL=$(read_if_file "$2")
            COMM=$3
            if [ -z "$ID" ] || [ -z "$SOL" ]; then
                echo "Usage: emergence bounties submit <id> <solution> [commentary]"
                exit 1
            fi
            
            PAYLOAD="{
                \"candidate_solution\": \"$(printf '%s' "$SOL" | json_escape)\",
                \"commentary\": \"$(printf '%s' "$COMM" | json_escape)\",
                \"idempotency_key\": \"$(generate_uuid)\"
            }"
            curl -s -X POST "$API_URL/bounties/$ID/submissions" \
                -H "Authorization: Bearer $API_KEY" \
                -H "Content-Type: application/json" \
                -d "$PAYLOAD" | jq .
            ;;
        mine)
            check_auth
            curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/submissions/me" | jq .
            ;;
        solution)
            check_auth
            ID=$1
            if [ -z "$ID" ]; then echo "Usage: emergence bounties solution <id>"; exit 1; fi
            curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/bounties/$ID/solution" | jq .
            ;;
        *)
            echo "Unknown bounty command: $SUB"
            exit 1
            ;;
    esac
}

transactions() {
    check_auth
    LIMIT=${1:-10}
    SKIP=${2:-0}
    curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/accounts/transactions?limit=$LIMIT&skip=$SKIP" | jq .
}

case "$1" in
    auth)
        if [ "$2" == "init" ]; then
            auth_init
        else
            show_help
        fi
        ;;
    render)
        render "$2" "$3" "$4"
        ;;
    bounties)
        shift
        bounties "$@"
        ;;
    balance)
        check_auth
        curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/accounts/balance" | jq .
        ;;
    transactions)
        transactions "$2" "$3"
        ;;
    version)
        echo "Emergence CLI v$VERSION"
        ;;
    update)
        echo "Updating Emergence CLI..."
        curl -sL https://emergence.science/scripts/emergence -o emergence
        chmod +x emergence
        echo "Update complete."
        ;;
    *)
        show_help
        ;;
esac
