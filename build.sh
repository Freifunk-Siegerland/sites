#!/bin/bash

### SETTINGS ###
# Warn of uninitialized variables
set -u
#exit on error
set -e
#CPU cores
NUM_CORES_PLUS_ONE=$(expr $(nproc) + 1)

### INPUTCHECK ###
#check if arguments empty
if [ $# -eq 0 ]; then
	echo "Please run this script with the following arguments:"
  echo "./build.sh <1> <2> <3> <4> <n>"
  echo "1: GLUON_BRANCH for manifest: s=stable, b=beta, e=experimental"
  echo "2: GLUON_RELEASE: in format XX.XX(.??)"
  echo "3: GLUON_VERSION to build from: in format 'v20XX.?X.?X', example v2017.1.8"
	echo "4-n: Site XXXX to build for. Example 'sihb'"
	exit 1;
fi

#GLUON_BRANCH format check
case "${1}" in
	"")	echo "!!!!! No GLUON_BRANCH option was specified. !!!!!"; 	exit 1 ;;
	s)	echo "----- GLUON_BRANCH = stable -----"; 				export GLUON_BRANCH=stable ;;
	b)	echo "----- GLUON_BRANCH = beta -----"; 					export GLUON_BRANCH=beta ;;
	e)	echo "----- GLUON_BRANCH = experimental -----"; 	export GLUON_BRANCH=stable ;;
#	a)	echo "----- GLUON_BRANCH = stable & beta & experimental -----";               GLUON_BRANCH=all ;;
	*)	echo "!!!!! Unknown GLUON_BRANCH !!!!!"; 					exit 1 ;;
esac

#GLUON_RELEASE format check
if [[ $2 == [0-9][0-9].[0-9][0-9].+([0-9]) ]] || [[ $2 == [0-9][0-9].[0-9][0-9] ]]; then
  export GLUON_RELEASE=$2
  echo "----- GLUON_RELEASE "$GLUON_RELEASE" -----"
else
  echo "!!!!! GLUON_RELEASE not format XX.XX(.??) !!!!!"
  exit 1;
fi

#GLUON_VERSION format check
if [[ $3 == v20[0-9][0-9].+([0-9]).+([0-9]) ]]; then
	echo "----- GLUON_VERSION: "$3" -----"
else
  echo "!!!!! GLUON_VERSION format 'v20XX.?X.?X', example v2017.1.8 !!!!!"
  exit 1;
fi


#check sites exist
for dir in "${@:4}"
do
	if [ -d $dir ]; then
		echo "----- will build for "$dir" -----"
	else
		echo "!!!!! $dir site not found !!!!!"
                exit 1;
	fi
done

#jump to upper folder from the build.sh
cd ../"$(dirname "$0")"

#check for Secretkey exist and not empty
if [[ -s lekey ]]; then
	echo "----- Signingkey file exists at ../lekey and not empty -----"
        read LESECRETKEY < lekey

else
       echo "----- Pleas type in ur manifest signingkey or leave blank no signing -----"
       read -p 'Secretkey: ' LESECRETKEY
        if [ "$LESECRETKEY" = "" ]; then
                echo "----- will not sign Manifest -----"
        else
                while true; do
                        read -p "????? Do you wish to save this Key in a file for later [y/n]? " -n 1 -r
                        echo    # (optional) move to a new line
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                                echo "$LESECRETKEY" > lekey
                                echo "Key saved in file '../lekey'"
                                break
                        else
                                echo "Key not saved in file"
                                break
                        fi
                done


        fi
fi

### check/create gluon ###
if [ -s gluon/GLUON_VERSION ]; then
	if [ "$3" != "$(cat gluon/GLUON_VERSION)" ]; then
		while true; do
			echo "????? GLUON_VERSION does not match the allready cloned one"
			read -p "Delete and clone "$3" [y/n]? " -n 1 -r
			echo    # (optional) move to a new line
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				rm -rf gluon
				echo "gluon folder deleted"
				echo "----- clone git "$3" -----"
				git clone -c advice.detachedHead=false https://github.com/freifunk-gluon/gluon.git gluon -b $3
				echo "$3" > gluon/GLUON_VERSION
				break
			else
				echo "gluon folder not deleted"
				exit 0;
			fi
		done
	else
		echo "----- GLUON_VERSION "$3" allready cloned -----"
	fi
else
	echo "----- clone git "$3" -----"
	git clone -c advice.detachedHead=false https://github.com/freifunk-gluon/gluon.git gluon -b $3
	echo "$3" > gluon/GLUON_VERSION
fi

### BAUEN ###
for dir in "${@:4}"
do
	#clean gluon folders
	[[ -f gluon/site/site.conf ]] && rm -rf gluon/site/*
	[[ -d gluon/output/images ]] && rm -rf gluon/output/*

	#check and create folders
	[[ ! -d gluon/site ]] && mkdir -p gluon/site
	[[ ! -d outputs/$dir/$GLUON_BRANCH ]] && mkdir -p outputs/$dir/$GLUON_BRANCH

	#start log
	BASHLOGPATH=outputs/$dir/$GLUON_BRANCH/.build.sh.log
	echo "----- START log to "$BASHLOGPATH" -----"
	(

	echo "----- copy site "$dir" -----"
	rsync -av sites/$dir/ gluon/site

	cd gluon

	echo "----- make update -----"
	make update
	echo "----- cleaning ar71xx-generic -----"
	make clean GLUON_TARGET=ar71xx-generic
  echo "----- building ar71xx-generic for "$dir" -----"
  make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-generic
  echo "----- cleaning ar71xx-tiny -----"
  make clean GLUON_TARGET=ar71xx-tiny
	echo "----- building ar71xx-tiny for "$dir" -----"
	make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-tiny
  #echo "----- cleaning ar71xx-nand -----"
  #make clean GLUON_TARGET=ar71xx-nand
  #echo "----- building ar71xx-nand for "$dir" -----"
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-nand
  #echo "----- cleaning ramips-mt7621 -----"
  #make clean GLUON_TARGET=ramips-mt7621
  #echo "----- building ramips-mt7621 for "$dir" -----"
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ramips-mt7621
  #echo "----- cleaning mpc85xx-generic -----"
  #make clean GLUON_TARGET=mpc85xx-generic
  #echo "----- building mpc85xx-generic for "$dir" -----"1
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=mpc85xx-generic
  #echo "----- cleaning ipq40xx -----"
  #make clean GLUON_TARGET=ipq40xx
  #echo "----- building ipq40xx for "$dir" -----"
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ipq40xx

  echo "----- generating manifest -----"
	make manifest

  #zu Bauen Pfad springen
  cd ..

	if ! [ "$LESECRETKEY" = "" ]; then
  	echo "----- signing manifest -----"
		gluon/contrib/sign.sh lekey gluon/output/images/sysupgrade/$GLUON_BRANCH.manifest
	else
		echo "----- NOT signing manifest -----"
	fi

  echo "----- copying images and info -----"

	#mit  backup (nicht angepasst)
	#if ! [ -d outputs/$dir ]; then
        #        mkdir -p outputs/$dir
        #else
        #        if [ -d outputs/$dir/sysupgrade.old ]; then
        #                rm -r outputs/$dir/sysupgrade.old
        #        fi
        #        if [ -d outputs/$dir/factory.old ]; then
        #                rm -r outputs/$dir/factory.old
        #        fi
        #        mv outputs/$dir/sysupgrade outputs/$dir/sysupgrade.old
        #        mv outputs/$dir/factory outputs/$dir/factory.old
        #fi
        #cp -av gluon/output/images/sysupgrade/ outputs/$dir/sysupgrade/
        #cp -av gluon/output/images/factory/ outputs/$dir/factory/

	#output kopieren ohne backup
	rsync -av gluon/output/images/sysupgrade outputs/$dir/$GLUON_BRANCH
	rsync -av gluon/output/images/factory outputs/$dir/$GLUON_BRANCH

	#copy .htaccess for hideing the manifest from all
	rsync -av sites/.htaccess  outputs/$dir/$GLUON_BRANCH/sysupgrade/

	#copy logs and infos
	rsync -av gluon/site/ outputs/$dir/$GLUON_BRANCH/.site
	rsync -av sites/build.sh outputs/$dir/$GLUON_BRANCH/.build.sh
  echo "$GLUON_VERSION" > outputs/$dir/$GLUON_BRANCH/.GLUON_VERSION
	echo "$GLUON_RELEASE" > outputs/$dir/$GLUON_BRANCH/.GLUON_RELEASE
	echo "----- FINISHED building "$GLUON_BRANCH" firmware for "$dir". Log in "$BASHLOGPATH" -----"

	) 2>&1 | tee -a $BASHLOGPATH
done
