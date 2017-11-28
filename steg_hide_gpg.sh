#!/usr/bin/env bash

function usage(){
	echo "usage: steg_hide_gpg.sh enc <file|dir> <image_file> [gpg_password] [steanography_password]"
	echo "usage: steg_hide_gpg.sh dec <image_file> [gpg_password] [steanography_password]"
}

function check_exit_status(){
	if [ $1 -ne 0 ]; then
		echo "Error: " $2
		exit $1;
	fi
}

function check_installed(){
	#echo -n "Checking for "$1"..."

	PROG=`which $1`
	if [ -z "$PROG" ]; then
		echo " $1 not installed, run: apt install $1"
		exit 1;
	fi
		#echo " -> found: "$PROG
}

function encode() {
	DIR=$1
	I=0
	IMG_FULL_PATH=$2
	IMG_TMP=$(basename "$2")
	IMG_EXT="${IMG_TMP##*.}"
	IMG_BASE="${IMG_TMP%.*}"
	IMG_HIDE=$IMG_BASE"_"$I"."$IMG_EXT
	TAR_FILE=$DIR.tar.gz
	GPG_FILE=$TAR_FILE.gpg
	GPG_PASS=$5
	STEG_PASS=$6

	while [ -f $IMG_HIDE ]
	do
		echo "File $IMG_HIDE exists."
		I=$((I+1))
		IMG_HIDE=$IMG_BASE"_"$I"."$IMG_EXT
	done

	echo "Encrypting "$DIR" and hiding it in "$IMG_HIDE

	#step 1: pack the directory or file
	#echo "Packing "$DIR
	tar -zcf $TAR_FILE $DIR
	check_exit_status $? "tar error"

	#step 2: encrypt it with gpg
	#echo "Encrypting "$TAR_FILE
	if [ -z $GPG_PASS ]; then
		read -sp "Enter gpg encrypt password: " GPG_PASS
		echo ""
	fi
	#echo "Encrypting " $TAR_FILE " --> " $GPG_FILE
	echo $GPG_PASS | gpg --batch --yes --symmetric --cipher-algo aes256 --compress-algo zip --passphrase-fd 0 -c $TAR_FILE
	check_exit_status $? "gpg error"

	#step 3: put encrypted file in image
	if [ -z $STEG_PASS ]; then
		read -sp "Enter steanography encrypt password: " STEG_PASS
		echo ""
	fi
	#echo "Steanography on "$GPG_FILE
	steghide embed -q -cf $IMG_FULL_PATH -sf $IMG_HIDE -ef $GPG_FILE -p $STEG_PASS
	check_exit_status $? "steghide error";

	#step 4: cleanup
	rm $TAR_FILE $GPG_FILE

	#step 5: delete original file/directory
	#rm -rf $DIR

}

function decode() {
	STEG_FILE=$1
	GPG_PASS=$2
	STEG_PASS=$3
	GPG_FILE=out.tar.gz.gpg

	echo "Extracting from: "$STEG_FILE

	#step 1: get encrypted data from image
	if [ -z $STEG_PASS ]; then
		read -sp "Enter steanography decrypt password: " STEG_PASS
		echo ""
	fi
	#echo "Steanography on "$STEG_FILE
	steghide extract -q -sf $STEG_FILE -p $STEG_PASS -xf $GPG_FILE
	check_exit_status $? "steghide error";

	#step 2: ungpg
	if [ -z $GPG_PASS ]; then
		read -sp "Enter gpg decrypt password: " GPG_PASS
		echo ""
	fi
	#echo "GPG on "$GPG_FILE

	TAR_FILE=${GPG_FILE%.gpg}
	echo $GPG_PASS | gpg --quiet --batch --yes --cipher-algo aes256 --compress-algo zlib --passphrase-fd 0 --output $TAR_FILE --decrypt $GPG_FILE
    check_exit_status $? "gpg error";

	#step 3: untar
	#echo "Extract on "$TAR_FILE
	tar -zxf $TAR_FILE
    check_exit_status $? "tar error";

	#step 4: cleanup
	rm $TAR_FILE $GPG_FILE
	check_exit_status $? "rm error";
}

check_installed "steghide"
check_installed "gpg"

if [[ $1 == "enc" ]] && [[ -e $2 && -f $3 ]] ; then
	encode $2 $3;
elif [[ $1 == "dec" ]] && [[ -f $2 ]] ; then
	decode $2;
else 
	usage;
fi
