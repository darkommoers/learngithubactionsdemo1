#!/usr/bin/env bash
#
#=#!/bin/bash

mkdir -p $PWD/mymain; install -d $PWD/mymain
WORKING_DIR="$PWD/mymain"
echo $WORKING_DIR

mkdir -p $WORKING_DIR/dev/shm; install -d $WORKING_DIR/dev/shm
mkdir -p $WORKING_DIR/etc/xray; install -d $WORKING_DIR/etc/xray

cat <<EOF > $WORKING_DIR/etc/xray/config.json
{
  "log":{"access":"/dev/null","error":"/dev/null","loglevel":"none"},
  "inbounds": 
  [
    {
      "tag": "vless-in-ws-tls",
    #   "listen": "::",
      "listen": "$WORKING_DIR/dev/shm/vlessws.socket,0666",
    #   "port": "54949",
      "protocol": "vless",
      "settings": {"clients": [{"id": "54212000-0000-0000-0000-000000000000"}],"decryption": "none"},
      "streamSettings": {"network": "ws","wsSettings": {"path": "vlessws"}},
      "sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    },
    {
      "tag": "vless-in-httpupgrade-tls",
    #   "listen": "::",
      "listen": "$WORKING_DIR/dev/shm/vlesshttpupgrade.socket,0666",
    #   "port": "54949",
      "protocol": "vless",
      "settings": {"clients": [{"id": "54212000-0000-0000-0000-000000000001"}],"decryption": "none"},
      "streamSettings": {"network": "httpupgrade","httpupgradeSettings": {"path": "/vlesshttpupgrade"}},
      "sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    },
    {
      "tag": "vless-in-grpc-tls",
    #   "listen": "::",
      "listen": "$WORKING_DIR/dev/shm/vlessgrpc.socket,0666",
    #   "port": "54949",
      "protocol": "vless",
      "settings": {"clients": [{"id": "54212000-0000-0000-0000-000000000002"}],"decryption": "none"},
      "streamSettings": {"network": "grpc","grpcSettings": {"serviceName": "vlessgrpc"}},
      "sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    },
    {
      "tag": "vless-in-splithttp-tls",
    #   "listen": "::",
      "listen": "$WORKING_DIR/dev/shm/vlesssplithttp.socket,0666",
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
target_custom_general="$WORKING_DIR/etc/xray/config.json"
sed '/#/d' "$target_custom_general" | cat -s | tee "${target_custom_general}.new" | \
cat -n; mv -f "${target_custom_general}.new" "${target_custom_general}"
unset target_custom_general &>/dev/null

mkdir -p $WORKING_DIR/etc/caddy; install -d $WORKING_DIR/etc/caddy
cat <<EOF > $WORKING_DIR/etc/caddy/Caddyfile
{
# http_port 58480
# https_port 58443
# servers :58480 {
# protocols h1 h2 h2c h3
# }
# servers :58443 {
# protocols h1 h2 h2c h3
# }
# Customizes the admin API endpoint 2019
admin off
# order forward_proxy before reverse_proxy
# order reverse_proxy before route
# auto_https off
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
reverse_proxy @vlessws unix/$WORKING_DIR/dev/shm/vlessws.socket

@vlesshttpupgrade {
header Connection *Upgrade*
header Upgrade    websocket
path /vlesshttpupgrade
}
reverse_proxy @vlesshttpupgrade unix/$WORKING_DIR/dev/shm/vlesshttpupgrade.socket

@vlessgrpc {
# protocol grpc
path /vlessgrpc/*
}
reverse_proxy @vlessgrpc unix+h2c/$WORKING_DIR/dev/shm/vlessgrpc.socket

# handle /vlesssplithttp/* {
# reverse_proxy unix/$WORKING_DIR/dev/shm/vlesssplithttp.socket
# }
@vlesssplithttp {
path /vlesssplithttp/*
}
reverse_proxy @vlesssplithttp unix/$WORKING_DIR/dev/shm/vlesssplithttp.socket

}

EOF
target_custom_general="$WORKING_DIR/etc/caddy/Caddyfile"
sed '/#/d' "${target_custom_general}" | cat -s | tee "${target_custom_general}.new" | \
cat -n; mv -f "${target_custom_general}.new" "${target_custom_general}"
unset target_custom_general &>/dev/null

sudo docker run -it --rm --privileged --net host --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE -v $WORKING_DIR/etc/caddy:/etc/caddy caddy \
caddy fmt --overwrite /etc/caddy/Caddyfile &>/dev/null

sudo docker run -itd \
  --name=xray \
  --privileged \
  --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE \
  --network=host \
  --restart=always \
  -v $WORKING_DIR/etc/xray:/etc/xray \
  -v $WORKING_DIR/dev/shm:$WORKING_DIR/dev/shm \
  teddysun/xray

xray_images="$(docker images | grep xray | awk 'NR==1 {print $1}')";if [ ${xray_images} ]; then  echo "$(date +"%Y-%m-%d %H:%M:%S") === Successfully pulled xray image."; else echo "$(date +"%Y-%m-%d %H:%M:%S") === Failed to pull xray image."; fi

sudo docker run -itd \
  --name=caddy \
  --privileged \
  --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE \
  --network=host \
  --restart=always \
  -v $WORKING_DIR/etc/caddy:/etc/caddy \
  -v $WORKING_DIR/dev/shm:$WORKING_DIR/dev/shm \
  caddy

caddy_images="$(docker images | grep caddy | awk 'NR==1 {print $1}')";if [ ${caddy_images} ]; then  echo "$(date +"%Y-%m-%d %H:%M:%S") === Successfully pulled caddy image."; else echo "$(date +"%Y-%m-%d %H:%M:%S") === Failed to pull caddy image."; fi

sudo docker exec -it --privileged caddy cat /etc/caddy/Caddyfile

docker ps -as
