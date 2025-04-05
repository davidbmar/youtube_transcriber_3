#!/bin/bash

# Version-aware test script for Lambda function
echo "Testing Lambda function..."

# Check AWS CLI version
AWS_CLI_VERSION=$(aws --version)
echo "AWS CLI Version: $AWS_CLI_VERSION"

# Choose the right command format based on CLI version
if [[ $AWS_CLI_VERSION == *"aws-cli/2"* ]]; then
    echo "Using AWS CLI v2 format"
    aws lambda invoke \
      --function-name runpod-manager \
      --cli-binary-format raw-in-base64-out \
      --payload '{"command":"list_gpu_types"}' \
      output.json
else
    echo "Using AWS CLI v1 format"
    # For v1, encode the payload in base64
    PAYLOAD=$(echo '{"command":"list_gpu_types"}' | base64)
    aws lambda invoke \
      --function-name runpod-manager \
      --payload "$PAYLOAD" \
      output.json
fi

# Display the result if successful
if [ -f output.json ]; then
  echo "Lambda execution response:"
  echo ""
  # Use Python to pretty print the JSON output
  cat output.json | python3 -c '
import json
import sys

try:
    # Parse the Lambda response
    data = sys.stdin.read()
    if data:
        try:
            # Try to parse as JSON
            lambda_response = json.loads(data)
            
            # Check if the response has a body field
            if "body" in lambda_response:
                # Parse the body as JSON
                body = json.loads(lambda_response["body"])
                
                # Pretty print the result
                print(json.dumps(body, indent=2))
            else:
                # Just pretty print the whole response
                print(json.dumps(lambda_response, indent=2))
        except json.JSONDecodeError:
            # If not valid JSON, just print the raw data
            print(data)
except Exception as e:
    print(f"Error processing output: {str(e)}")
    print("Raw output:")
    print(open("output.json").read())
'
  echo ""
fi
