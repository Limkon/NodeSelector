#!/bin/bash
export LANG=en_US.UTF-8

# 自动判断系统架构
case "$(uname -m)" in
  x86_64 | x64 | amd64 ) cpu=amd64;;
  i386 | i686 ) cpu=386;;
  armv8 | armv8l | arm64 | aarch64 ) cpu=arm64;;
  armv7l ) cpu=arm;;
  mips64le ) cpu=mips64le;;
  mips64 ) cpu=mips64;;
  mips | mipsle ) cpu=mipsle;;
  * ) echo "当前架构为$(uname -m)，暂不支持"; exit;;
esac

# 优选函数：筛选台湾、新加坡节点
result(){
  echo "\n筛选台湾和新加坡的优选节点（各取前3）..."
  
  # 台湾：TPE（台北）、KHH（高雄）
  awk -F ',' '$2 ~ /TPE|KHH/' $ip.csv | sort -t ',' -k5,5n | head -n 3 > TW-$ip.csv
  echo "\n台湾优选节点："
  cat TW-$ip.csv
  
  # 新加坡：SIN
  awk -F ',' '$2 ~ /SIN/' $ip.csv | sort -t ',' -k5,5n | head -n 3 > SG-$ip.csv
  echo "\n新加坡优选节点："
  cat SG-$ip.csv
}

# 检查网络
if timeout 3 ping -c 2 2400:3200::1 &> /dev/null; then
  echo "当前网络支持 IPV4 + IPV6"
else
  echo "当前网络仅支持 IPV4"
fi

# 初始化环境
rm -rf 6.csv 4.csv

# 下载依赖工具
[ ! -e cf ] && curl -L -o cf -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/$cpu && chmod +x cf
[ ! -e locations.json ] && curl -s -o locations.json https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/locations.json
[ ! -e ips-v4.txt ] && curl -s -o ips-v4.txt https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/ips-v4.txt
[ ! -e ips-v6.txt ] && curl -s -o ips-v6.txt https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/ips-v6.txt

# 运行测速：同时执行 IPv4 和 IPv6
ip=4
./cf -ips 4 -outfile 4.csv
result
ip=6
./cf -ips 6 -outfile 6.csv
result

# 展示结果
if [ -e TW-4.csv ]; then
  echo "\n台湾 IPV4 优选："
  cat TW-4.csv
fi
if [ -e SG-4.csv ]; then
  echo "\n新加坡 IPV4 优选："
  cat SG-4.csv
fi
if [ -e TW-6.csv ]; then
  echo "\n台湾 IPV6 优选："
  cat TW-6.csv
fi
if [ -e SG-6.csv ]; then
  echo "\n新加坡 IPV6 优选："
  cat SG-6.csv
fi

[ ! -e 4.csv ] && [ ! -e 6.csv ] && echo "\n运行出错，请检查网络依赖环境"
