#!/usr/bin/env bash
#
# Usage:  deploy.sh [ -h | --help | -v | --version ]
#         deploy.sh [ options ]
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
#   --tugboat         Path to tugboat command
#   --build-only      Do not run a container after build
#   --rebuild         Rebuild a container
#   --create          Create a droplet and deploy a container
#   --destroy         Destroy a droplet

set -e

[[ "${1}" = '--debug' ]] && set -x && shift 1

COMMAND_NAME='deploy.sh'
COMMAND_VERSION='v0.1.2'
COMMAND_PATH="$(dirname ${0})/$(basename ${0})"
TUGBOAT='tugboat'
DROPLET="${FRACT_DROPLET}"
FRACT_YML_PATH="$(eval echo ${FRACT_YML})"
Q_FLAG=''
TO_NULL=''
DC_CMD='up -d --remove-orphans'
CREATE=0
DESTROY=0

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
    '--tugboat' )
      TUGBOAT="${2}" && shift 2
      ;;
    '--build-only' )
      DC_CMD='build --pull --no-cache' && shift 1
      ;;
    '--rebuild' )
      DC_CMD='up -d --remove-orphans --build' && shift 1
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

[[ -n "${DROPLET}" ]] || abort 'missing a droplet name'

if [[ ${DESTROY} -eq 0 ]]; then
  [[ -n "${FRACT_YML_PATH}" ]] || abort 'missing a path to fract.yml'

  if [[ ${CREATE} -eq 0 ]]; then
    ${TUGBOAT} ssh ${Q_FLAG} ${DROPLET} \
      -c "[[ -f docker-compose.yml ]] && docker-compose stop ${TO_NULL} && docker-compose rm -f ${TO_NULL}"
  else
    ${TUGBOAT} create ${Q_FLAG} ${DROPLET}
    sleep 35
    for i in $(seq 5); do
      ${TUGBOAT} ssh -q ${DROPLET} -c 'pwd' > /dev/null 2>&1 && break
      [[ ${i} -lt 5 ]] && sleep 5 || abort 'connection timed out'
    done
    ${TUGBOAT} ssh ${Q_FLAG} ${DROPLET} \
      -c "apt -y update ${TO_NULL} && apt -y upgrade ${TO_NULL}; \
          pip install -U ${Q_FLAG} pip && pip install -U ${Q_FLAG} docker-compose; \
          echo \"alias d='docker-compose' dc='docker-compose'\" >> ~/.bashrc;"
  fi

  scp ${Q_FLAG} -i "$(${TUGBOAT} config | awk '$1 == "ssh_key_path:" {print $2}')" \
    "${FRACT_YML_PATH}" \
    "root@$(${TUGBOAT} info -a ip4 ${DROPLET} | tail -1):fract.yml"

  ${TUGBOAT} ssh ${Q_FLAG} ${DROPLET} \
    -c "wget -N ${Q_FLAG} https://raw.githubusercontent.com/dceoy/docker-fract/master/{Dockerfile,docker-compose.yml}; \
        docker-compose ${DC_CMD} ${TO_NULL};"
else
  ${TUGBOAT} destroy -y ${Q_FLAG} ${DROPLET}
fi
