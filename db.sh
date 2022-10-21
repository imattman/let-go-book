#!/usr/bin/env bash

# fail early
set -eou pipefail

if [[ -n "${DEBUG:=}" ]]; then
  set -x
fi

THIS_SCRIPT="${0##*/}"
BASE_DIR="$(cd "${0%/*}" && pwd)"

SQL_INIT_FILE="$BASE_DIR/db-init.sql"
DOCKER_NAME_MYSQL="${DOCKER_NAME_MYSQL:-mysql-snippetbox}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-tiger}"

MYSQL_DB="${MYSQL_DB:-snippetbox}"
MYSQL_USER_NAME="${MYSQL_USER_NAME:-web}"
MYSQL_USER_PASSWORD="${MYSQL_USER_PASSWORD:-dev}"

usage() {
  cat <<-EOU
	Usage: $THIS_SCRIPT [OPTIONS] <COMMAND>
	
	Init script for MySQL in docker for snippetbox app.

	COMMANDS

	  start      Start DB container via docker-compose
	  init       Initialize DB schema

	  client     Connect to $MYSQL_DB with user credentials
	  snippets   Show records from snippets table
	  charset    Show charset of client session

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
  echo "Starting via docker-compose..."
  cd $BASE_DIR && docker-compose up -d
}

stop() {
  echo "Stopping via docker-compose..."
  cd $BASE_DIR && docker-compose down
}

start-manual() {
  echo "Starting container with name $DOCKER_NAME_MYSQL ..."

  docker run --rm -d \
    -p 3306:3306 \
    --name="$DOCKER_NAME_MYSQL" \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    mysql \
    --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
}

init() {
  echo "Initializing DB from init file $SQL_INIT_FILE ..."

  if [[ ! $(which docker) && $(which mysql) ]]; then
    mysql -u root --password=$MYSQL_ROOT_PASSWORD \
    --default-character-set=utf8mb4 \
    < "$SQL_INIT_FILE"
  else
    docker exec -i "$DOCKER_NAME_MYSQL" \
      mysql -u root --password=$MYSQL_ROOT_PASSWORD \
      --default-character-set=utf8mb4 \
      < "$SQL_INIT_FILE"
  fi
}

status() {
  docker ps --filter name="$DOCKER_NAME_MYSQL"
}


client() {
  if [[ ! $(which docker) && $(which mysql) ]]; then
    mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" \
      --password="$MYSQL_USER_PASSWORD" \
      --default-character-set=utf8mb4 
  else
    docker exec -it "$DOCKER_NAME_MYSQL" \
      mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" \
        --password="$MYSQL_USER_PASSWORD" \
        --default-character-set=utf8mb4 
  fi
}

client-root() {
  if [[ ! $(which docker) && $(which mysql) ]]; then
    mysql -D "$MYSQL_DB" -u root \
    --password="$MYSQL_ROOT_PASSWORD" \
      --default-character-set=utf8mb4 
  else
    docker exec -it "$DOCKER_NAME_MYSQL" \
      mysql -D "$MYSQL_DB" -u root \
      --password="$MYSQL_ROOT_PASSWORD" \
        --default-character-set=utf8mb4 
  fi
}

snippets() {
  if [[ ! $(which docker) && $(which mysql) ]]; then
    mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" \
    --password="$MYSQL_USER_PASSWORD" \
      --default-character-set=utf8mb4 \
    <<<"select id, title from snippets;"
  else
    docker exec -i "$DOCKER_NAME_MYSQL" \
      mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" \
      --password="$MYSQL_USER_PASSWORD" \
        --default-character-set=utf8mb4 \
      <<<"select id, title from snippets;"
  fi
}

charset() {
  if [[ ! $(which docker) && $(which mysql) ]]; then
    mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" \
    --password="$MYSQL_USER_PASSWORD" \
      --default-character-set=utf8mb4 \
    <<< "SELECT * FROM performance_schema.session_variables
      WHERE VARIABLE_NAME IN (
        'character_set_client', 'character_set_connection',
        'character_set_results', 'collation_connection'
      ) ORDER BY VARIABLE_NAME;"
  else
    docker exec -i "$DOCKER_NAME_MYSQL" \
      mysql -D "$MYSQL_DB" -u "$MYSQL_USER_NAME" \
      --password="$MYSQL_USER_PASSWORD" \
        --default-character-set=utf8mb4 \
      <<< "SELECT * FROM performance_schema.session_variables
        WHERE VARIABLE_NAME IN (
          'character_set_client', 'character_set_connection',
          'character_set_results', 'collation_connection'
        ) ORDER BY VARIABLE_NAME;"
  fi
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

