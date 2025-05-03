#!/bin/bash
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
echo "甬哥Github项目  ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo "Sing-box 真一键无交互脚本（无 Argo 隧道）"
echo "当前版本：25.4.28 测试beta5版"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
export LANG=en_US.UTF-8

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo "请以root模式运行脚本" && exit

# 检测系统
if [[ -f /etc/redhat-release ]]; then
    release="Centos"
elif cat /etc/issue | grep -q -E -i "alpine"; then
    release="alpine"
elif cat /etc/issue | grep -q -E -i "debian"; then
    release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
    release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="Centos"
else 
    echo "脚本不支持当前的系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
if [[ $(echo "$op" | grep -i -E "arch") ]]; then
    echo "脚本不支持当前的 $op 系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi

# 检测 CPU 架构
case $(uname -m) in
    aarch64) cpu=arm64;;
    x86_64) cpu=amd64;;
    *) echo "目前脚本不支持$(uname -m)架构" && exit;;
esac
hostname=$(hostname)
export UUID=${uuid:-''}

# 删除旧的 sing-box 配置和进程
del() {
    kill -15 $(cat /etc/s-box-ag/sbpid.log 2>/dev/null) >/dev/null 2>&1
    if [[ x"${release}" == x"alpine" ]]; then
        rc-service sing-box stop
        rc-update del sing-box default
        rm /etc/init.d/sing-box -f
    else
        systemctl stop sing-box >/dev/null 2>&1
        systemctl disable sing-box >/dev/null 2>&1
        rm -f /etc/systemd/system/sing-box.service
    fi
    crontab -l > /tmp/crontab.tmp
    sed -i '/sbpid/d' /tmp/crontab.tmp
    crontab /tmp/crontab.tmp
    rm /tmp/crontab.tmp
    rm -rf /etc/s-box-ag /usr/bin/agsb
}

# 升级脚本
up() {
    rm -rf /usr/bin/agsb
    curl -L -o /usr/bin/agsb -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh
    chmod +x /usr/bin/agsb
}

# 处理命令行参数
if [[ "$1" == "del" ]]; then
    del && sleep 2
    echo "卸载完成" 
    exit
elif [[ "$1" == "up" ]]; then
    up && sleep 2
    echo "升级完成" 
    exit
fi

# 检查 sing-box 是否已运行
if [[ -n $(ps -e | grep sing-box) ]] && [[ -e /etc/s-box-ag/list.txt ]]; then
    echo "Sing-box 脚本已在运行中"
    echo "当前公网 IP：$(cat /etc/s-box-ag/public_ip.log 2>/dev/null)"
    cat /etc/s-box-ag/list.txt
    exit
elif [[ -z $(ps -e | grep sing-box) ]]; then
    echo "VPS系统：$op"
    echo "CPU架构：$cpu"
    echo "Sing-box 脚本未安装，开始安装…………" && sleep 3
    echo
else
    echo "Sing-box 脚本未启动，可能与其他脚本冲突，请先卸载(agsb del)，再重新安装"
    exit
fi

# 安装依赖
if command -v apt &> /dev/null; then
    apt update -y
    apt install curl wget tar gzip cron jq openssl -y
elif command -v yum &> /dev/null; then
    yum install -y curl wget jq tar openssl
elif command -v apk &> /dev/null; then
    apk update -y
    apk add wget curl tar jq tzdata openssl git grep dcron
else
    echo "不支持当前系统，请手动安装依赖。"
    exit
fi

# 获取公网 IP
public_ip=$(ip addr show enp3s0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
if [[ -z $public_ip ]]; then
    echo "无法获取公网 IP 地址，请检查网络配置"
    exit
fi
echo "公网 IP：$public_ip"
echo "$public_ip" > /etc/s-box-ag/public_ip.log

# 修复主机名解析问题
if ! grep -q "$hostname" /etc/hosts; then
    echo "127.0.0.1 $hostname" >> /etc/hosts
    echo "修复主机名解析：添加 127.0.0.1 $hostname 到 /etc/hosts"
fi

# 安装 sing-box
mkdir -p /etc/s-box-ag
sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
sbname="sing-box-$sbcore-linux-$cpu"
echo "下载 sing-box 最新正式版内核：$sbcore"
curl -L -o /etc/s-box-ag/sing-box.tar.gz -# --retry 2 https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz
if [[ -f '/etc/s-box-ag/sing-box.tar.gz' ]]; then
    tar xzf /etc/s-box-ag/sing-box.tar.gz -C /etc/s-box-ag
    mv /etc/s-box-ag/$sbname/sing-box /etc/s-box-ag
    rm -rf /etc/s-box-ag/{sing-box.tar.gz,$sbname}
else
    echo "下载失败，请检测网络"
    exit
fi

# 设置 UUID
if [ -z $UUID ]; then
    UUID=$(/etc/s-box-ag/sing-box generate uuid)
fi
echo "当前 uuid 密码：$UUID"
sleep 3

# 生成自签名证书（包含 SAN）
cat > /etc/s-box-ag/openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $public_ip

[v3_req]
subjectAltName = IP:$public_ip
EOF
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/s-box-ag/private.key -out /etc/s-box-ag/cert.pem -days 365 -config /etc/s-box-ag/openssl.cnf
if [[ -f /etc/s-box-ag/cert.pem && -f /etc/s-box-ag/private.key ]]; then
    echo "已生成自签名证书：/etc/s-box-ag/cert.pem 和 /etc/s-box-ag/private.key"
else
    echo "证书生成失败，请检查 openssl 安装"
    exit
fi
rm /etc/s-box-ag/openssl.cnf

# 生成 sing-box 配置文件
cat > /etc/s-box-ag/sb.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "debug",
    "timestamp": true,
    "output": "/etc/s-box-ag/sb.log"
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-tls-443",
      "listen": "::",
      "listen_port": 443,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": true,
        "server_name": "$public_ip",
        "certificate_path": "/etc/s-box-ag/cert.pem",
        "key_path": "/etc/s-box-ag/private.key",
        "min_version": "1.2"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-tls-8443",
      "listen": "::",
      "listen_port": 8443,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": true,
        "server_name": "$public_ip",
        "certificate_path": "/etc/s-box-ag/cert.pem",
        "key_path": "/etc/s-box-ag/private.key",
        "min_version": "1.2"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-tls-2053",
      "listen": "::",
      "listen_port": 2053,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": true,
        "server_name": "$public_ip",
        "certificate_path": "/etc/s-box-ag/cert.pem",
        "key_path": "/etc/s-box-ag/private.key",
        "min_version": "1.2"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-tls-2083",
      "listen": "::",
      "listen_port": 2083,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": true,
        "server_name": "$public_ip",
        "certificate_path": "/etc/s-box-ag/cert.pem",
        "key_path": "/etc/s-box-ag/private.key",
        "min_version": "1.2"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-tls-2087",
      "listen": "::",
      "listen_port": 2087,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": true,
        "server_name": "$public_ip",
        "certificate_path": "/etc/s-box-ag/cert.pem",
        "key_path": "/etc/s-box-ag/private.key",
        "min_version": "1.2"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-tls-2096",
      "listen": "::",
      "listen_port": 2096,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": true,
        "server_name": "$public_ip",
        "certificate_path": "/etc/s-box-ag/cert.pem",
        "key_path": "/etc/s-box-ag/private.key",
        "min_version": "1.2"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-80",
      "listen": "::",
      "listen_port": 80,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-8080",
      "listen": "::",
      "listen_port": 8080,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-8880",
      "listen": "::",
      "listen_port": 8880,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-2052",
      "listen": "::",
      "listen_port": 2052,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-2082",
      "listen": "::",
      "listen_port": 2082,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-2086",
      "listen": "::",
      "listen_port": 2086,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-2095",
      "listen": "::",
      "listen_port": 2095,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${UUID}-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

# 启动 sing-box
nohup setsid /etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json >/etc/s-box-ag/sb.log 2>&1 & echo "$!" > /etc/s-box-ag/sbpid.log
crontab -l > /tmp/crontab.tmp
sed -i '/sbpid/d' /tmp/crontab.tmp
echo '@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json >/etc/s-box-ag/sb.log 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbpid.log"' >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp

# 生成 vmess 链接（TLS 节点添加 allowInsecure=1）
up
vmatls_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-$hostname-443\", \"add\": \"$public_ip\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$public_ip\", \"alpn\": \"\", \"fp\": \"\", \"allowInsecure\": true }" | base64 -w0)"
echo "$vmatls_link1" > /etc/s-box-ag/jh.txt
vmatls_link2="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-$hostname-8443\", \"add\": \"$public_ip\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$public_ip\", \"alpn\": \"\", \"fp\": \"\", \"allowInsecure\": true }" | base64 -w0)"
echo "$vmatls_link2" >> /etc/s-box-ag/jh.txt
vmatls_link3="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-$hostname-2053\", \"add\": \"$public_ip\", \"port\": \"2053\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$public_ip\", \"alpn\": \"\", \"fp\": \"\", \"allowInsecure\": true }" | base64 -w0)"
echo "$vmatls_link3" >> /etc/s-box-ag/jh.txt
vmatls_link4="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-$hostname-2083\", \"add\": \"$public_ip\", \"port\": \"2083\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$public_ip\", \"alpn\": \"\", \"fp\": \"\", \"allowInsecure\": true }" | base64 -w0)"
echo "$vmatls_link4" >> /etc/s-box-ag/jh.txt
vmatls_link5="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-$hostname-2087\", \"add\": \"$public_ip\", \"port\": \"2087\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$public_ip\", \"alpn\": \"\", \"fp\": \"\", \"allowInsecure\": true }" | base64 -w0)"
echo "$vmatls_link5" >> /etc/s-box-ag/jh.txt
vmatls_link6="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-$hostname-2096\", \"add\": \"$public_ip\", \"port\": \"2096\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$public_ip\", \"alpn\": \"\", \"fp\": \"\", \"allowInsecure\": true }" | base64 -w0)"
echo "$vmatls_link6" >> /etc/s-box-ag/jh.txt
vma_link7="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-$hostname-80\", \"add\": \"$public_ip\", \"port\": \"80\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link7" >> /etc/s-box-ag/jh.txt
vma_link8="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-$hostname-8080\", \"add\": \"$public_ip\", \"port\": \"8080\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link8" >> /etc/s-box-ag/jh.txt
vma_link9="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-$hostname-8880\", \"add\": \"$public_ip\", \"port\": \"8880\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link9" >> /etc/s-box-ag/jh.txt
vma_link10="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-$hostname-2052\", \"add\": \"$public_ip\", \"port\": \"2052\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link10" >> /etc/s-box-ag/jh.txt
vma_link11="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-$hostname-2082\", \"add\": \"$public_ip\", \"port\": \"2082\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link11" >> /etc/s-box-ag/jh.txt
vma_link12="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-$hostname-2086\", \"add\": \"$public_ip\", \"port\": \"2086\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link12" >> /etc/s-box-ag/jh.txt
vma_link13="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-$hostname-2095\", \"add\": \"$public_ip\", \"port\": \"2095\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$public_ip\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link13" >> /etc/s-box-ag/jh.txt
baseurl=$(base64 -w 0 < /etc/s-box-ag/jh.txt)
line1=$(sed -n '1p' /etc/s-box-ag/jh.txt)
line6=$(sed -n '6p' /etc/s-box-ag/jh.txt)
line7=$(sed -n '7p' /etc/s-box-ag/jh.txt)
line13=$(sed -n '13p' /etc/s-box-ag/jh.txt)

# 输出配置信息
echo "Sing-box 脚本安装完毕" && sleep 2
cat > /etc/s-box-ag/list.txt <<EOF
---------------------------------------------------------
---------------------------------------------------------
单节点配置输出：
1、443端口的vmess-ws-tls节点（自签名证书，需允许不安全连接），IP：$public_ip
$line1

2、2096端口的vmess-ws-tls节点（自签名证书，需允许不安全连接），IP：$public_ip
$line6

3、80端口的vmess-ws节点，IP：$public_ip
$line7

4、2095端口的vmess-ws节点，IP：$public_ip
$line13

---------------------------------------------------------
聚合节点配置输出：
5、节点13个端口及IP全覆盖：7个关tls 80系端口节点、6个开tls 443系端口节点（自签名证书，需允许不安全连接）
$baseurl

相关快捷方式如下：
显示 IP 及节点信息：agsb
升级脚本：agsb up
卸载脚本：agsb del
---------------------------------------------------------
EOF
cat /etc/s-box-ag/list.txt