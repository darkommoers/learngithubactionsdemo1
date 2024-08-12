#!/usr/bin/env bash
#
#=#!/bin/bash

mkdir -p /etc/xray; install -d /etc/xray
cat <<EOF > /etc/xray/config.json
{
  "log":{"access":"/dev/null","error":"/dev/null","loglevel":"none"},
  "inbounds": 
  [
    {
      "tag": "vless-in-ws-tls",
    #   "listen": "::",
      "listen": "/dev/shm/vlessws.socket,0666",
    #   "port": "54949",
      "protocol": "vless",
      "settings": {"clients": [{"id": "54212000-0000-0000-0000-000000000000"}],"decryption": "none"},
      "streamSettings": {"network": "ws","wsSettings": {"path": "vlessws"}},
      "sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    },
    {
      "tag": "vless-in-httpupgrade-tls",
    #   "listen": "::",
      "listen": "/dev/shm/vlesshttpupgrade.socket,0666",
    #   "port": "54949",
      "protocol": "vless",
      "settings": {"clients": [{"id": "54212000-0000-0000-0000-000000000001"}],"decryption": "none"},
      "streamSettings": {"network": "httpupgrade","httpupgradeSettings": {"path": "/vlesshttpupgrade"}},
      "sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    },
    {
      "tag": "vless-in-grpc-tls",
    #   "listen": "::",
      "listen": "/dev/shm/vlessgrpc.socket,0666",
    #   "port": "54949",
      "protocol": "vless",
      "settings": {"clients": [{"id": "54212000-0000-0000-0000-000000000002"}],"decryption": "none"},
      "streamSettings": {"network": "grpc","grpcSettings": {"serviceName": "vlessgrpc"}},
      "sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    },
    {
      "tag": "vless-in-splithttp-tls",
    #   "listen": "::",
      "listen": "/dev/shm/vlesssplithttp.socket,0666",
    #   "port": "54949",
      "protocol": "vless",
      "settings": {"clients": [{"id": "54212000-0000-0000-0000-000000000003"}],"decryption": "none"},
      "streamSettings": {"network": "splithttp","splithttpSettings": {"path": "/vlesssplithttp"}},
      "sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    }
  ],
  "outbounds": 
  [
    {"protocol": "freedom","tag": "direct"},
    {"protocol": "blackhole","tag": "reject"},
    {
      "tag": "WARP",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "IP50qUeHhUOKhP7oE4/2aDGV6r3oCm5is7Dlk+dqLVM=",
        "address": [
          "172.16.0.2/32",
          "2606:4700:110:8577:4243:68b5:38f1:f798/128"
        ],
        "peers": [
          {
            "endpoint": "engage.cloudflareclient.com:2408",
            "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
            "allowedIPs": [
              "0.0.0.0/0",
              "::/0"
            ]
          }
        ],
        "reserved": [186, 204, 130],
        "mtu": 1280
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "domain": [
          "domain:openai.com",
          "domain:ai.com",
          "domain:chatgpt.com",
          "domain:lmsys.org",
          "domain:ip.sb"
        ],
        "outboundTag": "WARP"
      },
      {
        "type": "field",
        "outboundTag": "WARP",
        "ip": [
          "::/0"
        ]
      }
    ]
  }
}
EOF
target_custom_general="/etc/xray/config.json"
sed '/#/d' "$target_custom_general" | cat -s | tee "${target_custom_general}.new" | \
cat -n; mv -f "${target_custom_general}.new" "${target_custom_general}"
unset target_custom_general &>/dev/null

mkdir -p /etc/caddy; install -d /etc/caddy
cat <<EOF > /etc/caddy/Caddyfile
{
# 可更改默认端口
# http_port 58480
# https_port 58443
# servers :58480 {
# protocols h1 h2 h2c h3
# }
# servers :58443 {
# protocols h1 h2 h2c h3
# }
# Customizes the admin API endpoint 2019端口这玩意
admin off
# order forward_proxy before reverse_proxy
# order reverse_proxy before route
# 真关闭证书自动申请
# auto_https off
# 关闭日志
log {
output discard
}
servers :54949 {
protocols h1 h2 h2c h3
}

}

# http://, :54949 {
:54949 {

@vlessws {
header Connection *Upgrade*
header Upgrade    websocket
path /vlessws
}
reverse_proxy @vlessws unix//dev/shm/vlessws.socket

@vlesshttpupgrade {
header Connection *Upgrade*
header Upgrade    websocket
path /vlesshttpupgrade
}
reverse_proxy @vlesshttpupgrade unix//dev/shm/vlesshttpupgrade.socket

@vlessgrpc {
# protocol grpc
path /vlessgrpc/*
}
reverse_proxy @vlessgrpc unix+h2c//dev/shm/vlessgrpc.socket

# handle /vlesssplithttp/* {
# reverse_proxy unix//dev/shm/vlesssplithttp.socket
# }
@vlesssplithttp {
path /vlesssplithttp/*
}
reverse_proxy @vlesssplithttp unix//dev/shm/vlesssplithttp.socket

}

EOF
target_custom_general="/etc/caddy/Caddyfile"
sed '/#/d' "${target_custom_general}" | cat -s | tee "${target_custom_general}.new" | \
cat -n; mv -f "${target_custom_general}.new" "${target_custom_general}"
unset target_custom_general &>/dev/null

docker run -it --rm --privileged --net host --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE -v /etc/caddy:/etc/caddy caddy \
caddy fmt --overwrite /etc/caddy/Caddyfile &>/dev/null

cat /etc/caddy/Caddyfile

sudo docker run -itd \
  --name=xray \
  --privileged \
  --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE \
  --network=host \
  --restart=always \
  -v /etc/xray:/etc/xray \
  -v /dev/shm:/dev/shm \
  teddysun/xray

xray_images="$(docker images | grep xray | awk 'NR==1 {print $1}')";if [ ${xray_images} ]; then  echo "$(date +"%Y-%m-%d %H:%M:%S") === Successfully pulled xray image."; else echo "$(date +"%Y-%m-%d %H:%M:%S") === Failed to pull xray image."; fi

sudo docker run -itd \
  --name=caddy \
  --privileged \
  --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE \
  --network=host \
  --restart=always \
  -v /etc/caddy:/etc/caddy \
  -v /dev/shm:/dev/shm \
  caddy

caddy_images="$(docker images | grep caddy | awk 'NR==1 {print $1}')";if [ ${caddy_images} ]; then  echo "$(date +"%Y-%m-%d %H:%M:%S") === Successfully pulled caddy image."; else echo "$(date +"%Y-%m-%d %H:%M:%S") === Failed to pull caddy image."; fi

docker ps -as