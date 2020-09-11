#!/bin/sh

fn_ppp_in_default_route(){
    ip route | grep default | grep -c ppp
}
fn_vpn_in_default_route(){
    ip route | grep default | grep -c vpn
}
fn_vpn_default_route_settings(){
    ip route | grep default | grep vpn | head -n 1
}

ppp_in_default_route=$(fn_ppp_in_default_route)
vpn_in_default_route=$(fn_vpn_in_default_route)
vpn_default_route_settings=$(fn_vpn_default_route_settings)
default_route_count=$(ip route | grep -c default)

vpn_route_metric=$(ip route | grep default | grep vpn | awk -F" " '{print $NF}')
ppp_route_metric=60

vpn_route_name="$(ip route | grep default | grep vpn | head -n 1 | cut -d' ' -f 3)"
ppp_route_name="$(ip route | grep default | grep ppp | head -n 1 | cut -d' ' -f 3)"

while [ "$default_route_count" -gt 0 ]
do
    ip route del default
    default_route_count=$((default_route_count-1))
done

if [ "$vpn_in_default_route" -gt 0 ]; then
    echo "ip route add \"$vpn_default_route_settings\""
    ip route add ${vpn_default_route_settings}
    ppp_route_metric=$((vpn_route_metric+10))
fi

if [ "$ppp_in_default_route" -gt 0 ]; then
    echo "ip route add default \"$ppp_route_name\" metric \"$ppp_route_metric\""
    ip route add default dev "$ppp_route_name" metric "$ppp_route_metric"
fi
