#!/bin/bash
#
# SQUAB(Scalable QUagga-based Automated configuration on BGP)
# gen_zebra_bgpd_sec_conf.sh
# input: ROUTER_INDEX ASN BNET RPKI_IP PEER_NUM PEER_ADDRESS ROUTER_NAME
#

ZEBRA_CONF_FILE="/NIST-BGP-SRx-master/local-5.1.1/etc/zebra.conf"
BGPD_CONF_FILE="/NIST-BGP-SRx-master/local-5.1.1/etc/bgpd.conf"
SRX_SERVER_CONF_FILE="/NIST-BGP-SRx-master/local-5.1.1/etc/srx_server.conf"

INTERFACE=($(echo $(ip addr | grep inet | grep eth | cut -f 11 -d' ' | tr '\n' ' ')))
IP_ADDR=($(echo $(ip addr | grep inet | grep eth | cut -f 6 -d' ' | tr '\n' ' ')))

echo "!" > $ZEBRA_CONF_FILE
echo "! zebra.conf" >> $ZEBRA_CONF_FILE
echo "! generated by gen_zebra_bgpd_sec_conf.sh (SQUAB) `date`" >> $ZEBRA_CONF_FILE
echo "!" >> $ZEBRA_CONF_FILE

echo "hostname Router" >> $ZEBRA_CONF_FILE
echo "password zebra" >> $ZEBRA_CONF_FILE
echo "!" >> $ZEBRA_CONF_FILE
echo "! Interface's description." >> $ZEBRA_CONF_FILE
echo "!" >> $ZEBRA_CONF_FILE

for i in $(seq 0 $(expr ${#INTERFACE[@]} - 1))
do
	echo "interface ${INTERFACE[i]}" >> $ZEBRA_CONF_FILE
	echo " ip address ${IP_ADDR[i]}" >> $ZEBRA_CONF_FILE
	echo " ipv6 nd suppress-ra" >> $ZEBRA_CONF_FILE
	echo "!" >> $ZEBRA_CONF_FILE
done
cat $ZEBRA_CONF_FILE

ROUTER_INDEX=$1
ASN=$2
BNET=$3
PEER_NUM=$5
PEER_ADDRESS=$6

KEY_REPO="/var/lib/bgpsec-keys"

echo "!" > $BGPD_CONF_FILE
echo "! bgpd.conf" >> $BGPD_CONF_FILE
echo "! generated by gen_zebra_bgpd_sec_conf.sh (SQUAB) `date`" >> $BGPD_CONF_FILE
echo "!" >> $BGPD_CONF_FILE

echo "hostname bgpd" >> $BGPD_CONF_FILE
echo "password  zebra" >> $BGPD_CONF_FILE
echo "log stdout" >> $BGPD_CONF_FILE
echo "!" >> $BGPD_CONF_FILE

echo "router bgp $ASN" >> $BGPD_CONF_FILE
echo " bgp router-id 10.10.10.$ROUTER_INDEX" >> $BGPD_CONF_FILE
echo " network $BNET" >> $BGPD_CONF_FILE
echo " neighbor $PEER_ADDRESS remote-as $PEER_NUM" >> $BGPD_CONF_FILE
echo " neighbor $PEER_ADDRESS next-hop-self" >> $BGPD_CONF_FILE

cd $KEY_REPO
ROUTER_NAME=$7
echo " srx bgpsec ski 0 1 `qsrx-view-subject $ROUTER_NAME`" >> $BGPD_CONF_FILE
echo "!" >> $BGPD_CONF_FILE

echo " ! SRx Basic Configuration Settings" >> $BGPD_CONF_FILE
echo " srx set-proxy-id 172.18.0.$ROUTER_INDEX" >> $BGPD_CONF_FILE
echo " srx set-server localhost 17900" >> $BGPD_CONF_FILE
echo " srx keep-window 900" >> $BGPD_CONF_FILE
echo " srx evaluation origin_only" >> $BGPD_CONF_FILE
echo " no srx extcommunity" >> $BGPD_CONF_FILE
echo " srx display" >> $BGPD_CONF_FILE
echo "" >> $BGPD_CONF_FILE

echo " ! SRx Evaluation Configuration Settings" >> $BGPD_CONF_FILE
echo " srx set-origin-value valid" >> $BGPD_CONF_FILE
echo " srx set-path-value undefined" >> $BGPD_CONF_FILE
echo "" >> $BGPD_CONF_FILE

echo " ! Connect to SRx-server" >> $BGPD_CONF_FILE
echo " srx connect" >> $BGPD_CONF_FILE
echo "!" >> $BGPD_CONF_FILE
echo "line vty" >> $BGPD_CONF_FILE
echo "!" >> $BGPD_CONF_FILE

cat $BGPD_CONF_FILE

RPKI_IP=$4

echo "verbose  = true;" > $SRX_SERVER_CONF_FILE
echo "loglevel = 5;" >> $SRX_SERVER_CONF_FILE
echo "log     = \"/var/log/srx_server.log\";" >> $SRX_SERVER_CONF_FILE
echo "sync    = true;" >> $SRX_SERVER_CONF_FILE
echo "port    = 17900;" >> $SRX_SERVER_CONF_FILE
echo "" >> $SRX_SERVER_CONF_FILE

echo "console: {" >> $SRX_SERVER_CONF_FILE
echo "  port = 17901;" >> $SRX_SERVER_CONF_FILE
echo "  password = \"x\";" >> $SRX_SERVER_CONF_FILE
echo "};" >> $SRX_SERVER_CONF_FILE
echo "" >> $SRX_SERVER_CONF_FILE

echo "rpki: {" >> $SRX_SERVER_CONF_FILE
echo "  host = \"$RPKI_IP\";" >> $SRX_SERVER_CONF_FILE
echo "  port = 323;" >> $SRX_SERVER_CONF_FILE
echo "  # supports 2 versions: 0 => RFC6810, 1 => RFC8210" >> $SRX_SERVER_CONF_FILE
echo "  router_protocol = 1;" >> $SRX_SERVER_CONF_FILE
echo "};" >> $SRX_SERVER_CONF_FILE
echo "" >> $SRX_SERVER_CONF_FILE

echo "bgpsec: {" >> $SRX_SERVER_CONF_FILE
echo "  # Allows to set a configuration file for path valiation" >> $SRX_SERVER_CONF_FILE
echo "  #srxcryptoapi_cfg = \"<configuration file>\";" >> $SRX_SERVER_CONF_FILE
echo "" >> $SRX_SERVER_CONF_FILE
echo "  # Synchronize the logging settings of SCA with the logging settings of " >> $SRX_SERVER_CONF_FILE
echo "  # srx-server. If set to false the sca configuration takes precedence" >> $SRX_SERVER_CONF_FILE
echo "  sync_logging = true;" >> $SRX_SERVER_CONF_FILE
echo "};" >> $SRX_SERVER_CONF_FILE
echo "" >> $SRX_SERVER_CONF_FILE

echo "mode: {" >> $SRX_SERVER_CONF_FILE
echo "  no-sendqueue = true;" >> $SRX_SERVER_CONF_FILE
echo "  no-receivequeue = false;" >> $SRX_SERVER_CONF_FILE
echo "};" >> $SRX_SERVER_CONF_FILE
echo "" >> $SRX_SERVER_CONF_FILE

echo "mapping: {" >> $SRX_SERVER_CONF_FILE
echo "#The configuration allows 255 pre-configurations. client_0 is invalid" >> $SRX_SERVER_CONF_FILE
echo "  client_1  = \"2\";" >> $SRX_SERVER_CONF_FILE
echo "  client_10 = \"10.0.0.1\";" >> $SRX_SERVER_CONF_FILE
echo "  client_25 = \"10.1.1.2\";" >> $SRX_SERVER_CONF_FILE
echo "};" >> $SRX_SERVER_CONF_FILE

cat $SRX_SERVER_CONF_FILE
