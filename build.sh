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
	stable)				echo "----- GLUON_BRANCH = stable -----"; export GLUON_BRANCH=$1 ;;
	beta)					echo "----- GLUON_BRANCH = beta -----"; export GLUON_BRANCH=$1  ;;
	experimental)	echo "----- GLUON_BRANCH = experimental -----"; export GLUON_BRANCH=$1 ;;
	*)						echo "!!!!! Unknown GLUON_BRANCH !!!!!"; 					exit 1 ;;
esac

#GLUON_RELEASE format check
if [[ $2 == [0-9][0-9].[0-9][0-9].+([0-9]) ]] || [[ $2 == [0-9][0-9].[0-9][0-9] ]]; then
  echo "----- GLUON_RELEASE "$2" -----"
	export GLUON_RELEASE=$2
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
for site in "${@:4}"
do
	if [ -d $site ]; then
		echo "----- will build for "$site" -----"
	else
		echo "!!!!! $site site not found !!!!!"
    exit 1;
	fi
done

#jump to upper folder from the build.sh
cd ../"$(dirname "$0")"

#check for Secretkey exist and not empty
if [[ -f lekey ]]; then
	if [[ -s lekey ]]; then
		echo "----- Manifest will be signed with key ../lekey -----"
    read LESECRETKEY < lekey
	else
		echo "----- Found empty keyfile at ../lekey, will not sign manifest -----"
		LESECRETKEY = ""
	fi
else
       echo "----- Pleas type in ur manifest signingkey or leave blank for no manifest signing -----"
			 echo "----- The key/blank will be saved in '../lekey' -----"
       read -p 'Secretkey: ' LESECRETKEY
      	if [ "$LESECRETKEY" = "" ]; then
                echo "----- will not sign Manifest -----"
								touch ../lekey
        else
					echo "----- writeing key in '../lekey' -----"
					echo "$LESECRETKEY" > lekey
          #      while true; do
          #              read -p "????? Do you wish to save this Key in a file for later [y/n]? " -n 1 -r
          #              echo    # (optional) move to a new line
          #              if [[ $REPLY =~ ^[Yy]$ ]]; then
          #                      echo "$LESECRETKEY" > lekey
          #                      echo "Key saved in file '../lekey'"
          #                      break
          #              else
          #                      echo "Key not saved in file"
          #                      break
          #              fi
          #      done


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
for site in "${@:4}"
do
	#clean gluon folders
	[[ -f gluon/site/site.conf ]] && rm -rf gluon/site/*
	[[ -d gluon/output/images ]] && rm -rf gluon/output/*

	#check and create folders
	[[ ! -d gluon/site ]] && mkdir -p gluon/site
	[[ ! -d outputs/$site/$GLUON_BRANCH ]] && mkdir -p outputs/$site/$GLUON_BRANCH

	echo "----- copy site "$site" -----"
	rsync -av sites/$site/* gluon/site

	cd gluon

	echo "----- make update -----"
	make update
	echo "----- cleaning ar71xx-generic -----"
	make clean GLUON_TARGET=ar71xx-generic
  echo "----- building ar71xx-generic for "$site" -----"
  make -j $NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-generic
  echo "----- cleaning ar71xx-tiny -----"
  make clean GLUON_TARGET=ar71xx-tiny
	echo "----- building ar71xx-tiny for "$site" -----"
	make -j $NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-tiny
  #echo "----- cleaning ar71xx-nand -----"
  #make clean GLUON_TARGET=ar71xx-nand
  #echo "----- building ar71xx-nand for "$site" -----"
  #make -j $NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-nand
  #echo "----- cleaning ramips-mt7621 -----"
  #make clean GLUON_TARGET=ramips-mt7621
  #echo "----- building ramips-mt7621 for "$site" -----"
  #make -j $NUM_CORES_PLUS_ONE GLUON_TARGET=ramips-mt7621
  #echo "----- cleaning mpc85xx-generic -----"
  #make clean GLUON_TARGET=mpc85xx-generic
  #echo "----- building mpc85xx-generic for "$site" -----"1
  #make -j $NUM_CORES_PLUS_ONE GLUON_TARGET=mpc85xx-generic
  #echo "----- cleaning ipq40xx -----"
  #make clean GLUON_TARGET=ipq40xx
  #echo "----- building ipq40xx for "$site" -----"
  #make -j $NUM_CORES_PLUS_ONE GLUON_TARGET=ipq40xx

  echo "----- generating manifest -----"
	make manifest

  #zu Bauen Pfad springen
  cd ..

	if ! [ $LESECRETKEY = "" ]; then
  	echo "----- signing manifest -----"
		gluon/contrib/sign.sh lekey gluon/output/images/sysupgrade/$GLUON_BRANCH.manifest
	else
		echo "----- NOT signing manifest -----"
	fi

  echo "----- copying images and info -----"

	#mit  backup (nicht angepasst)
	#if ! [ -d outputs/$site ]; then
        #        mkdir -p outputs/$site
        #else
        #        if [ -d outputs/$site/sysupgrade.old ]; then
        #                rm -r outputs/$site/sysupgrade.old
        #        fi
        #        if [ -d outputs/$site/factory.old ]; then
        #                rm -r outputs/$site/factory.old
        #        fi
        #        mv outputs/$site/sysupgrade outputs/$site/sysupgrade.old
        #        mv outputs/$site/factory outputs/$site/factory.old
        #fi
        #cp -av gluon/output/images/sysupgrade/ outputs/$site/sysupgrade/
        #cp -av gluon/output/images/factory/ outputs/$site/factory/

	#output kopieren ohne backup
	rsync -av gluon/output/images/sysupgrade outputs/$site/$GLUON_BRANCH
	rsync -av gluon/output/images/factory outputs/$site/$GLUON_BRANCH

	#copy .htaccess for hideing the manifest from all
	rsync -av sites/.htaccess  outputs/$site/$GLUON_BRANCH/sysupgrade/

	#copy logs and infos
	[[ ! -d outputs/$site/$GLUON_BRANCH/.infos ]] && mkdir -p outputs/$site/$GLUON_BRANCH/.infos
	rsync -av gluon/site/* outputs/$site/$GLUON_BRANCH/.infos/site/
	rsync -av sites/build.sh outputs/$site/$GLUON_BRANCH/.infos/build.sh
	echo "$GLUON_RELEASE" > outputs/$site/$GLUON_BRANCH/.infos/GLUON_RELEASE
  echo "$3" > outputs/$site/$GLUON_BRANCH/.infos/GLUON_VERSION
	echo "----- FINISHED building "$GLUON_BRANCH" firmware for "$site" -----"

done
