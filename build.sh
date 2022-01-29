#!/bin/bash

# Warn of uninitialized variables
set -u
#exit on error
set -e

#allready in site.mk
#export GLUON_ATH10K_MESH=ibss

#CPU cores
NUM_CORES_PLUS_ONE=$(expr $(nproc) + 1)

case "${1}" in
	"")	echo "!!!!! No GLUON_BRANCH option was specified. !!!!!"; 	exit 1 ;;
	s)	echo "----- GLUON_BRANCH=stable -----"; 			export GLUON_BRANCH=stable ;;
	b)	echo "----- GLUON_BRANCH=beta -----"; 				export GLUON_BRANCH=beta ;;
	e)	echo "----- GLUON_BRANCH=experimental -----"; 			export GLUON_BRANCH=stable ;;
	*)	echo "!!!!! Unknown GLUON_BRANCH !!!!!"; 			exit 1 ;;
esac

#GLUON_RELEASE format check
if [[ $2 == [0-9][0-9].[0-9][0-9].+([0-9]) ]] || [[ $2 == [0-9][0-9].[0-9][0-9] ]]; then
        export GLUON_RELEASE=$2
        echo "----- GLUON_RELEASE "$GLUON_RELEASE" -----"
else
        echo "!!!!! GLUON_RELEASE format is not XX.XX(.??) !!!!!"
        exit 1;
fi

#check sites exist
for dir in "${@:3}"
do
	if ! [ -d $dir ]; then
		echo "!!!!! $dir site not found !!!!!"
		exit 1;
	fi
done

#zu Bauen Pfad springen
cd ../"$(dirname "$0")"

for dir in "${@:3}"
do
	#check and create branch folder
	[[ ! -d outputs/$dir/$GLUON_BRANCH ]] && mkdir -p outputs/$dir/$GLUON_BRANCH/

	#start log
	BASHLOGPATH=outputs/$dir/$GLUON_BRANCH/.build.sh.log
	echo "----- START log to "$BASHLOGPATH" -----"
	(

	#clean folders
	[[ -f gluon/site/site.conf ]] && rm -r gluon/site/*
	[[ -d gluon/output/images ]] && rm -r gluon/output/*

	#copy site
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

        echo "----- signing manifest -----"
        gluon/contrib/sign.sh garnix gluon/output/images/sysupgrade/$GLUON_BRANCH.manifest

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

	#copy logs and infos
	rsync -av sites/.htaccess  outputs/$dir/$GLUON_BRANCH/sysupgrade/
	rsync -av gluon/site/ outputs/$dir/$GLUON_BRANCH/.site
	rsync -av sites/build.sh outputs/$dir/$GLUON_BRANCH/.build.sh
        rsync -av sites/.git/HEAD  outputs/$dir/$GLUON_BRANCH/.sitesHEAD
        rsync -av gluon/.git/HEAD  outputs/$dir/$GLUON_BRANCH/.gluonHEAD

	echo "----- FINISHED building "$GLUON_BRANCH" firmware for "$dir". Log in "$BASHLOGPATH " -----"

	) 2>&1 | tee -a $BASHLOGPATH
done
