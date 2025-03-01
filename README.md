# db_backup_scripts
Scripts for Database backups optimized for autorestic use.

The scripts are all very similar, just with changes of the database executables.

The scripts are intended to be run inside a before hook of autorestic, creating a sql dump of all tables. Afterwards autorestic should backup this folder.
The script is created to work with docker compose containers running the databases.

Scripts to restore the backups are also provided.
