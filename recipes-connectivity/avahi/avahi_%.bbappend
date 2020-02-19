# Hach Claros Network Bus (ClarosBus) requires standard ZeroConf support
# The libdns_sd provides a compatibility layer over avahi for this

PACKAGECONFIG = "dbus ${AVAHI_GTK} libdns_sd"
PACKAGECONFIG[libdns_sd] = "--enable-compat-libdns_sd,"

PACKAGES =+ "${@bb.utils.contains("PACKAGECONFIG", "libdns_sd", "libavahi-compat-libdnssd", "", d)}"

FILES_libavahi-compat-libdnssd = "${libdir}/libdns_sd.so.*"

#RPROVIDES_libavahi-compat-libdnssd = "libdns-sd"

