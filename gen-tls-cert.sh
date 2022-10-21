#!/usr/bin/env bash

# fail early
set -eou pipefail

if [[ -n "${DEBUG:=}" ]]; then
  set -x
fi

THIS_SCRIPT="${0##*/}"
BASE_DIR="$(cd "${0%/*}" && pwd)"

TLS_DIR="$BASE_DIR/tls"


usage() {
  cat <<-EOU
	Usage: $THIS_SCRIPT
	
	Generates self-signed TLS certificate for use with localhost.

	OPTIONS
	   -h        Show this message

EOU
}

check() {
  GOROOT="$(go env GOROOT)"
  if [[ -z "$GOROOT" ]]; then
    echo "Unable to determine GOROOT"
    exit 1
  fi

  if [[ ! -d "$TLS_DIR" ]]; then
    echo "Directory not found: $TLS_DIR"
    exit 1
  fi


}

gencert() {
  cd "$TLS_DIR" && \
    go run $GOROOT/src/crypto/tls/generate_cert.go \
      --rsa-bits=2048 \
      --host=localhost
}


all() {
  check
  gencert
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

