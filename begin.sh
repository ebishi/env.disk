#!/bin/bash
# Copyright 2013 SSmith

# Personal shell environment setup
# Should work in standard OSX & Linux systems



#############################################################################################
#   	HARDCODED DEFAULT VARIABLES
#############################################################################################
# These can be changed here, but the user is also given opportunity to change them when the 
# script runs
#############################################################################################
# Size of ram disk
MB_SIZE=100
# name of ram disk
DISK_NAME=RamDisk
#OSX doesn't let us change the mountpoint, so this is only used in Linux.
MOUNT_POINT=~

#############################################################################################
#   	LAY OF THE LAND
#############################################################################################
# Learning about our environment, and checking for dependencies
#############################################################################################

OS=`uname`
# Expected OSes:
#	Darwin = OSX
# 	Linux = Linux

USER=`whoami`

# If any of these dependencies fails, the script will abort.
DEPENDENCIES="ssh gpg ssh-agent readlink"



# Getting our current location
pushd . > /dev/null
SCRIPT_PATH="${BASH_SOURCE[0]}";
SCRIPT="${BASH_SOURCE[0]}";
  while([ -h "${SCRIPT_PATH}" ]) do 
    cd "`dirname "${SCRIPT_PATH}"`"
    SCRIPT_PATH="$(readlink "`basename "${SCRIPT_PATH}"`")"; 
  done
cd "`dirname "${SCRIPT_PATH}"`" > /dev/null
SCRIPT_PATH="`pwd`";
popd  > /dev/null

source ${SCRIPT_PATH}/functions.sh

clear
echo -e "Hello ${PURPLE}${HOSTNAME}${NONE}, you beautiful ${PURPLE}${OS}${NONE} box, you."
#echo -e "I'm running ${UNDERLINE}${SCRIPT}${NONE} as ${UNDERLINE}${USER}${NONE}, from ${UNDERLINE}${SCRIPT_PATH}${NONE}"
echo ""
echo -e "${TITLE}Testing dependencies....${NONE}"

deps_ok=YES
for dep in ${DEPENDENCIES} 
do

		echo "Checking for $dep..."
		command -v $dep
		OUT=$?
		if [ $OUT == 1 ]; then
			echo -e "${RED}$dep not found.${NONE}"
			deps_ok=NO
		fi
		
		echo ""
		
done

if [[ $deps_ok == "NO" ]]; then
        echo -e "Unmet dependencies up there."                
		abort
fi

if [ $OS = "Darwin" ]; then
	READLINK="readlink"
else
	READLINK="readlink -f"
fi

# We need to sort out the RamDisk before looking at symlinks, since the symlink will explicitly refer to the symlink

#############################################################################################
#   BEGINNING THE BEGINE: RAMDISK
#############################################################################################
echo -e ${TITLE}Setting up the RamDisk.${NONE}
if [ $OS = "Linux" ]; then
	source ${SCRIPT_PATH}/linux_ramdisk.sh
elif [ $OS = "Darwin" ]; then
	source ${SCRIPT_PATH}/darwin_ramdisk.sh
	
else
	echo "I don't recognize ${OS}. Aborting."
	exit 1
fi

#############################################################################################
#   GPG
#############################################################################################
# GPG archive has to be created keyless, since we won't have keys available to decrypt
# tar -cf - gnupg/* | gpg -c > gpg.tpg

# ~/.gnupg needs to be a valid directory before we can run any gpg commands!
# if it doesn't exist, gpg will create
# if it is a symlink, but the target is invalid, gpg will fail
# we should check this first, and delete the symlink if it is invalid

mkdir ${MOUNT_POINT}/${DISK_NAME}/gnupg

create_dotdir gnupg
echo ""
echo -e "Unpacking gpg.tpg archive"
# We should wrap this in some sort of while loop, to the password is entered successsfully
gpg < ${SCRIPT_PATH}/env/gpg.tpg | tar -C ${MOUNT_POINT}/${DISK_NAME}/gnupg/ -xv
ls -lh ${MOUNT_POINT}/${DISK_NAME}/

gpg --list-secret

# Import public keys from ${SCRIPT_PATH}/env/public_gpg

gpg --import ${SCRIPT_PATH}/env/public_gpg/*.asc


#############################################################################################
#   SSH Shenanigans
#############################################################################################
# SSH keys can be encrypted with my GPG key, since the GPG secret key is now loaded
# tar -cf - ssh | gpg -e > ssh.tpg

create_dotdir ssh

while ! [ -d ${MOUNT_POINT}/${DISK_NAME}/ssh ]; do
	# Keep prompting for the gpg passphrase, until successful
	# Should probably add a counter to this as well, rather than allowing infinite tries
	echo ""
	echo -e "Unpacking ssh.tpg archive"
	gpg < ${SCRIPT_PATH}/env/ssh.tpg | tar -C ${MOUNT_POINT}/${DISK_NAME} -xv
done

# ssh private key is in env/ssh/steph_ccj.gpg
# should create an archive for all the private keys (unfuddle & empty as well)


chmod 700 ${MOUNT_POINT}/${DISK_NAME}/ssh
chmod 600 ${MOUNT_POINT}/${DISK_NAME}/ssh/config
chmod 600 ${MOUNT_POINT}/${DISK_NAME}/ssh/private_keys/steph_ccj
chmod 600 ${MOUNT_POINT}/${DISK_NAME}/ssh/private_keys/unfuddle

echo Loading SSH key
ssh-add ${MOUNT_POINT}/${DISK_NAME}/ssh/private_keys/steph_ccj
ssh-add ${MOUNT_POINT}/${DISK_NAME}/ssh/private_keys/unfuddle
ssh-add -list

#echo Removing SSH private key
rm -rf ${MOUNT_POINT}/${DISK_NAME}/ssh/private_keys


# a friendly space at the end, so we don't look so crowded.
echo ""
