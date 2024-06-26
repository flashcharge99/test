rm -rf xray
clear
NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
secs_to_human() {
echo -e "${WB}Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds${NC}"
}
start=$(date +%s)
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt install socat netfilter-persistent -y
apt install vnstat lsof fail2ban -y
apt install curl sudo -y
apt install screen cron screenfetch -y
mkdir /user >> /dev/null 2>&1
mkdir /tmp >> /dev/null 2>&1
apt install resolvconf network-manager dnsutils bind9 -y
cat > /etc/systemd/resolved.conf << END
[Resolve]
DNS=8.8.8.8 8.8.4.4
Domains=~.
ReadEtcHosts=yes
END
systemctl enable resolvconf
systemctl enable systemd-resolved
systemctl enable NetworkManager
rm -rf /etc/resolv.conf
rm -rf /etc/resolvconf/resolv.conf.d/head
echo "
nameserver 127.0.0.53
" >> /etc/resolv.conf
echo "
" >> /etc/resolvconf/resolv.conf.d/head
systemctl restart resolvconf
systemctl restart systemd-resolved
systemctl restart NetworkManager
echo "Google DNS" > /user/current
rm /usr/local/etc/xray/city >> /dev/null 2>&1
rm /usr/local/etc/xray/org >> /dev/null 2>&1
rm /usr/local/etc/xray/timezone >> /dev/null 2>&1
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install --beta
curl -s ipinfo.io/city >> /usr/local/etc/xray/city
curl -s ipinfo.io/org | cut -d " " -f 2-10 >> /usr/local/etc/xray/org
curl -s ipinfo.io/timezone >> /usr/local/etc/xray/timezone
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
clear
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
apt install nginx -y
rm -rf /var/www/html/* >> /dev/null 2>&1
rm /etc/nginx/sites-enabled/default >> /dev/null 2>&1
rm /etc/nginx/sites-available/default >> /dev/null 2>&1
mkdir -p /var/www/html/vmess >> /dev/null 2>&1
mkdir -p /var/www/html/vless >> /dev/null 2>&1
mkdir -p /var/www/html/trojan >> /dev/null 2>&1
mkdir -p /var/www/html/ss >> /dev/null 2>&1
mkdir -p /var/www/html/ss2022 >> /dev/null 2>&1
mkdir -p /var/www/html/allxray >> /dev/null 2>&1
systemctl restart nginx
clear
touch /usr/local/etc/xray/domain
echo -e "${YB}Input Domain${NC} "
echo " "
read -rp "Input domain kamu : " -e dns
if [ -z $dns ]; then
echo -e "Nothing input for domain!"
else
echo "$dns" > /usr/local/etc/xray/domain
echo "DNS=$dns" > /var/lib/dnsvps.conf
fi
clear
systemctl stop nginx
systemctl stop xray
domain=$(cat /usr/local/etc/xray/domain)
curl https://get.acme.sh | sh
source ~/.bashrc
bash .acme.sh/acme.sh  --register-account  -m $(echo $RANDOM | md5sum | head -c 6; echo;)@gmail.com --server zerossl
bash .acme.sh/acme.sh --issue -d $domain --server zerossl --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.crt --key-file /usr/local/etc/xray/private.key --standalone --force
chmod 745 /usr/local/etc/xray/private.key
clear
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Nginx & Xray Conf${NC}"
uuid=$(cat /proc/sys/kernel/random/uuid)
pwtr=$(openssl rand -hex 4)
cat > /usr/local/etc/xray/config.json << END
{
  "api": {
    "services": [
      "HandlerService",
      "LoggerService",
      "StatsService"
    ],
    "tag": "api"
  },
  "dns": {
    "queryStrategy": "UseIP",
    "servers": [
      {
        "address": "localhost",
        "domains": [
          "https://1.1.1.1/dns-query"
        ],
        "queryStrategy": "UseIP"
      }
    ],
    "tag": "dns_inbound"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 62789,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
# XTLS
    {
      "listen": "::",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "flow": "xtls-rprx-vision",
            "id": "$uuid"
#vless-xtls
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "alpn": "h2",
            "dest": 2323,
            "xver": 2
          },
          {
            "dest": 800,
            "xver": 2
          },
          {
            "path": "/vless",
            "dest": "@vless-ws",
            "xver": 2
          },
          {
            "path": "/vmess",
            "dest": "@vmess-ws",
            "xver": 2
          },
          {
            "path": "/trojan",
            "dest": "@trojan-ws",
            "xver": 2
          },
          {
            "path": "/vless-hup",
            "dest": "@vl-hup",
            "xver": 2
          },
          {
            "path": "/vmess-hup",
            "dest": "@vm-hup",
            "xver": 2
          },
          {
            "path": "/trojan-hup",
            "dest": "@tr-hup",
            "xver": 2
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "ocspStapling": 3600,
              "certificateFile": "/usr/local/etc/xray/fullchain.crt",
              "keyFile": "/usr/local/etc/xray/private.key"
            }
          ],
          "minVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# TROJAN TCP TLS
    {
      "port": 2323,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr",
            "level": 0
#trojan-tcp
          }
        ],
        "fallbacks": [
          {
            "dest": "844",
            "xver": 2
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "acceptProxyProtocol": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# VLESS WS
    {
      "listen": "@vless-ws",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vless"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# VLESS HUP
    {
      "listen": "@vl-hup",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/vless-hup"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# VMESS WS
    {
      "listen": "@vmess-ws",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "general@vmess-ws", 
            "id": "$uuid",
            "level": 0
#vmess
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmess"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# VMESS HUP
    {
      "listen": "@vm-hup",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "general@vmess-ws", 
            "id": "$uuid",
            "level": 0
#vmess
          }
        ]
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmess-hup"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# TROJAN WS
    {
      "listen": "@trojan-ws",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr",
            "level": 0
#trojan
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# TROJAN HUP
    {
      "listen": "@tr-hup",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr",
            "level": 0
#trojan
          }
        ]
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-hup"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "port": 80,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid"
#universal
          }
        ],
        "fallbacks": [
          {
            "dest": 800,
            "xver": 2
          },
          {
            "path": "/vless",
            "dest": "@vless-ws",
            "xver": 2
          },
          {
            "path": "/vmess",
            "dest": "@vmess-ws",
            "xver": 2
          },
          {
            "path": "/trojan",
            "dest": "@trojan",
            "xver": 2
          }
        ],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
# TROJAN WS
    {
      "listen": "@trojan",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr",
            "level": 0
#trojan
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIP"
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    },
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "sg.vless.sbs",
            "port": 443,
            "users": [
              {
                "encryption": "none",
                "id": "47f5ab29-37cb-4f1a-8638-765c59774836"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": false,
          "alpn": [],
          "fingerprint": "",
          "serverName": "sg.vless.sbs"
        },
        "wsSettings": {
          "headers": {
            "Host": "sg.vless.sbs"
          },
          "host": "sg.vless.sbs",
          "path": "/vless"
        }
      },
      "tag": "sg.vless.sbs"
    }
  ],
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundDownlink": true,
      "statsInboundUplink": true,
      "statsOutboundDownlink": true,
      "statsOutboundUplink": true
    }
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked",
        "type": "field"
      },
      {
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ],
        "type": "field"
      },
      {
        "domain": [
          "geosite:google",
          "geosite:netflix"
        ],
        "outboundTag": "sg.vless.sbs",
        "type": "field"
      }
    ]
  },
  "stats": {}
}
END
cat > /etc/nginx/nginx.conf << END
# Generated by nginxconfig.io
user www-data;
pid /run/nginx.pid;
worker_processes auto;
worker_rlimit_nofile 65535;

events {
   multi_accept on;
   worker_connections 65535;
}

http {
   charset utf-8;
   sendfile on;
   tcp_nopush on;
   tcp_nodelay on;
   server_tokens off;
   types_hash_max_size 2048;
   server_names_hash_bucket_size 128;
   server_names_hash_max_size 512;
   client_max_body_size 16M;

   # MIME
   include mime.types;
   default_type application/octet-stream;

   # logging
   access_log /var/log/nginx/access.log;
   error_log /var/log/nginx/error.log warn;

   # Compression
   gzip on;
   gzip_comp_level 5;
   gzip_min_length 256;
   gzip_proxied any;
   gzip_types application/javascript application/json application/xml text/css text/plain text/xml application/xml+rss;

   include /etc/nginx/conf.d/*.conf;
   include /etc/nginx/sites-enabled/*;

   server {
       listen 800 proxy_protocol default_server;
       listen 844 http2 proxy_protocol default_server;
       set_real_ip_from 127.0.0.1;
       real_ip_header proxy_protocol;
       server_name _;
       return 400;
   }
   server {
       listen 844 http2;
       set_real_ip_from 127.0.0.1;
       real_ip_header proxy_protocol;
       server_name $domain;

       # Web Content
       location / {
         root /var/www/html;
       }
   }
}
END
# wget -q -O /etc/nginx/conf.d/grpc.conf https://raw.githubusercontent.com/dugong-lewat/autoscript2/main/config/grpc.conf

# wget -q -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/dugong-lewat/autoscript2/main/config/nginx.conf
# sudo sed -i -e 's/example.com/${domain}/g' /etc/nginx/conf.d/xray.conf
systemctl restart nginx
systemctl restart xray
echo -e "${GB}[ INFO ]${NC} ${YB}Setup Done${NC}"
sleep 1
clear
# Blokir lalu lintas torrent (BitTorrent)
sudo iptables -A INPUT -p udp --dport 6881:6889 -j DROP
sudo iptables -A INPUT -p tcp --dport 6881:6889 -j DROP
# Blokir lalu lintas torrent dengan modul string
sudo iptables -A INPUT -p tcp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
sudo iptables -A INPUT -p udp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
cd /usr/bin
GITHUB=raw.githubusercontent.com/flashcharge99/test/main
echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Main Menu${NC}"
wget -q -O menu "https://${GITHUB}/menu/menu.sh"
wget -q -O allxray "https://${GITHUB}/menu/allxray.sh"
sleep 0.5

echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu All Xray${NC}"
wget -q -O add-xray "https://${GITHUB}/allxray/add-xray.sh"
wget -q -O del-xray "https://${GITHUB}/allxray/del-xray.sh"
wget -q -O extend-xray "https://${GITHUB}/allxray/extend-xray.sh"
wget -q -O trialxray "https://${GITHUB}/allxray/trialxray.sh"
wget -q -O cek-xray "https://${GITHUB}/allxray/cek-xray.sh"
sleep 0.5

echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Menu Log${NC}"
wget -q -O log-create "https://${GITHUB}/log/log-create.sh"
wget -q -O log-allxray "https://${GITHUB}/log/log-allxray.sh"
sleep 0.5

echo -e "${GB}[ INFO ]${NC} ${YB}Downloading Other Menu${NC}"
wget -q -O xp "https://${GITHUB}/other/xp.sh"
wget -q -O dns "https://${GITHUB}/other/dns.sh"
wget -q -O certxray "https://${GITHUB}/other/certxray.sh"
wget -q -O about "https://${GITHUB}/other/about.sh"
wget -q -O clear-log "https://${GITHUB}/other/clear-log.sh"
wget -q -O changer "https://${GITHUB}/other/changer.sh"
echo -e "${GB}[ INFO ]${NC} ${YB}Download All Menu Done${NC}"
sleep 2
chmod +x add-xray
chmod +x del-xray
chmod +x extend-xray
chmod +x trialxray
chmod +x cek-xray

chmod +x log-create
chmod +x log-allxray

chmod +x menu
chmod +x allxray

chmod +x xp
chmod +x dns
chmod +x certxray
chmod +x about
chmod +x clear-log
chmod +x changer
cd
echo "0 0 * * * root xp" >> /etc/crontab
echo "*/3 * * * * root clear-log" >> /etc/crontab
systemctl restart cron
cat > /root/.profile << END
if [ "$BASH" ]; then
if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi
fi
mesg n || true
clear
menu
END
chmod 644 /root/.profile
clear
echo ""
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "                  ${WB}XRAY SCRIPT BY DUGONG${NC}"
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "                 ${WB}»»» Protocol Service «««${NC}  "
echo -e "${BB}—————————————————————————————————————————————————————————${NC}"
echo -e "  ${YB}- Vmess WS TLS${NC}         : ${YB}443${NC}"
echo -e "  ${YB}- Vmess WS nTLS${NC}        : ${YB}80${NC}"
echo -e "  ${YB}- Vmess HTTPupgrade${NC}    : ${YB}443${NC}"
echo -e "  ${YB}- Vless XTLS Vision${NC}    : ${YB}443${NC}"
echo -e "  ${YB}- Vless WS TLS${NC}         : ${YB}443${NC}"
echo -e "  ${YB}- Vless WS nTLS${NC}        : ${YB}80${NC}"
echo -e "  ${YB}- Vless HTTPupgrade${NC}    : ${YB}443${NC}"
echo -e "  ${YB}- Trojan TCP TLS${NC}       : ${YB}443${NC}"
echo -e "  ${YB}- Trojan WS TLS${NC}        : ${YB}443${NC}"
echo -e "  ${YB}- Trojan WS nTLS${NC}       : ${YB}80${NC}"
echo -e "  ${YB}- Trojan HTTPupgrade${NC}   : ${YB}443${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo ""
rm -f xray
secs_to_human "$(($(date +%s) - ${start}))"
echo -e "${YB}[ WARNING ] reboot now ? (Y/N)${NC} "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
reboot
fi
