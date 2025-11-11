#!/bin/bash

# Port conflict detection and management
# Usage: ./scripts/port-check.sh <port> [environment]

PORT=$1
ENV=${2:-unknown}

if [ -z "$PORT" ]; then
    echo "Usage: ./scripts/port-check.sh <port> [environment]"
    exit 1
fi

# Check if port is in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port $PORT is already in use"
    
    # Try to identify what's using the port
    PROCESS_INFO=$(lsof -Pi :$PORT -sTCP:LISTEN)
    echo "Current process on port $PORT:"
    echo "$PROCESS_INFO"
    
    # Ask user what to do
    echo ""
    echo "Options:"
    echo "1) Kill existing process and continue"
    echo "2) Exit and let user handle it"
    echo "3) Try alternative port (+10, e.g. 3010 instead of 3000)"
    
    read -p "Choose option (1-3): " choice
    
    case $choice in
        1)
            echo "🔫 Killing process on port $PORT..."
            lsof -ti :$PORT | xargs kill -9
            sleep 1
            if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
                echo "❌ Failed to free port $PORT"
                exit 1
            else
                echo "✅ Port $PORT is now free"
            fi
            ;;
        2)
            echo "👋 Exiting - please manually handle the port conflict"
            exit 1
            ;;
        3)
            ALTERNATIVE_PORT=$((PORT + 10))
            echo "🔄 Trying alternative port: $ALTERNATIVE_PORT"
            export PORT=$ALTERNATIVE_PORT
            echo "Use PORT=$ALTERNATIVE_PORT for $ENV environment"
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
else
    echo "✅ Port $PORT is available for $ENV environment"
fi
