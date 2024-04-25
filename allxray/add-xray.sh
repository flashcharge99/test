NC='\e[0m'
DEFBOLD='\e[39;1m'
RB='\e[31;1m'
GB='\e[32;1m'
YB='\e[33;1m'
BB='\e[34;1m'
MB='\e[35;1m'
CB='\e[35;1m'
WB='\e[37;1m'
clear
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "          ${WB}----- [  Create All Xray  ] -----${NC}         "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -rp "Username: " -e user
CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/config.json | wc -l)
if [[ ${CLIENT_EXISTS} == '1' ]]; then
clear
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e "          ${WB}----- [  Create All Xray  ] -----${NC}         "
echo -e "${BB}————————————————————————————————————————————————————${NC}"
echo -e ""
echo -e "${YB}A client with the specified name was already created, please choose another name.${NC}"
echo -e ""
echo -e "${BB}————————————————————————————————————————————————————${NC}"
read -n 1 -s -r -p "Press any key to back on menu"
add-xray
clear
fi
done
domain=$(cat /usr/local/etc/xray/domain)
uuid=$(cat /proc/sys/kernel/random/uuid)
pwtr=$(openssl rand -hex 4)
read -p "Expired (days): " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#universal$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vmess$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vless$/a\#&@ '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#vless-xtls$/a\#&@ '"$user $exp"'\
},{"flow": "'""xtls-rprx-vision""'","id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#trojan$/a\#&@ '"$user $exp"'\
},{"password": "'""$pwtr""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#trojan-tcp$/a\#&@ '"$user $exp"'\
},{"password": "'""$pwtr""'","email": "'""$user""'"' /usr/local/etc/xray/config.json

ISP=$(cat /usr/local/etc/xray/org)
CITY=$(cat /usr/local/etc/xray/city)
vmlink1=`cat<<EOF
{
"v": "2",
"ps": "${user}",
"add": "${domain}",
"port": "443",
"id": "${uuid}",
"aid": "0",
"net": "ws",
"path": "/vmess",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`
vmlink2=`cat<<EOF
{
"v": "2",
"ps": "${user}",
"add": "${domain}",
"port": "80",
"id": "${uuid}",
"aid": "0",
"net": "ws",
"path": "/vmess",
"type": "none",
"host": "$domain",
"tls": "none"
}
EOF`
vmesslink1="vmess://$(echo $vmlink1 | base64 -w 0)"
vmesslink2="vmess://$(echo $vmlink2 | base64 -w 0)"

vlesslink1="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#$user"
vlesslink2="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user"
vlesslink3="vless://$uuid@$domain:443?security=tls&encryption=none&headerType=none&type=tcp&sni=$domain&flow=xtls-rprx-vision&fp=chrome#$user"

trojanlink1="trojan://$pwtr@$domain:443?path=/trojan&security=tls&host=$domain&type=ws&sni=$domain#$user"
trojanlink2="trojan://$pwtr@$domain:80?path=/trojan&security=none&host=$domain&type=ws#$user"
trojanlink3="trojan://$pwtr@$domain:443?security=tls&type=tcp&sni=$domain#$user"


cat > /var/www/html/allxray/allxray-$user.txt << END
========================================
        ----- [ All Xray ] -----
========================================
Domain      : $domain
ISP         : $ISP
City        : $CITY
Port TLS    : 443
Port NTLS   : 80
Network     : TCP, Websocket
Alpn        : h2, http/1.1
Expired On  : $exp
========================================
        ----- [ Vmess Link ] -----
========================================
Link TLS   : $vmesslink1
========================================
Link NTLS  : $vmesslink2
========================================

========================================
        ----- [ Vless Link ] -----
========================================
Link TLS   : $vlesslink1
========================================
Link NTLS  : $vlesslink2
========================================
Link XTLS  : $vlesslink3
========================================

========================================
       ----- [ Trojan Link ] -----
========================================
Link TLS   : $trojanlink1
========================================
Link NTLS  : $trojanlink2
========================================
Link TCP   : $trojanlink3
========================================
END
systemctl restart xray
clear
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "              ----- [ All Xray ] -----              " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Domain       : $domain" | tee -a /user/log-allxray-$user.txt
echo -e "ISP          : $ISP" | tee -a /user/log-allxray-$user.txt
echo -e "City         : $CITY" | tee -a /user/log-allxray-$user.txt
echo -e "Port TLS     : 443" | tee -a /user/log-allxray-$user.txt
echo -e "Port NTLS    : 80" | tee -a /user/log-allxray-$user.txt
echo -e "Network      : TCP, Websocket" | tee -a /user/log-allxray-$user.txt
echo -e "Alpn         : h2, http/1.1" | tee -a /user/log-allxray-$user.txt
echo -e "Expired On   : $exp" | tee -a /user/log-allxray-$user.txt
echo -e "Link Akun    : https://$domain/allxray/allxray-$user.txt" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "             ----- [ Vmess Link ] -----             " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link TLS   : $vmesslink1" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link NTLS  : $vmesslink2" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "             ----- [ Vless Link ] -----             " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link TLS   : $vlesslink1" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link NTLS  : $vlesslink2" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link XTLS  : $vlesslink3" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "            ----- [ Trojan Link ] -----             " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link TLS   : $trojanlink1" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link NTLS  : $trojanlink2" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link TCP   : $trojanlink3 | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
read -n 1 -s -r -p "Press any key to back on menu"
clear
allxray
