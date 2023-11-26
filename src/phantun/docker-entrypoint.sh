#!/bin/sh
#
echo "Run"

info() {
  local green='\e[0;32m'
  local clear='\e[0m'
  local time=$(date '+%Y-%m-%d %T')
  printf "${green}[${time}] [INFO]: ${clear}%s\n" "$*"
}

warn() {
  local yellow='\e[1;33m'
  local clear='\e[0m'
  local time=$(date '+%Y-%m-%d %T')
  printf "${yellow}[${time}] [WARN]: ${clear}%s\n" "$*" >&2
}

error() {
  local red='\e[0;31m'
  local clear='\e[0m'
  local time=$(date '+%Y-%m-%d %T')
  printf "${red}[${time}] [ERROR]: ${clear}%s\n" "$*" >&2
}

apply_sysctl() {
  info "apply sysctl: $(sysctl -w net.ipv4.conf.all.forwarding=1)"
  info "apply sysctl: $(sysctl -w net.ipv6.conf.all.forwarding=1)"

  MyNic=`ip route | grep default | grep -oP '(?<=dev[\s?])(\S*)'`
  info "get iface: $MyNic"
  info "apply iptables: $(iptables -t nat -A POSTROUTING -o $MyNic -j MASQUERADE)"
  info "apply ip6tables: $(ip6tables -t nat -A POSTROUTING -o ${MyNic} -j MASQUERADE)"
  info "apply iptables: $(iptables -t nat -A PREROUTING -p tcp -i $MyNic --dport 4567 -j DNAT --to-destination 192.168.201.2)"
  info "apply ip6tables: $(ip6tables -t nat -A PREROUTING -p tcp -i ${MyNic} --dport 4567 -j DNAT --to-destination fcc9::2)"
}

stop_process() {
  # kill $(pidof phantun-server phantun-client)
  killall $(pidof phantun-server phantun-client)
  info "terminate phantun process."
}

graceful_stop() {
  warn "caught SIGTERM or SIGINT signal, graceful stopping..."
  stop_process
}

start_phantun() {
  trap 'graceful_stop "$@"' SIGTERM SIGINT
  apply_sysctl "$@"
  "$@" &
  wait
}

start_phantun "$@"
echo "End"
