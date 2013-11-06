#echo "Reading from darwin_ramdisk.sh"

# Input: default variables for a ramdisk
# Output: a properly mounted ramdisk

MOUNT_POINT=/Volumes

#echo "Hello again, ${HOSTNAME}, you beautiful ${OS} box, you."
#echo "I'm thinking about creating a ${MB_SIZE}MB ramdisk at ${MOUNT_POINT}/${DISK_NAME}."

# While ${MOUNT_POINT}/${DISK_NAME} exists, prompt user to: 
#	* change disk name
#	* review contents of ${MOUNT_POINT}/${DISK_NAME}
#	* eject ${MOUNT_POINT}/${DISK_NAME}
# While ${MOUNT_POINT}/${DISK_NAME} does not exist, prompt user to:
#	* change disk name
#	* change disk size
# 	* mount disk

#############################################################################################
#   VALIDATING THE DEFAULT RAM DISK NAME
#############################################################################################
echo ""
while [ -d ${MOUNT_POINT}/${DISK_NAME} ]
# named RamDisk already exists
do
	echo -e "${BOLD}Hold up! ${MOUNT_POINT}/${DISK_NAME} already exists. You can:${NONE}"
	echo ""
	
	RD_ACTIONS=("change ramdisk name" "review contents of existing ${MOUNT_POINT}/${DISK_NAME} ('q' to escape)" "eject existing ${MOUNT_POINT}/${DISK_NAME}" )
	PS3="Select action: "
	
	select action in "${RD_ACTIONS[@]}"
	do
	    case $REPLY in
	         1) 	change_rd
	                break ;;

	         2) 	ls_rd 
	                break ;;

			 3) 	eject_rd
			 		break ;;
	    esac
	done
	
done

# Let's do this thing!
create_rd


