#!/bin/bash

#Ordneraufbau Beispiel
#~/bauen/sites/     #FF git und build.sh pfad
#~/bauen/gluon/     #gluon git
#~/bauen/outputs/   #image output

#GLUON_RELEASE anpassen!
#GLUON_BRANCH auswählen!
#script aufrufen mit den sites: ./build.sh sihb sisi sifb

# Warn of uninitialized variables
set -u

export GLUON_RELEASE=22.01
export GLUON_ATH10K_MESH=ibss
export GLUON_BRANCH=stable
#export GLUON_BRANCH=beta
#export GLUON_BRANCH=experimental

NUM_CORES_PLUS_ONE=$(expr $(nproc) + 1)

#zu Bauen Pfad springen
cd ../"$(dirname "$0")"

rm -r outputs/*

for dir in "$@"
do
        if ! [ -d sites/$dir ]; then
                echo "$dir site.conf not found, skipping..."
                break;
        fi
        rm -r gluon/site/*
        rm -r gluon/output/*
        rsync -avzP sites/$dir/* gluon/site/

        cd gluon

	make update
        echo "----- cleaning ar71xx-generic -----"
	make clean GLUON_TARGET=ar71xx-generic
        echo "----- building ar71xx-generic -----"
        make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-generic
        echo "----- cleaning ar71xx-tiny -----"
        make clean GLUON_TARGET=ar71xx-tiny
        echo "----- building ar71xx-tiny -----"
        make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-tiny
        #echo "----- cleaning ar71xx-nand -----"
        #make clean GLUON_TARGET=ar71xx-nand
        #echo "----- building ar71xx-nand -----"
        #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ar71xx-nand
        #echo "----- cleaning ramips-mt7621 -----"
        #make clean GLUON_TARGET=ramips-mt7621
        #echo "----- building ramips-mt7621 -----"
        #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ramips-mt7621
        #echo "----- cleaning mpc85xx-generic -----"
        #make clean GLUON_TARGET=mpc85xx-generic
        #echo "----- building mpc85xx-generic -----"1
        #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=mpc85xx-generic
        #echo "----- cleaning ipq40xx -----"
        #make clean GLUON_TARGET=ipq40xx
        #echo "----- building ipq40xx -----"
        #make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=ipq40xx

        echo "----- generating manifest -----"
	make manifest

        #zu Bauen Pfad springen
        cd ..

        echo "----- signing manifest -----"
        gluon/contrib/sign.sh fakesecret gluon/output/images/sysupgrade/stable.manifest

        echo "----- copying images -----"
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
	mkdir -p outputs/$dir/sysupgrade/
	rsync -avzP gluon/output/images/sysupgrade/* outputs/$dir/sysupgrade/
	mkdir -p outputs/$dir/factory/
	rsync -avzP gluon/output/images/factory/* outputs/$dir/factory/

done

