#! /bin/bash
set -uo pipefail

display_usage() {
  echo "Usage: $0 <name> (sftp)" >&2
}

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

info() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&1
}

if [ "$EUID" -ne 0 ]
  then err "Please run as root"
  exit
fi

if [ "$#" -lt 1 ]; then
  display_usage
  exit 1
fi

readonly NOW=$(date +"%Y%m%d")
NAME=$1
METHOD=$2
SCRIPT_DIR="/root/scripts"
KEY=''


intro() {
  echo "-------------------------------------------------------------------------------------------------"
  echo "This script will:"
  echo "  * clone restic-tools project as a wrapper for restic"
  echo "  * give steps for getting restic binary"
  echo "  * create SSH config file for root"
  echo "  * create cron task"
  echo "-------------------------------------------------------------------------------------------------"

  read -p "Would you like to continue? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
}

get_env() {
  # to be enhanced...
  case $(uname -m) in 
    'armv7l')
      arch='arm'
      ;;
    'armv8')
      arch='arm64'
      ;;
    'x86_64')
      arch='amd64'
      ;;
    *)
      exit 126
      ;;
  esac

  case $(uname) in 
    'Linux')
      os='linux'
      ;;
    'OpensBSD')
      os='openbsd'
      ;;
    *)
      exit 126
      ;;
  esac
}

get_restic_tools() {
  if [ ! -d $SCRIPT_DIR/restic-tools ]; then
    info "cloning restic-tools project"
    mkdir -p $SCRIPT_DIR
    git clone https://github.com/binarybucks/restic-tools.git "$SCRIPT_DIR"/restic-tools
  fi

  if [ ! -f /usr/local/bin/backup ]; then
    cp $SCRIPT_DIR/restic-tools/bin/backup /usr/local/bin/
  fi

  if [ ! -f /etc/backup/"$NAME".repo ]; then
    cp -r $SCRIPT_DIR/restic-tools/etc/backup /etc/
    mv /etc/backup/example.repo /etc/backup/"$NAME".repo
    chmod 600 /etc/backup/"$NAME".repo
    KEY=$(pwgen -Bsy 20 1)
    sed -i /etc/backup/"$NAME".repo -e "s/RESTIC_PASSWORD=.*/RESTIC_PASSWORD=\x27$KEY\x27/g"

    if [ "$METHOD" == "sftp" ]; then
      sed -i /etc/backup/"$NAME".repo -e "s|RESTIC_REPOSITORY=.*|RESTIC_REPOSITORY=sftp:backup:/home/repos/$HOSTNAME|g"
      sed -i /etc/backup/"$NAME".repo -e "/^AWS_/d"
    fi
  fi
}

get_restic() {
  if [ ! -x /usr/local/bin/restic ]; then
    LATEST_URL=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/restic/restic/releases/latest)
    VERSION=${LATEST_URL##*/}
    err "restic bin is missing!"
    info "getting binary from https://github.com/restic/restic/releases/latest"

    cd /usr/local/bin || exit
    #TODO: check sum256
    wget --quiet https://github.com/restic/restic/releases/download/$VERSION/restic_${VERSION#"v"}_${os}_${arch}.bz2
    bunzip2 restic_0.7.3_${os}_${arch}.bz2
    ln -s restic_0.7.3_${os}_${arch} restic
    chmod 755 /usr/local/bin/restic
    cd - > /dev/null 2>&1

    #echo "----------------------------------------------------------------------------------------------"
    #echo "$ cd /usr/local/bin"
    #echo "$ wget https://github.com/restic/restic/releases/download/$VERSION/restic_${VERSION#"v"}_${os}_${arch}.bz2"
    #echo "$ bunzip2 restic_0.7.3_${os}_${arch}.bz2"
    #echo "$ ln -s restic_0.7.3_${os}_${arch} restic"
    #echo "$ chmod 755 /usr/local/bin/restic"
    #echo "----------------------------------------------------------------------------------------------"
  else
    info "found restic binary"
  fi
}

set_ssh_config() {
  if [ ! -f /root/.ssh/config ]; then
    info "creating SSH config file"
    cp ../ssh/config /root/.ssh/
  else
    info "found SSH config file, adding example host"
    cat ../ssh/config >> /root/.ssh/config
  fi
}

set_cron_task() {
  if [ ! -f /etc/cron.d/backup ]; then
    cp ../etc/cron.d/backup /etc/cron.d/
    sed -i /etc/cron.d/backup -e "s|backup REPONAME local|backup $NAME local|g"
  fi
}

end_info() {
  echo "-------------------------------------------------------------------------------------------------"
  echo "Remaining steps:"
  echo "  * customize /root/.ssh/config"
  echo "  * check /etc/backup/local.exclude for more exclusion"
  echo "  * customize time execution in /etc/cron.d/backup"
  if [ ! "$KEY" == '' ]; then 
    echo "  * store your encryption key: $KEY"
  fi
  echo "  * initialize your restic repo: backup $NAME init"
  echo "-------------------------------------------------------------------------------------------------"
}

intro
get_env
get_restic_tools
get_restic
set_ssh_config
set_cron_task
end_info
