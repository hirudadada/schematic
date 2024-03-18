#!/bin/ash

# Load the YAML file into a temporary JSON file.
ruby -ryaml -rjson -e 'File.write("/tmp/databases.json", YAML.load_file("databases.yaml")["databases"].to_json)'

# Get the length of the databases array.
length=$(jq length /tmp/databases.json)

# Loop over the databases.
for i in $(seq 0 $(($length-1))); do
  # Parse the JSON for this database into environment variables.
  export DB_HOST=$(jq -r .[$i].DB_HOST /tmp/databases.json)
  export DB_NAME=$(jq -r .[$i].DB_NAME /tmp/databases.json)
  export DATABASE_URL=$(jq -r .[$i].DATABASE_URL /tmp/databases.json)
  export DB_TYPE=$(jq -r .[$i].DB_TYPE /tmp/databases.json)
  export DB_ADAPTER=$(jq -r .[$i].DB_ADAPTER /tmp/databases.json)

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

# Remove the temporary JSON file.
#rm /tmp/databases.json
