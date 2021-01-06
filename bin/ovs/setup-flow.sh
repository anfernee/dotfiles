#!/bin/bash

# To reproduce https://github.com/openvswitch/ovs-issues/issues/197

ClassifierTable="0"
ContrackTable="1"
ContrackStateTable="2"
L3ForwardingTable="3"
L2ForwardingCalcTable="4"
ContrackCommitTable="6"
L2ForwardingOutTable="7"

Cookie="cookie=0x520"
Priority="priority=520"
CTZone="64520"

GWOFPort=2
UplinkOFPort=3
PodOFPort=4
LocalOFPort="LOCAL" # ?

# PodMac="00:15:5d:61:83:41"
PodIP="192.168.194.8"
LocalPodCIDR="192.168.194.0/24"
RemotePodCIDR="192.168.193.0/24"
RemoteNodeIP="10.176.25.211"
GWIP="192.168.192.1"
GWMac="00:15:5d:1a:d4:0b"

br="br0"

## 0. Default flows
function install_default() {
  ovs-ofctl add-flow $br "table=$L2ForwardingOutTable, $Cookie,priority=0 actions=drop"
  ovs-ofctl add-flow $br "table=$ContrackCommitTable, $Cookie,priority=0 actions=resubmit(,$L2ForwardingOutTable)"
  ovs-ofctl add-flow $br "table=$L2ForwardingCalcTable, $Cookie,priority=0 actions=drop"
  ovs-ofctl add-flow $br "table=$L3ForwardingTable, $Cookie,priority=0 ip, actions=dec_ttl,resubmit(,$L2ForwardingCalcTable)" 
  ovs-ofctl add-flow $br "table=$ContrackStateTable, $Cookie,priority=0 actions=drop"
  ovs-ofctl add-flow $br "table=$ContrackTable, $Cookie,priority=0 actions=drop"
}

## 1. request pkts
function step1() {
  ### Pod --> OVS --> GW --> HostNetwork
  ovs-ofctl add-flow $br "table=$ClassifierTable, $Cookie, $Priority, in_port=$PodOFPort, ip, nw_src=$PodIP, nw_dst=$RemotePodCIDR actions=resubmit(,$ContrackTable)" 
  ovs-ofctl add-flow $br "table=$ContrackTable, $Cookie, $Priority, ip, actions=ct(table=$ContrackStateTable,zone=$CTZone,nat)"
  ovs-ofctl add-flow $br "table=$ContrackStateTable, $Cookie, $Priority, ip actions=resubmit(,$L3ForwardingTable)" 
  ovs-ofctl add-flow $br "table=$L3ForwardingTable, $Cookie, $Priority, ip, nw_dst=$RemotePodCIDR actions=dec_ttl,mod_dl_dst:$GWMac,resubmit(,$L2ForwardingCalcTable)" 
  ovs-ofctl add-flow $br "table=$L2ForwardingCalcTable, $Cookie, $Priority, dl_dst=$GWMac actions=load:0x$GWOFPort->NXM_NX_REG1[],load:0x1->NXM_NX_REG0[16],resubmit(,$ContrackCommitTable)" # set gw as putport; mark as known
  ovs-ofctl add-flow $br "table=$ContrackCommitTable, $Cookie, $Priority, ct_state=+new+trk,ip actions=ct(commit,table=$L2ForwardingOutTable,zone=$CTZone)"
  ovs-ofctl add-flow $br "table=$L2ForwardingOutTable, $Cookie, $Priority, ip,reg0=0x10000/0x10000 actions=output:NXM_NX_REG1[]"
  ovs-ofctl add-flow $br "table=$L2ForwardingOutTable, $Cookie,priority=0 actions=drop"
  ### HostNetwork --> LOCAL --> OVS --> Uplink --> RemoteNode
  ovs-ofctl add-flow $br "table=$ClassifierTable, $Cookie, $Priority, in_port=$LocalOFPort, ip, nw_dst=$RemotePodCIDR actions=$UplinkOFPort"
}

function step2() {
  ovs-ofctl add-flow $br "table=$ClassifierTable, $Cookie, $Priority, in_port=$UplinkOFPort, ip, nw_src=$RemotePodCIDR actions=$LocalOFPort"
  ### HostNetwork --> GW --> OVS --> Pod
  ovs-ofctl add-flow $br "table=$ClassifierTable, $Cookie, $Priority, in_port=$GWOFPort, ip, nw_src=$RemotePodCIDR, nw_dst=$PodIP actions=resubmit(,$ContrackTable)"
  ovs-ofctl add-flow $br "table=$L3ForwardingTable, $Cookie, ip, actions=dec_ttl,resubmit(,$L2ForwardingCalcTable)"
  ovs-ofctl add-flow $br "table=$L2ForwardingCalcTable, $Cookie, $Priority, dl_dst=00:15:5d:61:83:41 actions=load:0x$PodOFPort->NXM_NX_REG1[],load:0x1->NXM_NX_REG0[16],resubmit(,$ContrackCommitTable)"
  ovs-ofctl add-flow $br "table=$ContrackCommitTable, $Cookie, ct_state=+inv+trk,ip actions=drop"
  ovs-ofctl add-flow $br "table=$ContrackCommitTable, $Cookie,priority=0 actions=resubmit(,$L2ForwardingOutTable)"
}

install_default
step1
step2
