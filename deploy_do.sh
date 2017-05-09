#!/usr/bin/env bash
#
# Usage:  deploy_do.sh [ -h | --help | -v | --version ]
#         deploy_do.sh [ options ]
#
# Description:
#   Deploy a Docker container with fractus on DigitalOcean.
#
# Options:
#   -h, --help        Print usage
#   -v, --version     Print version information
#   --droplet         Name of a Docker installed droplet
#   --fractus-yml     Path to fractus.yml
#   --build-only      Do not run a container after build

set -e

[[ "${1}" = '--debug' ]] && set -x && shift 1

COMMAND_NAME='deploy_do.sh'
COMMAND_VERSION='v0.0.1'
COMMAND_PATH="$(dirname ${0})/$(basename ${0})"
BUILD_ONLY=0

function print_version {
  echo "${COMMAND_NAME}: ${COMMAND_VERSION}"
}

function print_usage {
  sed -ne '1,2d; /^#/!q; s/^#$/# /; s/^# //p;' ${COMMAND_PATH}
}

function abort {
  echo "${COMMAND_NAME}: ${*}" >&2
  exit 1
}

while [[ -n "${1}" ]]; do
  case "${1}" in
    '-v' | '--version' )
      print_version && exit 0
      ;;
    '-h' | '--help' )
      print_usage && exit 0
      ;;
    '--droplet' )
      DROPLET="${2}" && shift 2
      ;;
    '--fractus-yml' )
      FRACTUS_YML="${2}" && shift 2
      ;;
    '--build-only' )
      BUILD_ONLY=1 && shift 1
      ;;
    * )
      abort "invalid argument \`${1}\`"
      ;;
  esac
done

[[ -n "${DROPLET}" ]] || abort 'missing a droplet name'
[[ -n "${FRACTUS_YML}" ]] || abort 'missing a path to fractus.yml'

set -u

tugboat ssh "${DROPLET}" \
  -c 'wget https://raw.githubusercontent.com/dceoy/docker-fract/master/{Dockerfile,docker-compose.yml}'

scp -i "$(tugboat config | awk '$1 == "ssh_key_path:" {print $2}')" \
  "${FRACTUS_YML}" "root@$(tugboat info -a ip4 ${DROPLET} | tail -1):fractus.yml"

tugboat ssh "${DROPLET}" \
  -c 'pip install -U pip docker-compose'

tugboat ssh "${DROPLET}" \
  -c "docker-compose $([[ ${BUILD_ONLY} -eq 0 ]] && echo 'up -d' || echo 'build')"
