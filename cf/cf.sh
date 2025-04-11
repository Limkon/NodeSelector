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

# 创建输出目录
mkdir -p output

# 优选函数：筛选台湾、新加坡节点
result(){
  echo "\n筛选台湾和新加坡的优选节点（各取前3）..."

  # 台湾：TPE（台北）、KHH（高雄）
  awk -F ',' '$2 ~ /TPE|KHH/' output/$ip.csv | sort -t ',' -k5,5n | head -n 3 > output/TW-$ip.csv
  echo "\n台湾优选节点："
  cat output/TW-$ip.csv || echo "无结果"

  # 新加坡：SIN
  awk -F ',' '$2 ~ /SIN/' output/$ip.csv | sort -t ',' -k5,5n | head -n 3 > output/SG-$ip.csv
  echo "\n新加坡优选节点："
  cat output/SG-$ip.csv || echo "无结果"
}

# 检查网络（IPv6可用性）
if timeout 3 ping -c 2 2400:3200::1 &> /dev/null; then
  echo "当前网络支持 IPV4 + IPV6"
else
  echo "当前网络仅支持 IPV4"
fi

# 清理历史测速结果
rm -f output/4.csv output/6.csv

# 下载依赖工具（cf 可执行文件和资源）
[ ! -e cf/cf ] && mkdir -p cf && curl -L -o cf/cf -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/$cpu && chmod +x cf/cf
[ ! -e cf/locations.json ] && curl -s -o cf/locations.json https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/locations.json
[ ! -e cf/ips-v4.txt ] && curl -s -o cf/ips-v4.txt https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/ips-v4.txt
[ ! -e cf/ips-v6.txt ] && curl -s -o cf/ips-v6.txt https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/ips-v6.txt

# IPv4测速并筛选
ip=4
cf/cf -ips 4 -outfile output/4.csv && result

# IPv6测速并筛选
ip=6
cf/cf -ips 6 -outfile output/6.csv && result

# 展示最终结果
[ -e output/TW-4.csv ] && echo "\n台湾 IPV4 优选：" && cat output/TW-4.csv
[ -e output/SG-4.csv ] && echo "\n新加坡 IPV4 优选：" && cat output/SG-4.csv
[ -e output/TW-6.csv ] && echo "\n台湾 IPV6 优选：" && cat output/TW-6.csv
[ -e output/SG-6.csv ] && echo "\n新加坡 IPV6 优选：" && cat output/SG-6.csv

[ ! -e output/4.csv ] && [ ! -e output/6.csv ] && echo "\n运行出错，请检查网络依赖环境"
