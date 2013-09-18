NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

TITLE=${BOLD}${UNDERLINE}

function abort {
	echo ""
	echo -e "${RED}${BOLD}I can't work under these conditions!${NONE}"
	exit 1
}

function change_rd {
	read -p "New RamDisk Name: " NEW_DISK_NAME
	DISK_NAME=$NEW_DISK_NAME
	echo "Changing ramdisk to ${MOUNT_POINT}/${DISK_NAME}."
}

function ls_rd {
	find ${MOUNT_POINT}/${DISK_NAME} |less
}

function eject_rd {
	
	if [ $OS = "Linux" ]; then
		# want to try without sudo first
		# if that fails, try with sudo
		# if that fails, change_rd
		umount ${MOUNT_POINT}/${DISK_NAME}
	elif [ $OS = "Darwin" ]; then
		diskutil unmount ${MOUNT_POINT}/${DISK_NAME}
		
		if [ -d ${MOUNT_POINT}/${DISK_NAME} ]; then
			echo "Sorry, ejecting ${MOUNT_POINT}/${DISK_NAME} was unsuccessful. Let's just create a new ramdisk instead."
			change_rd
		else
			echo "${MOUNT_POINT}/${DISK_NAME} was successfully ejected."
		fi
		
	fi
}

function create_rd {
	while ! [ -d ${MOUNT_POINT}/${DISK_NAME} ]; do	
	# Completely untested, with no checks in place for failure.
	# Won't work in linux, because the mount point already exists!


		if [ $OS = "Linux" ]; then
			
 			sudo mkfs -q /dev/ram0 8192
			sudo mount /dev/ram0 ${MOUNT_POINT}/${DISK_NAME}
			sudo chown ${USER}:${USER} ${MOUNT_POINT}/${DISK_NAME}
			chmod 700 ${MOUNT_POINT}/${DISK_NAME}

		elif [ $OS = "Darwin" ]; then
		
			BLOCKS=${MB_SIZE}
			let "BLOCKS *= 2048"
		
			echo Creating ${MB_SIZE} MB ram disk named ${DISK_NAME}
			echo hdid -nomount ram://$BLOCKS
			CREATED_RAMDISK=`hdid -nomount ram://$BLOCKS`

			echo New block device: ${CREATED_RAMDISK}
			#DISK_NAME=`basename ${CREATED_RAMDISK}`

			echo Creating volume named: ${DISK_NAME}
			newfs_hfs -v ${DISK_NAME} /dev/$CREATED_RAMDISK

			echo Mounting in ${MOUNT_POINT}/${DISK_NAME}
			diskutil mount ${CREATED_RAMDISK}
			chmod 700 ${MOUNT_POINT}/${DISK_NAME}

		fi
	
	done
	
	#make this output prettier!
	echo ""
	echo `mount |grep ${MOUNT_POINT}/${DISK_NAME}`
	echo `ls -lsd ${MOUNT_POINT}/${DISK_NAME}`
	echo `df -h ${MOUNT_POINT}/${DISK_NAME}`
	echo ""
}

function create_dotdir (){
	#checking symlinks
	#DOTDIR="gnupg"
	DOTDIR=$1
	
	echo ""
	echo -e "${TITLE}Checking out ~/.$DOTDIR ${NONE}"
	echo ""
	SSHPATH=`$READLINK ~/.ssh`
	GPGPATH=`$READLINK ~/.gnupg`

	# does directory already exist? 
		# if not, we'll just create symlink, and that's that
	# if it does exist, is it a symlink?
		# if not, we'll offer to move existing dir, and then make symlink
	# if it is a symlink, is it correct?
		# if not, we'll offer to delete it, and then make the correct symlink

	# we should make this all a function, since we'll be doing the same thing on multiple directories.
	
	# -d ~/.$DOTDIR is true when
		# - directory exists
		# - symlink points to a valid target
	# -d ~/.$DOTDIR is false when
		# - directory does not exist
		# - symlink points to an invalid target
	# both symlink states should be treated the same.
	
	# Should probably rewrite all this to check for symlink first, and then if no symlink, check if directory exists.
		
	

	# does directory already exist?	
	if [ -d ~/.$DOTDIR ]; then
		
		# But is it a symlink?
		if [ -h ~/.$DOTDIR ]; then
			echo -e "~/.$DOTDIR is already symlinked: ${STRONG}$DOTDIRLINK${NONE}"
			#echo -e "But is it the right symlink?"
			#echo "What we want: ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR"
			DOTDIRLINK=`$READLINK ~/.$DOTDIR`
			#echo -e "What we got: $DOTDIRLINK"

			if [ "${MOUNT_POINT}/${DISK_NAME}/$DOTDIR" == "$DOTDIRLINK" ]; then
				echo -e "${MOUNT_POINT}/${DISK_NAME}/$DOTDIR equals $DOTDIRLINK"
				echo -e "Our job here is done."
			else
				read -p "Replace with symlink to ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR? " -n 1 -r
				if [[ $REPLY =~ ^[Yy]$ ]]
				then
					echo ""
					rm -rf ~/.$DOTDIR && echo "$DOTDIRLINK symlink deleted." || abort
					echo "ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR" 
					ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR && echo "ls -la ~/.$DOTDIR"; ls -la ~/.$DOTDIR || abort
				else
					abort
				fi
			fi

		else
			echo "~/.$DOTDIR exists."
			echo "Here are its contents:"
			ls -lh ~/.$DOTDIR
			echo ""
			read -p "In order to proceed, we need to delete it. Would you like to back everything up first? " -n 1 -r

				if [[ $REPLY =~ ^[Yy]$ ]]
				then
					echo ""
					BACKUP_DOTDIR=~/.$DOTDIR.`date +%s`
				    echo "Backing up ~/.$DOTDIR to $BACKUP_DOTDIR."
					echo ""
					mv ~/.$DOTDIR $BACKUP_DOTDIR && echo "ls -lh $BACKUP_DOTDIR"; ls -lh $BACKUP_DOTDIR || abort
					echo ""
					echo "Creating symlink with"
					echo "ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR" 
					ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR && echo "ls -la ~/.$DOTDIR"; ls -la ~/.$DOTDIR || abort

				else
					echo ""
					read -p "Okay to delete existing ~/.$DOTDIR ? " -n 1 -r
					if [[ $REPLY =~ ^[Yy]$ ]]
					then
						echo ""
						rm -rf ~/.$DOTDIR && echo "~/.$DOTDIR deleted." || $ABORT
						echo "Creating symlink with"
						echo "ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR" 
						ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR && echo "ls -la ~/.$DOTDIR"; ls -la ~/.$DOTDIR || abort
					else
						echo ""
						abort
					fi

				fi

		fi

	else
	# directory does not already exist. Is it already symlinked?
		if [ -h ~/.$DOTDIR ]; then
			echo -e "~/.$DOTDIR is already symlinked: ${STRONG}$DOTDIRLINK${NONE}"
			echo -e "But is it the right symlink? ${RED}Probably not, since this symlink doesn't point to a valid directory${NONE}."
			#echo "What we want: ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR"
			DOTDIRLINK=`$READLINK ~/.$DOTDIR`
			#echo -e "What we got: $DOTDIRLINK"

			if [ "${MOUNT_POINT}/${DISK_NAME}/$DOTDIR" == "$DOTDIRLINK" ]; then
				echo -e "${MOUNT_POINT}/${DISK_NAME}/$DOTDIR equals $DOTDIRLINK"
				echo -e "Our job here is done."
			else
				read -p "Replace with symlink to ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR? " -n 1 -r
				if [[ $REPLY =~ ^[Yy]$ ]]
				then
					echo ""
					rm -rf ~/.$DOTDIR && echo "$DOTDIRLINK symlink deleted." || abort
					echo "ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR" 
					ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR && echo "ls -la ~/.$DOTDIR"; ls -la ~/.$DOTDIR || abort
				else
					abort
				fi
			fi

		else

			#We can create the symlink and go.
			echo "~/.$DOTDIR does not exist. We should probably create it."
			echo "Creating symlink with"
			echo "ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR" 
			ln -s ${MOUNT_POINT}/${DISK_NAME}/$DOTDIR ~/.$DOTDIR && echo "ls -la ~/.$DOTDIR"; ls -la ~/.$DOTDIR || abort

		fi
	fi
}