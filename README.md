# sites
Site Configurations der Städte im Bereich Siegerland.

## Zuordnung der Städte zu den Kürzeln

Die Kürzel der Städte sind im [Freifunk-Wiki](http://wiki.freifunk.net/Namenskonventionen_im_Kreis_Siegen-Wittgenstein) hinterlegt.

## build.sh anleitung
mkdir bauen
cd bauen
git clone https://github.com/freifunk-gluon/gluon.git gluon -b v2017.1.8
git clone https://github.com/Freifunk-Siegerland/sites.git -b v2017.1.8
cd sites
chmod +x build.sh
rm -rf ../outputs/*
./build.sh s 22.01.3 sihb sisi sifb
./build.sh b 22.01.3 sihb sisi sifb
./build.sh e 22.01.3 sihb sisi sifb
