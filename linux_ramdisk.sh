# THIS ALL NEEDS TO BE RE-WRITTEN!
# DOES IT EVEN WORK??

echo "Reading from linux_ramdisk.sh"

# Input: default variables for a ramdisk
# Output: a properly mounted ramdisk

echo "Hello again, ${HOSTNAME}, you beautiful ${OS} box, you."
echo "I'm thinking about creating a ${MB_SIZE}MB ramdisk at ${MOUNT_POINT}/${DISK_NAME}."

# Linux wants the mountpoint to already exist, though we should warn if the directory is NOT empty.

#############################################################################################
#   VALIDATING THE DEFAULT RAM DISK NAME
#############################################################################################
echo ""
while [ ! -d ${MOUNT_POINT}/${DISK_NAME} ]
# named RamDisk does not exist
do
	echo "Hold up! ${MOUNT_POINT}/${DISK_NAME} does not exist. You can:"
	echo ""
	
	RD_ACTIONS=("change ramdisk name" "create ${MOUNT_POINT}/${DISK_NAME}" )
	PS3="Select action: "
	
	select action in "${RD_ACTIONS[@]}"
	do
	    case $REPLY in
	         1) 	echo "change_rd"
					change_rd
	                break ;;

	         2) 	mkdir ${MOUNT_POINT}/${DISK_NAME}
	                break ;;
	    esac
	done
	
done

echo "${MOUNT_POINT}/${DISK_NAME} exists! Is it empty?"

shopt -s nullglob
shopt -s dotglob # To include hidden files
files=(${MOUNT_POINT}/${DISK_NAME}/*)
while [ ${#files[@]} -gt 1 ]; then 
	echo "${MOUNT_POINT}/${DISK_NAME} is not empty. Did you want to mount on top of it anyway?"
	ls -lh 
	echo "This bit is broken."
	#We should probably check whether or not this is already an active mount point. 
	#if mount | grep /mnt/md0 > /dev/null; then
	#    echo "yay"
	#else
	#    echo "nay"
	#fi
done
shopt -u dotglob
shopt -u nullglob

#Let's do this thing!

create_rd

