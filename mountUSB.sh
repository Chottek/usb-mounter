#!/bin/bash
#
#Bartosz Chotkowski s18555
#

#DEVICE TYPE GETTER
function getDeviceType(){
  local deviceName=/sys/block/${1#/dev/}
  local deviceType=$(udevadm info --query=property --path="$deviceName" | grep -Po 'ID_BUS=\K\w+')
  echo "$deviceType"
}

#TABLE JOINER
function joinBy() {
   local IFS=$1
   shift
   echo "$*"
}

#DEVICES LISTER
function listUSBDevices(){
local lsblkCmd='lsblk -o name,model,size'

local -a devices
	local device
	mapfile -t devices < <(lsblk -o NAME,TYPE | grep --color=never -oP '^\K\w+(?=\s+disk$)')
	devicesList=()
	for device in "${devices[@]}"; do
		if [ "$(getDeviceType "/dev/$device")" == "usb" ] || [ "$disableUSBCheck" == 'true' ]; then
			devicesList+=("$device")
		fi
	done

      printf "\nListing USB Memory drives available:\n"
	if [ "${#devicesList[@]}" -gt 0 ]; then
		$lsblkCmd | sed -n 1p | sed 's/^/         /'
		$lsblkCmd | grep --color=never -P "^($(joinBy '|' "${devicesList[@]}"))" | sed 's/^/ /'
	else
		printf "\nCouldn't find any USB drives on your system. \nIf there is a device plugged in, replug it\n"
		exit 1
	fi
printf "\n"
}

#USB MOUNT CHECKER
function isMounted(){
if [ ! -z "$1" ] && grep -q -e "$1" /etc/mtab; then
   return 0
else
   return 1
fi
}

#WELCOME TEXT
function welcome(){
clear
printf "Hello $USERNAME \n"
printf "Here you can create a bootable pendrive\n"

read -p "Press enter to continue"
clear
}

#ISO BURNER
function copyToDest(){
clear
read -p "Continue (y/n)? " choice
case "$choice" in 
  y|Y ) burn;;
  n|N ) printf "\nCancelled by user choice\n" exit 0 ;;
  * ) printf "\nInvalid input\n" exit 0;;
esac
}

#FORMATCHOICEGETTER
function format(){
printf "\nYour drive will be formatted\n"
read -p "Continue (y/n)? " fchoice
case "$fchoice" in
  y|Y ) mkfs.vfat  $pathInput ;;
  n|N ) printf "\nCancelled by o=user choice\n" exit 0 ;;
   * ) printf "\nInvalid input\n" exit 0;;
esac
printf "\nSuccessfuly formatted $pathInput\n"
}

#ISOBURNER
function burn(){
printf "Burning in progress, please wait!\n\n"
dd bs=1MB if="$iso_name" of="$pathInput" status=progress 
printf "\nDONE!\n"
}


#IMAGE SIZE CHECKER
function checkImageSize(){
if [ "$(blockdev --getsz "$iso_name")" -gt "$(blockdev --getsz "$pathInput")" ] ; then
	printf "\n> Image size is bigger than the selected '$device'!"
	exit 1
fi
}

#PATH GETTER
function getPath(){
printf "Input your external drive path (usually /dev/sd**)\n <path>> "
read pathInput
}

#DEVICE UNMOUNTER
function unmountDevice(){
typeset path=$1
if isMounted "$pathInput"; then
   if umount "$pathInput"; then
	printf "\nUSB device succesfully unmounted.\n"
   else printf "\nCould not unmount USB device.\n"
	exit 1
   fi
fi

read -p "Press enter to continue"
}


#ISO GETTER
function getIso(){
printf "Give me the name of .iso file you want to mount\n <name.iso>> "

read iso_name
checkFileExtension "$iso_name"
checkImageSize "$iso_name"
sleep 1
}

#EXTENSION CHECKER
function checkFileExtension(){
local iso=".iso"
   if [[ $iso_name =~ $iso ]]; then
	printf "\nFile extension is good\n"
   else
  	 printf "\nFile '$iso_name' has wrong extension.\n"
   	 exit 1
   fi
}	


#MAIN
function process(){
welcome
listUSBDevices
getPath
getIso
unmountDevice
format
copyToDest
}


#DO THIS ON LAUNCH
process






