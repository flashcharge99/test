user=trial-`echo $RANDOM | head -c4`
masaaktif=1
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
vmlink3=`cat<<EOF
{
"v": "2",
"ps": "${user}",
"add": "${domain}",
"port": "443",
"id": "${uuid}",
"aid": "0",
"net": "httpupgrade",
"path": "/vmess-hup",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`
vmesslink1="vmess://$(echo $vmlink1 | base64 -w 0)"
vmesslink2="vmess://$(echo $vmlink2 | base64 -w 0)"
vmesslink3="vmess://$(echo $vmlink3 | base64 -w 0)"

vlesslink1="vless://$uuid@$domain:443?path=/vless&security=tls&encryption=none&host=$domain&type=ws&sni=$domain#$user"
vlesslink2="vless://$uuid@$domain:80?path=/vless&security=none&encryption=none&host=$domain&type=ws#$user"
vlesslink3="vless://$uuid@$domain:443?security=tls&encryption=none&headerType=none&type=tcp&sni=$domain&flow=xtls-rprx-vision&fp=chrome#$user"
vlesslink4="vless://$uuid@$domain:443?path=/vless-hup&security=tls&encryption=none&host=$domain&type=httpupgrade&sni=$domain#$user"

trojanlink1="trojan://$pwtr@$domain:443?path=/trojan&security=tls&host=$domain&type=ws&sni=$domain#$user"
trojanlink2="trojan://$pwtr@$domain:80?path=/trojan&security=none&host=$domain&type=ws#$user"
trojanlink3="trojan://$pwtr@$domain:443?security=tls&type=tcp&sni=$domain#$user"
trojanlink4="trojan://$pwtr@$domain:443?path=/trojan-hup&security=tls&host=$domain&type=httpupgrade&sni=$domain#$user"

cat > /var/www/html/allxray/allxray-$user.txt << END
========================================
        ----- [ All Xray ] -----
========================================
Domain            : $domain
ISP               : $ISP
City              : $CITY
Port WS TLS       : 443
Port WS nTLS      : 80
Port HTTPupgrade  : 443
Network           : TCP, Websocket, HTTPupgrade
Alpn              : h2, http/1.1
Expired On        : $exp
========================================
        ----- [ Vmess Link ] -----
========================================
Link WS TLS       : $vmesslink1
========================================
Link WS nTLS      : $vmesslink2
========================================
Link HTTPupgrade  : $vmesslink3
========================================

========================================
        ----- [ Vless Link ] -----
========================================
Link WS TLS       : $vlesslink1
========================================
Link WS nTLS      : $vlesslink2
========================================
Link XTLS         : $vlesslink3
========================================
Link HTTPupgrade  : $vlesslink4
========================================

========================================
       ----- [ Trojan Link ] -----
========================================
Link WS TLS       : $trojanlink1
========================================
Link WS nTLS      : $trojanlink2
========================================
Link TCP TLS      : $trojanlink3
========================================
Link HTTPupgrade  : $trojanlink4
========================================
END
systemctl restart xray
clear
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "              ----- [ All Xray ] -----              " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Domain             : $domain" | tee -a /user/log-allxray-$user.txt
echo -e "ISP                : $ISP" | tee -a /user/log-allxray-$user.txt
echo -e "City               : $CITY" | tee -a /user/log-allxray-$user.txt
echo -e "Port WS TLS        : 443" | tee -a /user/log-allxray-$user.txt
echo -e "Port WS nTLS       : 80" | tee -a /user/log-allxray-$user.txt
echo -e "Port HTTPupgrade   : 443" | tee -a /user/log-allxray-$user.txt
echo -e "Network            : TCP, Websocket, HTTPupgrade" | tee -a /user/log-allxray-$user.txt
echo -e "Alpn               : h2, http/1.1" | tee -a /user/log-allxray-$user.txt
echo -e "Expired On         : $exp" | tee -a /user/log-allxray-$user.txt
echo -e "Link Akun          : https://$domain/allxray/allxray-$user.txt" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "             ----- [ Vmess Link ] -----             " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link WS TLS       : $vmesslink1" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link WS nTLS      : $vmesslink2" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link HTTPupgrade  : $vmesslink3" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "             ----- [ Vless Link ] -----             " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link WS TLS       : $vlesslink1" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link WS nTLS      : $vlesslink2" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link XTLS         : $vlesslink3" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link HTTPupgrade  : $vlesslink4" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "            ----- [ Trojan Link ] -----             " | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link WS TLS      : $trojanlink1" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link WS nTLS     : $trojanlink2" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link TCP TLS     : $trojanlink3" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e "Link HTTPupgrade : $trojanlink4" | tee -a /user/log-allxray-$user.txt
echo -e "————————————————————————————————————————————————————" | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
echo -e " " | tee -a /user/log-allxray-$user.txt
read -n 1 -s -r -p "Press any key to back on menu"
clear
allxray
