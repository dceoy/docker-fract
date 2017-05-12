#!/usr/bin/env bash
#
# Usage:  deploy_do.sh [ -h | --help | -v | --version ]
#         deploy_do.sh [ options ]
#
# Description:
#   Deploy a Docker container with fract on DigitalOcean.
#
# Options:
#   -h, --help        Print usage
#   -v, --version     Print version information
#   -d, --droplet     Name of a Docker installed droplet [$FRACT_DROPLET]
#   -f, --fract-yml   Path to fract.yml [$FRACT_YML]
#   -q, --quiet       Suppress output
#   --build-only      Do not run a container after build

set -e

[[ "${1}" = '--debug' ]] && set -x && shift 1

COMMAND_NAME='deploy_do.sh'
COMMAND_VERSION='v0.1.0'
COMMAND_PATH="$(dirname ${0})/$(basename ${0})"
DROPLET="${FRACT_DROPLET}"
FRACT_YML_PATH="$(eval echo ${FRACT_YML})"
Q_FLAG=''
TO_NULL=''
DC_CMD='up -d'

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
    '-d' | '--droplet' )
      DROPLET="${2}" && shift 2
      ;;
    '-f' | '--fract-yml' )
      FRACT_YML_PATH="${2}" && shift 2
      ;;
    '-q' | '--quiet' )
      Q_FLAG='-q' && TO_NULL='> /dev/null 2>&1' && shift 1
      ;;
    '--build-only' )
      DC_CMD='build' && shift 1
      ;;
    * )
      abort "invalid argument \`${1}\`"
      ;;
  esac
done

set -u

[[ -n "${DROPLET}" ]] || abort 'missing a droplet name'
[[ -n "${FRACT_YML_PATH}" ]] || abort 'missing a path to fract.yml'

scp ${Q_FLAG} -i "$(tugboat config | awk '$1 == "ssh_key_path:" {print $2}')" \
  "${FRACT_YML_PATH}" \
  "root@$(tugboat info -a ip4 ${DROPLET} | tail -1):fract.yml"

tugboat ssh ${Q_FLAG} ${DROPLET} \
  -c "apt -y update ${TO_NULL}; \
      apt -y upgrade ${TO_NULL}; \
      pip install -U ${Q_FLAG} pip docker-compose; \
      wget ${Q_FLAG} https://raw.githubusercontent.com/dceoy/docker-fract/master/{Dockerfile,docker-compose.yml}; \
      echo \"alias d='docker-compose' dc='docker-compose'\" >> ~/.bashrc;
      docker-compose ${DC_CMD} ${TO_NULL};"
