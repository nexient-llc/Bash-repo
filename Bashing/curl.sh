#!/bin/bash

#setting the variables
REPO_NAME=$2
INPUT_FILE=$1
echo $REPO_NAME

declare -A inputs
while IFS="=" read -r key value
do
    inputs[$key]="$value"
done < <(jq -r 'to_entries | map((.key) + "=" + (.value)) | .[]' <$INPUT_FILE)

# check the TEAM values
for key in "${!inputs[@]}"; do
    echo "$key => ${inputs[$key]}"
done

# The curl command to check a teams permission
echo "$0: Running the CURL command"

curl -s "https://${GH_USER}:${GH_PAT}@api.github.com/repos/nexient-llc/${REPO_NAME}/teams" >./output.json

if [ $? -eq 0 ]; then
    echo "Successfully updated the output.json file with the Curl output"
else
    echo "could not upload the output to the output.json file" >&2
fi

echo "$0: iterating over the for loop"

SUCCESS=true

for key in "${!inputs[@]}"; do
    jq -e '.[] | select(.slug == "'$key'" and .permission == "'${inputs[$key]}'")' ./output.json >/dev/null

    if [ $? -eq 0 ]; then
        echo "$key has ${inputs[$key]}"
    else
        SUCCESS="false"
        echo "$key does not have ${inputs[$key]}" >&2
    fi

done

if [ "$SUCCESS" == "false" ]; then
    exit 1
else
    echo 'job done.'
fi

echo "$0: printing out the output"
