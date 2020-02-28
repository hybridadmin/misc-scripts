#!/bin/bash

if [[ -r /etc/redhat-release ]]; then
	DISTRO=$(cat /etc/*release | grep -E "^(Cent|Fedo|Redh)" | awk '{print $1}' | head -n1 | tr '[A-Z]' '[a-z]')
	RELEASE=$(sed 's/Linux//g' < /etc/redhat-release | awk '{print $3}' | tr -d " " | cut -c-1)	
	MINOR_VERSION=$(sed 's/Linux//g' < /etc/redhat-release | awk '{print $3}' | tr -d " " | cut -d "." -f 2)
    if [ $RELEASE -ge 8 ]; then
        PKG_INSTALLER=$(which dnf)
	else
        PKG_INSTALLER=$(which yum)
    fi
elif [[ -r /etc/issue ]] || [[ -f /etc/debian_version ]]; then
	DISTRO=$(lsb_release -is | tr '[A-Z]' '[a-z]')
	CODE_NAME=$(lsb_release -cs)
	RELEASE=$(lsb_release -rs | cut -d '.' -f 1)	
	export DEBIAN_FRONTEND=noninteractive
    PKG_INSTALLER=$(which apt)
else
   echo "OS NOT DETECTED"
fi

if [ $DISTRO == 'centos' ] || [ $DISTRO == 'redhat' ]; then
    sudo $PKG_INSTALLER install rpm-build
    mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
    #touch ~/strongswan.spec

    echo "Refer to https://www.thegeekstuff.com/2015/02/rpm-build-package-example/ for further build instructions from Step 3"
else
    sudo $PKG_INSTALLER install build-essential autoconf automake autotools-dev dh-make debhelper devscripts fakeroot xutils lintian pbuilder rng-tools

    read -p 'Email Address: ' EMAIL_ADDRESS
    read -p 'First Name: ' FIRST_NAME
    read -p 'Last Name: ' LAST_NAME

    if [ -z $EMAIL_ADDRESS ] && [ -z $FIRST_NAME ] && [ -z $LAST_NAME ] then
        #https://www.gnupg.org/documentation/manuals/gnupg-devel/Unattended-GPG-key-generation.html
        export GNUPGHOME="$(mktemp -d)"

cat >/tmp/gpg-key-params <<EOF
    %echo Generating a basic OpenPGP key
    Key-Type: RSA
    Key-Length: 2048
    Subkey-Type: RSA
    Subkey-Length: 2048
    Name-Real: ${FIRST_NAME^^} ${LAST_NAME^^}
    Name-Comment: GPG Key for ${FIRST_NAME^^} ${LAST_NAME^^}
    Name-Email: $EMAIL_ADDRESS
    Expire-Date: 0
    Passphrase: 
    # Do a commit here, so that we can later print "done" :-)
    %commit
    %echo done
EOF
        sudo rngd -r /dev/urandom
        gpg --verbose --batch --generate-key /tmp/gpg-key-params
        gpg -a --output ~/.gnupg/${FIRST_NAME^^}_${LAST_NAME^^}.gpg --export "${FIRST_NAME^^} ${LAST_NAME^^}"
        gpg --import ~/.gnupg/${FIRST_NAME}_${LAST_NAME}.gpg

        echo "Refer to https://coderwall.com/p/urkybq/how-to-create-debian-package-from-source for further build instructions from Step 3"
    else
        echo "Not all required paramters entered, Aborting"
    fi
fi
