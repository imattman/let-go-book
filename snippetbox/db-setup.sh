#!/usr/bin/bash

# fail early
set -eou pipefail

if [[ -n "${DEBUG:=}" ]]; then
  set -x
fi

THIS_SCRIPT="${0##*/}"
BASE_DIR="$(cd "${0%/*}" && pwd)"

DOCKER_NAME_MYSQL="${DOCKER_NAME_MYSQL:-mysql-snippetbox}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-tiger}"

MYSQL_DB="${MYSQL_DB:-snippetbox}"
MYSQL_USER_NAME="${MYSQL_USER_NAME:-web}"
MYSQL_USER_PASSWORD="${MYSQL_USER_PASSWORD:-dev}"

usage() {
  cat <<-EOU
	Usage: $THIS_SCRIPT [OPTIONS] <COMMAND>
	
	Init script for MySQL in docker for snippetbox app.

	WARNING

	  This uses a docker image without a backing data volume.
	  All data is ephemeral and lost at shutdown.
	
	COMMANDS

	  start      Start MySQL docker image.
	  initdb     Initialize DB schema
	  all        Run all set up steps
    
	  client     Connect to $MYSQL_DB with user credentials
	  show-recs  Show records from snippets table

	  stop       Shutdown MySQL docker image


	OPTIONS
	   -h        Show this message

	ENVIRONMENT VARIABLES

	  MYSQL_ROOT_PASSWORD   $MYSQL_ROOT_PASSWORD
	  MYSQL_DB              $MYSQL_DB
	  MYSQL_USER_NAME       $MYSQL_USER_NAME
	  MYSQL_USER_PASSWORD   $MYSQL_USER_PASSWORD
	  DOCKER_NAME_MYSQL     $DOCKER_NAME_MYSQL

EOU
}

check() {
  local container_id="$(docker ps -q --filter name="$DOCKER_NAME_MYSQL")"
  if [[ -z "$container_id" ]]; then
    echo "MySQL container not found"
  else
    printf '%s\tcontainer with name "%s"\n' "$container_id" "$DOCKER_NAME_MYSQL"
  fi
}


start() {
  echo "Starting container with name $DOCKER_NAME_MYSQL ..."

  docker run --rm -d \
    -p 3306:3306 \
    --name="$DOCKER_NAME_MYSQL" \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    mysql

  sleep 4
}

initdb() {
  echo "Initializing DB..."
  echo "  from $BASE_DIR/db-setup.sql"

  docker exec -i "$DOCKER_NAME_MYSQL" \
    mysql -u root --password=$MYSQL_ROOT_PASSWORD \
    < "$BASE_DIR/db-setup.sql"
}

status() {
  docker ps --filter name="$DOCKER_NAME_MYSQL"
}

info() {
  status
}


stop() {
  echo "Stopping..."
  docker stop "$DOCKER_NAME_MYSQL"
}


client() {
  docker exec -it "$DOCKER_NAME_MYSQL" \
    mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" --password="$MYSQL_USER_PASSWORD"
}

client-root() {
  docker exec -it "$DOCKER_NAME_MYSQL" \
    mysql -D "$MYSQL_DB" -u root --password="$MYSQL_ROOT_PASSWORD"
}

show-recs() {
  docker exec -i "$DOCKER_NAME_MYSQL" \
    mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" --password="$MYSQL_USER_PASSWORD" \
    <<<"select id, title from snippets;"
}


all() {
  check
  start
  initdb
  status
}


if [[ $# -eq 0 ]]; then
  all "$@"
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      help|-h)
        usage
        exit 0
        ;;
      *)
        "$1" "$@"
        ;;
    esac
    shift
  done
fi

