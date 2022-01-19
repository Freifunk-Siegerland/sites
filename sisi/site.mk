GLUON_SITE_PACKAGES := \
        gluon-mesh-batman-adv-15 \
        gluon-alfred \
        gluon-respondd \
        gluon-autoupdater \
        gluon-setup-mode \
        gluon-config-mode-core \
        gluon-config-mode-autoupdater \
        gluon-config-mode-hostname \
        gluon-config-mode-mesh-vpn \
        gluon-config-mode-geo-location \
        gluon-config-mode-contact-info \
        gluon-ebtables-filter-multicast \
        gluon-ebtables-filter-ra-dhcp \
        gluon-luci-admin \
        gluon-luci-autoupdater \
        gluon-luci-portconfig \
        gluon-luci-private-wifi \
        gluon-luci-wifi-config \
        gluon-next-node \
        gluon-mesh-vpn-fastd \
        gluon-radvd \
        gluon-status-page \
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
