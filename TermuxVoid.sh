#!/data/data/com.termux/files/usr/bin/bash -e
# Copyright ©2018 by Hax4Us. All rights reserved.  🌎 🌍 🌏 🌐 🗺
#
# https://hax4us.com
################################################################################

# colors

build_date="$1"
if [ -z "$2" ]
then
	libc=""
else
	if [ "$2" != "musl" ]
	then
		echo Error second argument must be musl. Exiting.
		exit 1
	fi
	libc="$2-"
fi
red='\033[1;31m'
yellow='\033[1;33m'
blue='\033[1;34m'
reset='\033[0m'

# Clean up
pre_cleanup() {
	find $HOME -name "void*" -type d -exec rm -rf {} \; || :
} 

post_cleanup() {
	find $HOME -name "void*" -type f -exec rm -rf {} \; || :
} 

# Utility function for Unknown Arch

#####################
#    Decide Chroot  #
#####################

setchroot() {
	chroot=minimal
}
unknownarch() {
	printf "$red"
	echo "[*] Unknown Architecture :("
	printf "$reset"
	exit
}

# Utility function for detect system

checksysinfo() {
	printf "$blue [*] Checking host architecture ..."
	case $(getprop ro.product.cpu.abi) in
		arm64-v8a)
			SETARCH=aarch64
			;;
		armeabi|armeabi-v7a)
			SETARCH=armv7l
			;;
		i686|x86)
			SETARCH=i686
			;;
		*)
			unknownarch
			;;
	esac
}

# Check if required packages are present

checkdeps() {
	printf "${blue}\n"
	echo " [*] Updating apt cache..."
	apt update -y &> /dev/null
	echo " [*] Checking for all required tools..."

	for i in proot tar axel xz; do
		if [ -e $PREFIX/bin/$i ]; then
			echo "  • $i is OK"
		else
			if [ "$i" = "xz" ]
			then
				i=xz-utils
			fi
			echo "Installing ${i}..."
			apt install -y $i || {
				printf "$red"
				echo " ERROR: check your internet connection or apt\n Exiting..."
				printf "$reset"
				exit
			}
		fi
	done
	apt upgrade -y
}

# URLs of all possibls architectures

seturl() {
	URL="https://a-hel-fi.m.voidlinux.org/live/current/${rootfs}"
}

# Utility function to get tar file

gettarfile() {
	printf "$blue [*] Getting tar file...$reset\n\n"
	DESTINATION=$HOME/void-${libc}${SETARCH}
	rootfs="void-$SETARCH-${libc}ROOTFS-${build_date}.tar.xz"
	seturl $SETARCH
	axel ${EXTRAARGS} --alternate "$URL"
}

# Utility function to get SHA

getsha() {
	printf "\n${blue} [*] Getting SHA ... $reset\n\n"
	axel ${EXTRAARGS} --alternate "https://a-hel-fi.m.voidlinux.org/live/current/sha256sums.txt"
}

# Utility function to check integrity

checkintegrity() {
	printf "\n${blue} [*] Checking integrity of file...\n"
	echo " [*] The script will immediately terminate in case of integrity failure"
	printf ' '
	grep ${rootfs} sha256sums.txt | sha256sum -c || {
		printf "$red Sorry :( to say your downloaded linux file ${rootfs} was corrupted or half downloaded, but don't worry, just rerun my script\n${reset}"
		exit 1
	}
}

# Utility function to extract tar file

extract() {
	printf "$blue [*] Extracting... $reset\n\n"
	mkdir -p ${DESTINATION}
	proot --link2symlink tar -C ${DESTINATION} -xf $rootfs 2> /dev/null || :
}

# Utility function for login file

createloginfile() {
	bin=${PREFIX}/bin/startvoid
	cat > $bin <<- EOM
#!/data/data/com.termux/files/usr/bin/bash -e
unset LD_PRELOAD
exec proot --link2symlink -0 -r ${DESTINATION} -b /dev/ -b /sys/ -b /proc/ -b /storage/ -b $HOME -w $HOME /usr/bin/env -i HOME=/root USER=root TERM="$TERM" LANG=$LANG PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash --login
EOM

	chmod 700 $bin
}

printline() {
	printf "${blue}\n"
	echo " #----------------------------------------------------#"
}

# Start
clear
EXTRAARGS=""
if [[ ! -z $1 ]]
	then
EXTRAARGS=$1
if [[ $EXTRAARGS != "--insecure" ]]
	then
		
		EXTRAARGS=""
	
	fi

	fi
# Dont run in non-home
if [ `pwd` != $HOME ]; then
printf "$red You are not in home :($reset"
exit 2
fi
printf "\n${yellow} You are going to install Void Linux In Termux Without Root ;) Cool\n\n"
pre_cleanup
checksysinfo
checkdeps
#if [ $(getprop ro.product.manufacturer) = HUAWEI -a $SETARCH = arm64 ]
#then
#proot_patch
#fi
setchroot
gettarfile
getsha
checkintegrity
extract
createloginfile
post_cleanup

printf "$blue [*] Configuring Void For You ..."

# Utility function for resolv.conf
resolvconf() {
	#create resolv.conf file 
	printf "\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > ${DESTINATION}/etc/resolv.conf
} 
resolvconf

################
# finaltouchup #
################

finalwork() {
	[ -e $HOME/finaltouchup.sh ] && rm $HOME/finaltouchup.sh
	echo
	axel -a https://github.com/taichifan/Void-In-Termux/raw/master/finaltouchup.sh
	DESTINATION=$DESTINATION SETARCH=$SETARCH bash $HOME/finaltouchup.sh
} 
#finalwork

printline
printf "\n${yellow} Now you can enjoy Void Linux in your Termux :)\n Don't forget to like my hard work for termux and many other things\n"
printline
printline
printf "\n${blue} [∆] My official email:${yellow}		vingjroak@gmail.com\n"
printf "\n${blue} [∆] Official email for Kali Nethunter author which is where I took the script from.:${yellow}		lkpandey950@gmail.com\n"
printf "$blue [∆] His website:${yellow}		https://hax4us.com\n"
printf "$blue [∆] His YouTube channel:${yellow}	https://youtube.com/hax4us\n"
printline
printf "$blue [∆] You should update the system using xbps-install -Su the first time after using startvoid.\n"
printline
printf "$reset"
