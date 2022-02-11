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
if [[ $# -eq 0 ]]; then
	echo "Run this script with the following arguments:"
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
for SITE in "${@:4}"
do
	if [[ -d $SITE ]]; then
		echo "----- will build for "$SITE" -----"
	else
		echo "!!!!! $SITE site not found !!!!!"
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
		LESECRETKEY=""
	fi
else
	echo "----- Pleas type in ur manifest signingkey or leave empty for no manifest signing -----"
	echo "----- The key/blank will be saved in '../lekey' -----"
	read -s -p 'Secretkey: ' LESECRETKEY
	if [[ $LESECRETKEY = "" ]]; then
		echo "----- will not sign Manifest -----"
		touch ../lekey
	else
		echo "----- writeing key in '../lekey' -----"
		echo "$LESECRETKEY" > lekey
		# glaub man muss zum signen ein file haben? umgeschrieben. reste:
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
if [[ -s gluon/GLUON_VERSION ]]; then
	if [[ "$3" != "$(cat gluon/GLUON_VERSION)" ]]; then
		while true; do
			echo "----- GLUON_VERSION does not match the allready cloned one -----"
			read -p "Delete and clone "$3" [y/n]? " -n 1 -r
			echo    # (optional) move to a new line
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				rm -rf gluon
				echo "----- gluon folder deleted -----"
				echo "----- clone git "$3" -----"
				git clone -c advice.detachedHead=false https://github.com/freifunk-gluon/gluon.git gluon -b $3
				echo "$3" > gluon/GLUON_VERSION
				break
			else
				echo "----- gluon folder not deleted -----"
				exit 0;
			fi
		done
	else
		echo "----- GLUON_VERSION "$3" allready cloned -----"
	fi
else
	[[ -d gluon/ ]] && rm -rf gluon/
	echo "----- clone git "$3" -----"
	git clone -c advice.detachedHead=false https://github.com/freifunk-gluon/gluon.git gluon -b $3
	echo "$3" > gluon/GLUON_VERSION
fi

### BUILDING ###
for SITE in "${@:4}"
do
	#clean gluon folders
	[[ -f gluon/site/site.conf ]] && rm -rf gluon/site/*
	[[ -d gluon/output/images ]] && rm -rf gluon/output/*

	#check and create folders
	[[ ! -d gluon/site ]] && mkdir -p gluon/site

	echo "----- copy site "$SITE" -----"
	cp -r sites/$SITE/* gluon/site/

	cd gluon

	echo "----- make update -----"
	make update

	BUILDARRAY=(\
	"ar71xx-generic" \
	"ar71xx-tiny" \
	"ar71xx-nand" \
	#"ath79-generic" \
	#"ath79-nand" \
	#"ipq40xx-generic" \
	#"ipq806x-generic" \
	#"lantiq-xrx200" \
	#"lantiq-xway" \
	"mpc85xx-generic" \
	"mpc85xx-p1020" \
	#"ramips-mt7620" \
	#"ramips-mt7621" \
	#"ramips-mt76x8" \
	#"ramips-rt305x" \
	)

	for NOWBUILDING in "${BUILDARRAY[@]}"
	do
		echo "$NOWBUILDING"
		echo "----- cleaning $NOWBUILDING -----"
		make clean GLUON_TARGET=$NOWBUILDING
		echo "----- building $GLUON_BRANCH $NOWBUILDING for $SITE -----"
		make -j $NUM_CORES_PLUS_ONE GLUON_TARGET=$NOWBUILDING
	done

	echo "----- generating "$GLUON_BRANCH" manifest for "$SITE" -----"
	make manifest

	#zu bauen Pfad springen
	cd ..

	if ! [[ $LESECRETKEY = "" ]]; then
		echo "----- signing "$GLUON_BRANCH" manifest for "$SITE" -----"
		gluon/contrib/sign.sh lekey gluon/output/images/sysupgrade/$GLUON_BRANCH.manifest
	else
		echo "----- NOT signing "$GLUON_BRANCH" manifest for "$SITE" -----"
	fi

	#echo "----- copying "$GLUON_BRANCH" images and info for "$SITE" -----"
	#mit  backup (nicht angepasst)
	#if ! [ -d outputs/$SITE ]; then
	#        mkdir -p outputs/$SITE
	#else
	#        if [ -d outputs/$SITE/sysupgrade.old ]; then
	#                rm -r outputs/$SITE/sysupgrade.old
	#        fi
	#        if [ -d outputs/$SITE/factory.old ]; then
	#                rm -r outputs/$SITE/factory.old
	#        fi
	#        mv outputs/$SITE/sysupgrade outputs/$SITE/sysupgrade.old
	#        mv outputs/$SITE/factory outputs/$SITE/factory.old
	#fi
	#cp -av gluon/output/images/sysupgrade/ outputs/$SITE/sysupgrade/
	#cp -av gluon/output/images/factory/ outputs/$SITE/factory/

	OUTPUTPATH=outputs/$SITE/$GLUON_BRANCH

	[[ ! -d $OUTPUTPATH ]] && mkdir -p $OUTPUTPATH

	#output kopieren ohne backup
	echo "----- copying "$GLUON_BRANCH" images to ../"$OUTPUTPATH"/ -----"
	rsync -av --remove-source-files gluon/output/images/ $OUTPUTPATH/

	#copy .htaccess for hideing the manifest from all
	echo "----- copying .htaccess to ../"$OUTPUTPATH"/sysupgrade/ -----"
	cp -r sites/.htaccess  $OUTPUTPATH/sysupgrade/

	#copy logs and infos
	[[ ! -d $OUTPUTPATH/.infos ]] && mkdir -p $OUTPUTPATH/.infos
	cp -r gluon/site $OUTPUTPATH/.infos/
	cp -r sites/build.sh $OUTPUTPATH/.infos/
	echo "$GLUON_RELEASE" > $OUTPUTPATH/.infos/GLUON_RELEASE
	echo "$3" > $OUTPUTPATH/.infos/GLUON_VERSION
	echo "----- FINISHED building "$GLUON_BRANCH" firmware for "$SITE" -----"

done
