# sites
Site Configurations der Städte im Bereich Siegerland.

## Zuordnung der Städte zu den Kürzeln

Die Kürzel der Städte sind im [Freifunk-Wiki](http://wiki.freifunk.net/Namenskonventionen_im_Kreis_Siegen-Wittgenstein) hinterlegt.

## build.sh anleitung
mkdir bauen<br />
cd bauen<br />
#in folgende Datei secret eintragen:<br />
touch garnix<br />
git clone https://github.com/freifunk-gluon/gluon.git gluon -b v2017.1.8<br />
git clone https://github.com/Freifunk-Siegerland/sites.git -b v2017.1.8<br />
cd sites<br />
chmod +x build.sh<br />
rm -rf ../outputs/*<br />
./build.sh s 22.01.3 sihb sisi sifb<br />
./build.sh b 22.01.3 sihb sisi sifb<br />
./build.sh e 22.01.3 sihb sisi sifb<br />
