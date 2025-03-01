#!/bin/bash

# Input parameters
FOLDER_PATH="$1"
COMPOSE_SERVICE="${2:-db}"
COMPOSE_FILE="${3:-$FOLDER_PATH/docker-compose.yml}"
BACKUP_DIR="${4:-$FOLDER_PATH/db_backup}"
ENV_FILE="${5:-$FOLDER_PATH/.env}"
DB_NAME_VAR="${6:-MYSQL_DB}"
DB_USER_VAR="${7:-MYSQL_USER}"
DB_PASS_VAR="${8:-MYSQL_PASSWORD}"
TABLES_TO_RESTORE=(${@:9})

# Validate input
if [ -z "$FOLDER_PATH" ] || [ -z "$COMPOSE_SERVICE" ]; then
    echo "Usage: $0 <folder-path> <compose-service> [docker-compose-file] [backup-dir] [env-file] [db-name-var] [db-user-var] [db-pass-var] [tables...]"
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
DB_PASSWORD=${!DB_PASS_VAR}

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory '$BACKUP_DIR' not found."
    exit 1
fi

# Restore tables
if [ ${#TABLES_TO_RESTORE[@]} -eq 0 ]; then
    TABLES_TO_RESTORE=($(ls "$BACKUP_DIR"/*.sql | xargs -n 1 basename | sed 's/.sql$//'))
fi

for TABLE in "${TABLES_TO_RESTORE[@]}"; do
    BACKUP_FILE="$BACKUP_DIR/$TABLE.sql"
    if [ -f "$BACKUP_FILE" ]; then
        echo "Restoring table: $TABLE"
        cat "$BACKUP_FILE" | docker compose -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"
        if [ $? -eq 0 ]; then
            echo "Table $TABLE restored successfully."
        else
            echo "Error restoring table $TABLE."
        fi
    else
        echo "Warning: Backup file for table '$TABLE' not found. Skipping."
    fi
done

echo "Restore process completed."

