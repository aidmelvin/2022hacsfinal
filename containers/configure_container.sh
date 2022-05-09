#!/bin/bash

# configure_container.sh: Given a running container name and a container type of
# either "web" or "control", this script will configure the container as a honeypot
# for our experiment by installing a database and populating it with fake data as honey,
# poisoning wget and curl so that they log their downloads to /var/log/.downloads, and
# if and only if the honeypot has type of "web", it will install and run the HTTP server.

if [ $# -ne 2 ]
then
  echo "configure_container.sh <container name> <web | control>"
  exit 1
fi

CONTAINER_NAME=$1
CONTAINER_MITM=$2

if [[ $CONTAINER_TYPE != "web" && $CONTAINER_TYPE != "control" ]]
then
  echo "container type must either be 'web' or 'control'"
  exit 1
fi

RUNNING=$(sudo lxc-ls --running | grep -c -w "$CONTAINER_NAME")
if [ $RUNNING -ne 1 ]
then
  echo "container '$CONTAINER_NAME' is not running!"
  exit 1
fi

CMDS=()

# Update packages
CMDS+=("apt update -y")
CMDS+=("apt upgrade -y")

# Install SSH server, postgres, wget, curl, git
CMDS+=("sudo apt install openssh-server postgresql wget curl git -y")

# Install NodeJS (cmds from https://joshtronic.com/2021/05/09/how-to-install-nodejs-16-on-ubuntu-2004-lts/)
CMDS+=("curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -")
CMDS+=("apt install -y nodejs")

# Configure postgres with most secure password in the world
CMDS+=("sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\"")

# Download setup files
CMDS+=("git clone https://github.com/aidmelvin/2022hacsfinal.git ~/setup")

# Populate database with fake data
CMDS+=("cd ~/setup/fakedata; npm i; npx ts-node fake.ts")

# --- Poison wget & curl ---
ROOT_FS_DIR="/var/lib/lxc/$CONTAINER_NAME/rootfs"
DOWNLOAD_DIR="/var/log/.downloads"
POISONED_CMDS_DIR="$DOWNLOAD_DIR/cmds"

# Make directories on container
sudo mkdir $ROOT_FS_DIR/$DOWNLOAD_DIR
sudo mkdir $ROOT_FS_DIR/$POISONED_CMDS_DIR

# Give read/write permissions to all users on container
CMDS+=("chmod a+rw $DOWNLOAD_DIR")

# Poison curl
CURL=$(cat <<EOM
#!/bin/bash

/usr/bin/curl --output $DOWNLOAD_DIR/D_\$(date '+%Y-%m-%d_%H-%M-%S') "\$@" > /dev/null 2>&1
/usr/bin/curl "\$@"
EOM
)

# Poison wget
WGET=$(cat <<EOM
#!/bin/bash

/usr/bin/wget "\$@" -O $DOWNLOAD_DIR/D_\$(date '+%Y-%m-%d_%H-%M-%S') -q > /dev/null 2>&1
/usr/bin/wget "\$@"
EOM
)

# Save poisoned commands in container
echo -e "$CURL" | sudo tee "$ROOT_FS_DIR$POISONED_CMDS_DIR/curl" > /dev/null
echo -e "$WGET" | sudo tee "$ROOT_FS_DIR$POISONED_CMDS_DIR/wget" > /dev/null

# Create aliases and give execute permissions to cmds
echo "alias curl=\"$POISONED_CMDS_DIR/curl\"" | sudo tee -a $ROOT_FS_DIR/etc/bash.bashrc > /dev/null
echo "alias wget=\"$POISONED_CMDS_DIR/wget\"" | sudo tee -a $ROOT_FS_DIR/etc/bash.bashrc > /dev/null
CMDS+=("chmod +x $POISONED_CMDS_DIR/*")
# ---------

# Web Server Configuration
if [[ $CONTAINER_TYPE == "web" ]]
then
  # Install forever & ts-node
  CMDS+=("npm install forever ts-node -g")

  # Move web server out of setup dir
  CMDS+=("mv ~/setup/webserver ~/webserver")

  # Install dependencies
  CMDS+=("cd ~/webserver && npm i")

  # Run HTTP server
  CMDS+=("forever start -c ts-node --workingDir ~/webserver ~/webserver/backend.ts")
fi

# Remove setup directory
CMDS+=("rm -rf ~/setup")

# Execute CMDs
for cmd in "${CMDS[@]}"
do
  sudo lxc-attach -n $CONTAINER_NAME -- bash -c "$cmd"
done
