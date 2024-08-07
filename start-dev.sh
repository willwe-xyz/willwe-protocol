#!/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required tools are installed
if ! command_exists anvil || ! command_exists forge; then
    echo "Error: anvil or forge is not installed. Please install Foundry."
    exit 1
fi

# Check if the BASE_TENDERLY environment variable is set
if [ -z "$BASE_TENDERLY" ]; then
    echo "Error: BASE_TENDERLY environment variable is not set. Please set it to the Tenderly fork URL."
    exit 1
fi

# Check if MNEMONIC_DEV is set, if not, generate a random one
if [ -z "$MNEMONIC_DEV" ]; then
    MNEMONIC_DEV=$(openssl rand -hex 32 | tr -d "\n" | sed 's/.\{2\}/& /g' | awk '{print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 " " $10 " " $11 " " $12}')
    export MNEMONIC_DEV
    echo "Generated random mnemonic and set as MNEMONIC_DEV environment variable"
else
    echo "Using existing MNEMONIC_DEV environment variable"
fi

# Set up trap to kill background processes on exit
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# Start Anvil with the BASE fork and specified mnemonic
echo "Starting Anvil with BASE fork and specified mnemonic..."
echo "Fork URL: $BASE_TENDERLY"

# Try starting Anvil
anvil --fork-url "$BASE_TENDERLY" --mnemonic "$MNEMONIC_DEV" > anvil.log 2>&1 &
ANVIL_PID=$!

# Wait for Anvil to start or fail
echo "Waiting for Anvil to start..."
for i in {1..30}; do
    if grep -q "Listening on" anvil.log; then
        echo "Anvil started successfully."
        break
    elif ! kill -0 $ANVIL_PID 2>/dev/null; then
        echo "Error: Anvil process died. Check anvil.log for details."
        cat anvil.log
        exit 1
    fi
    sleep 1
done

if ! grep -q "Listening on" anvil.log; then
    echo "Error: Anvil failed to start within 30 seconds. Check anvil.log for details."
    cat anvil.log
    exit 1
fi

# Display first 200 lines of Anvil startup logs
echo "First 200 lines of Anvil startup logs:"
head -n 200 anvil.log

# Find the deployer address (first address derived from the mnemonic)
DEPLOYER_ADDRESS=$(cast wallet address --mnemonic "$MNEMONIC_DEV" --mnemonic-index 0)




# Deploy contracts and populate data
echo "Deploying contracts and populating data..."
if forge script script/LocalDeployAndPopulate.s.sol:DeployAndPopulate --broadcast --rpc-url http://127.0.0.1:8545 --slow -vvv; then
    echo "Setup completed successfully."
else
    echo "Error occurred during contract deployment and data population."
    exit 1
fi

echo "Anvil is running with PID $ANVIL_PID."
echo "Press Ctrl+C to stop the local environment."

# Function to display last 200 lines of logs
display_last_200_lines() {
    echo "Last 200 lines of Anvil logs:"
    tail -n 200 anvil.log
}

# Set up trap to display last 200 lines before exiting
trap 'display_last_200_lines' EXIT

# Wait for Anvil to finish (which it never will, unless stopped)
wait $ANVIL_PID