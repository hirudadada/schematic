#!/bin/ash

# Load the JSON file into a variable.
databases=$(cat databases.json)

# Get the length of the databases array.
length=$(echo $databases | jq '.databases | length')

# Loop over the databases.
for i in $(seq 0 $(($length-1))); do
  # Parse the JSON for this database into environment variables.
  export DB_HOST=$(echo $databases | jq -r ".databases[$i].DB_HOST")
  export DB_NAME=$(echo $databases | jq -r ".databases[$i].DB_NAME")
  export DATABASE_URL=$(echo $databases | jq -r ".databases[$i].DATABASE_URL")
  export DB_TYPE=$(echo $databases | jq -r ".databases[$i].DB_TYPE")
  export DB_ADAPTER=$(echo $databases | jq -r ".databases[$i].DB_ADAPTER")

  # Run the Rake tasks.
  if [ -z "$1" ]; then
    echo -e "\n\n\nDeployment Start on $DB_HOST\\$DB_NAME \n-------------------------------------------------------------------------------- "
    rake deploy
    #rake sp:deploy
    echo -e "\nDeployment completed on $DB_HOST\\$DB_NAME.\n"
  else
    echo -e "\n\n\nDeployment Start on $DB_HOST\\$DB_NAME \n-------------------------------------------------------------------------------- "
    rake deploy["$1"]
    #rake sp:deploy["$1"]
    echo -e "\nDeployment completed on $DB_HOST\\$DB_NAME.\n"
  fi
done
