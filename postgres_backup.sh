#!/bin/bash

# Input parameters
FOLDER_PATH="$1"
COMPOSE_SERVICE="${2:-db}"
COMPOSE_FILE="${3:-$FOLDER_PATH/docker-compose.yml}"
OUTPUT_DIR="${4:-$FOLDER_PATH/db_backup}"
ENV_FILE="${5:-$FOLDER_PATH/.env}"
DB_NAME_VAR="${6:-POSTGRES_DB}"
DB_USER_VAR="${7:-POSTGRES_USER}"
#DB_PASS_VAR="${8:-POSTGRES_PASSWORD}"

# Validate input
if [ -z "$FOLDER_PATH" ] || [ -z "$COMPOSE_SERVICE" ]; then
    echo "Usage: $0 <folder-path> [compose-service] [docker-compose-file] [output-dir] [env-file] [db-name-var] [db-user-var] [db-pass-var]"
    exit 1
fi

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: Environment file '$ENV_FILE' not found."
    exit 1
fi

# Extract database credentials from environment variables
DB_NAME=${!DB_NAME_VAR}
DB_USER=${!DB_USER_VAR}
#DB_PASSWORD=${!DB_PASS_VAR}

# Check if required environment variables are set
#if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
    echo "Error: Missing database connection variables."
    exit 1
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Ensure output directory is empty
rm $OUTPUT_DIR/*.sql

# Get list of tables
TABLES=$(docker compose -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT tablename FROM pg_tables WHERE schemaname='public';")

# Check if we got any tables
if [ -z "$TABLES" ]; then
    echo "No tables found in the database."
    exit 1
fi

# Dump each table separately
for TABLE in $TABLES; do
    TABLE=$(echo "$TABLE" | tr -d '[:space:]')  # Trim whitespace
    if [ -n "$TABLE" ]; then
        echo "Dumping table: $TABLE"
        docker compose -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" pg_dump -U "$DB_USER" -d "$DB_NAME" -t "$TABLE" > "$OUTPUT_DIR/$TABLE.sql"
    fi
done

echo "All tables have been dumped in $OUTPUT_DIR"

