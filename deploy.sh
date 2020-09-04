#!/usr/bin/env bash
#
# Usage:
#   deploy.sh -h|--help
#   deploy.sh --version
#   deploy.sh [ options ]
#
# Description:
#   Deploy a Docker container with fract on DigitalOcean.
#
# Options:
#   -h, --help          Print usage
#   --version           Print version information
#   --droplet=<name>    Name of a Docker installed droplet [$FRACT_DROPLET]
#   --fract-yml=<path>  Path to fract.yml [$FRACT_YML]
#   --doctl=<path>      Path to doctl command
#   --build-only        Do not run a container after build
#   --rebuild           Rebuild a container
#   --create            Create a droplet and deploy a container
#   --destroy           Destroy a droplet

set -e

[[ "${1}" = '--debug' ]] && set -x && shift 1

COMMAND_NAME='deploy.sh'
COMMAND_VERSION='v0.2.0'
COMMAND_DIR_PATH="$(dirname "${0}")"
COMMAND_PATH="${COMMAND_DIR_PATH}/"$(basename "${0}")
DOCTL='doctl'
DROPLET="${FRACT_DROPLET}"
FRACT_YML_PATH=$(eval echo "${FRACT_YML}")
DC_BUILD='build'
CREATE=0
DESTROY=0

case "${OSTYPE}" in
  darwin* )
    DOCTL_CONFIG_PATH="${HOME}/Library/Application\\ Support/doctl/config.yaml"
    ;;
  linux* )
    DOCTL_CONFIG_PATH="${HOME}/.config/doctl/config.yaml"
    ;;
  * )
    DOCTL_CONFIG_PATH=''
    ;;
esac

function print_version {
  echo "${COMMAND_NAME}: ${COMMAND_VERSION}"
}

function print_usage {
  sed -ne '1,2d; /^#/!q; s/^#$/# /; s/^# //p;' "${COMMAND_PATH}"
}

function abort {
  echo "${COMMAND_NAME}: ${*}" >&2
  exit 1
}

while [[ -n "${1}" ]]; do
  case "${1}" in
    '--version' )
      print_version && exit 0
      ;;
    '-h' | '--help' )
      print_usage && exit 0
      ;;
    '--droplet' )
      DROPLET="${2}" && shift 2
      ;;
    --droplet=* )
      DROPLET="${1#*\=}" && shift 1
      ;;
    '--fract-yml' )
      FRACT_YML_PATH="${2}" && shift 2
      ;;
    --fract-yml=* )
      FRACT_YML_PATH="${1#*\=}" && shift 1
      ;;
    '--doctl' )
      DOCTL="${2}" && shift 2
      ;;
    --doctl=* )
      DOCTL="${1#*\=}" && shift 1
      ;;
    '--build-only' )
      DC_BUILD='build --pull --no-cache' && shift 1
      ;;
    '--rebuild' )
      DC_BUILD='build --pull --no-cache' && shift 1
      ;;
    '--create' )
      CREATE=1 && shift 1
      ;;
    '--destroy' )
      DESTROY=1 && shift 1
      ;;
    * )
      abort "invalid argument \`${1}\`"
      ;;
  esac
done

set -u

[[ -n "${DOCTL_CONFIG_PATH}" ]] || DOCTL="${DOCTL} --config=${DOCTL_CONFIG_PATH}"
[[ -n "${DROPLET}" ]] || abort 'missing a droplet name'

if [[ ${DESTROY} -eq 0 ]]; then
  [[ -n "${FRACT_YML_PATH}" ]] || abort 'missing a path to fract.yml'

  if [[ ${CREATE} -eq 0 ]]; then
    echo -e ">>\tClean up containers"
    ${DOCTL} compute ssh "${DROPLET}" --ssh-command 'docker-compose down || exit 0'
  else
    echo -e ">>\tCreate a droplet"
    ${DOCTL} compute droplet create --wait "${DROPLET}"
    sleep 10
    echo -e ">>\tCreate a log directory"
    for i in $(seq 5); do
      ${DOCTL} compute ssh "${DROPLET}" --ssh-command 'mkdir log_from_fract' > /dev/null 2>&1 && break
      if [[ ${i} -lt 5 ]]; then
        sleep 5
      else
        abort 'connection timed out'
      fi
    done
  fi

  echo -e ">>\tCopy the config files"
  SSH_KEY_PATH=$(grep ssh-key-path ~/.config/doctl/config.yaml | awk '{print $2}')
  DROPLET_IP=$(doctl compute droplet list | awk '$2 == "'"${DROPLET}"'" {print $3}')
  scp -i "${SSH_KEY_PATH}" \
    "${FRACT_YML_PATH}" \
    "${COMMAND_DIR_PATH}/Dockerfile" \
    "${COMMAND_DIR_PATH}/docker-compose.yml" \
    "root@${DROPLET_IP}:"

  echo -e ">>\tCreate and start containers"
  ${DOCTL} compute ssh "${DROPLET}" \
    --ssh-command "docker-compose ${DC_BUILD} && docker-compose up -d --remove-orphans"
else
  echo -e ">>\tDelete the droplet"
  ${DOCTL} compute droplet delete -f "${DROPLET}"
fi
