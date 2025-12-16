#!/bin/bash
VERSION="3.23.0"
ROOT_FS="alpine-minirootfs-${VERSION}-x86_64.tar.gz"
ROOT_FS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/$ROOT_FS"
SETUP_SCRIPT="./setup.sh"
DISTRO_NAME="Alpine"

echo installing Alpine Linux $VERSION to WLS
echo
read -p "Distro name in wls (Default: Alpine): " NAME
if [[ -n "$NAME" ]]; then
    DISTRO_NAME="$NAME"
fi

echo
if [ -f $ROOT_FS ]; then
    echo root file system $ROOT_FS already exist skipping download
else
    echo getting root file system $ROOT_FS
    curl -s $ROOT_FS_URL -o $ROOT_FS > /dev/null
fi

echo
echo creating WLS instance
wsl --import $DISTRO_NAME ./ $ROOT_FS

echo
echo "running setup"
cat > ./$SETUP_SCRIPT << EOF
#!/bin/sh
echo "updating packages"
apk --update-cache upgrade

echo 'PS1='\''\n\[\e[91m\]\u\[\e[0m\]@\[\e[95m\]\h\[\e[0m\]:\[\e[94m\]\w\n\[\e[97m\]\\$\[\e[0m\] '\''' > .profile
echo "alias ll='ls -la'" >> .profile

echo
read -p "Enter user name: " USER_NAME
if [[ -n "\$USER_NAME" ]]; then
    adduser \$USER_NAME
    echo 'PS1='\''\n\[\e[92m\]\u\[\e[0m\]@\[\e[95m\]\h\[\e[0m\]:\[\e[94m\]\w\n\[\e[97m\]\\$\[\e[0m\] '\''' > /home/\$USER_NAME/.profile
    echo "alias ll='ls -la'" >> /home/\$USER_NAME/.profile
    chown \$USER_NAME /home/\$USER_NAME/.profile

    echo
    read -p "Add to sudoers? (Y/N): " ADD_SUDOERS
    if [[ \$ADD_SUDOERS == [yY] ]]; then
        echo "adding sudo package"
        apk add sudo
        echo "adding \$USER_NAME to /etc/sudoers"
        echo "\$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers
    fi

    echo
    read -p "Set \$USER_NAME as default user? (Y/N): " DEFAULT_USER
    if [[ \$DEFAULT_USER == [yY] ]]; then
        echo "[user]" >> /etc/wsl.conf
        echo "default=\$USER_NAME" >> /etc/wsl.conf
    fi
fi
EOF
wsl -d $DISTRO_NAME --exec sh $SETUP_SCRIPT
rm $SETUP_SCRIPT

echo "restarting instance"
wsl --terminate $DISTRO_NAME
echo
echo
wsl -d $DISTRO_NAME
