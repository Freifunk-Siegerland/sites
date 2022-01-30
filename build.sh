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
	"")						echo "!!!!! No GLUON_BRANCH option was specified. !!!!!"; 	exit 1 ;;
	stable)				echo "----- GLUON_BRANCH = stable -----" ;;
	beta)					echo "----- GLUON_BRANCH = beta -----"  ;;
	experimental)	echo "----- GLUON_BRANCH = experimental -----" ;;
#	a)						echo "----- GLUON_BRANCH = stable & beta & experimental -----" ;;
	*)						echo "!!!!! Unknown GLUON_BRANCH !!!!!"; 					exit 1 ;;
esac

#GLUON_RELEASE format check
if [[ $2 == [0-9][0-9].[0-9][0-9].+([0-9]) ]] || [[ $2 == [0-9][0-9].[0-9][0-9] ]]; then
  echo "----- GLUON_RELEASE "$2" -----"
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
	[[ ! -d outputs/$dir/$1 ]] && mkdir -p outputs/$dir/$1

	#start log
	BASHLOGPATH="outputs/$dir/$1/.build.sh.log"
	echo "----- START log to "$BASHLOGPATH" -----"
	(

	echo "----- copy site "$dir" -----"
	cp -r sites/$dir/* gluon/site

	cd gluon

	echo "----- make update -----"
	make update
	echo "----- cleaning ar71xx-generic -----"
	make clean GLUON_TARGET=ar71xx-generic
  echo "----- building ar71xx-generic for "$dir" -----"
  make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-generic GLUON_BRANCH=$1 GLUON_RELEASE=$2
  echo "----- cleaning ar71xx-tiny -----"
  make clean GLUON_TARGET=ar71xx-tiny
	echo "----- building ar71xx-tiny for "$dir" -----"
	make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-tiny GLUON_BRANCH=$1 GLUON_RELEASE=$2
  #echo "----- cleaning ar71xx-nand -----"
  #make clean GLUON_TARGET=ar71xx-nand
  #echo "----- building ar71xx-nand for "$dir" -----"
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-nand GLUON_BRANCH=$1 GLUON_RELEASE=$2
  #echo "----- cleaning ramips-mt7621 -----"
  #make clean GLUON_TARGET=ramips-mt7621
  #echo "----- building ramips-mt7621 for "$dir" -----"
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ramips-mt7621 GLUON_BRANCH=$1 GLUON_RELEASE=$2
  #echo "----- cleaning mpc85xx-generic -----"
  #make clean GLUON_TARGET=mpc85xx-generic
  #echo "----- building mpc85xx-generic for "$dir" -----"1
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=mpc85xx-generic GLUON_BRANCH=$1 GLUON_RELEASE=$2
  #echo "----- cleaning ipq40xx -----"
  #make clean GLUON_TARGET=ipq40xx
  #echo "----- building ipq40xx for "$dir" -----"
  #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ipq40xx GLUON_BRANCH=$1 GLUON_RELEASE=$2

  echo "----- generating manifest -----"
	make manifest GLUON_BRANCH=$1

  #zu Bauen Pfad springen
  cd ..

	if ! [ "$LESECRETKEY" = "" ]; then
  	echo "----- signing manifest -----"
		gluon/contrib/sign.sh lekey gluon/output/images/sysupgrade/$1.manifest
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
	rsync -av gluon/output/images/sysupgrade outputs/$dir/$1
	rsync -av gluon/output/images/factory outputs/$dir/$1

	#copy .htaccess for hideing the manifest from all
	cp -r sites/.htaccess  outputs/$dir/"$1"/sysupgrade/

	#copy logs and infos
	cp -r gluon/site/* "outputs/$dir/$1/.infos/site"
	cp -r sites/build.sh "outputs/$dir/$1/.infos/build.sh"
	echo "$2" > outputs/$dir/$1/.infos/GLUON_RELEASE
  echo "$3" > outputs/$dir/$1/.infos/GLUON_VERSION
	echo "----- FINISHED building "$1" firmware for "$dir". Log in "$BASHLOGPATH" -----"

	) 2>&1 | tee -a $BASHLOGPATH
done
