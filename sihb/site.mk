GLUON_SITE_PACKAGES := \
	gluon-alfred \
	gluon-respondd \
	gluon-autoupdater \
	gluon-config-mode-autoupdater \
	gluon-config-mode-contact-info \
	gluon-config-mode-core \
	gluon-config-mode-geo-location \
	gluon-config-mode-hostname \
	gluon-config-mode-mesh-vpn \
	gluon-ebtables-filter-multicast \
	gluon-ebtables-filter-ra-dhcp \
	gluon-web-admin \
	gluon-web-autoupdater \
	gluon-web-network \
	gluon-web-wifi-config \
	gluon-mesh-batman-adv-15 \
	gluon-mesh-vpn-fastd \
	gluon-radvd \
	gluon-setup-mode \
	gluon-status-page \
	haveged \
	iwinfo
	
##  DEFAULT_GLUON_RELEASE
#   version string to use for images
#   gluon relies on
#     opkg compare-versions "$1" '>>' "$2"
#   to decide if a version is newer or not.
DEFAULT_GLUON_RELEASE := 0.6+exp$(shell date '+%y.%m')

# Allow overriding the release number from the command line
GLUON_RELEASE ?= 22.01

# Default priority for updates.
GLUON_PRIORITY ?= 0

# Region code required for some images; supported values: us eu
GLUON_REGION ?= eu

# Languages to include
GLUON_LANGS ?= en de

# activate generation of ath10k-targets
GLUON_ATH10K_MESH = ibss

GLUON_AUTOUPDATER_ENABLED = 1
