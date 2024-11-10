#!/bin/bash

sudo apt-get install -y -qq jq wget unzip libnss3 libgbm1 libasound2

wget https://github.com/NapNeko/NapCatQQ/releases/latest/download/NapCat.Shell.zip

unzip -o NapCat.Shell.zip -d /opt/QQ/resources/app/app_launcher/napcat/

rm -rf NapCat.Shell.zip

echo "正在备份并修改 /opt/QQ/resources/app/package.json..."

sudo cp -f /opt/QQ/resources/app/package.json /opt/QQ/resources/app/package.json.bak

if sudo jq '.main = "./loadNapCat.js"' /opt/QQ/resources/app/package.json > ./package.json.tmp; then
    sudo mv ./package.json.tmp /opt/QQ/resources/app/package.json
    echo "修改QQ启动配置成功..."
else
    echo "修改失败，还原备份..."
    sudo mv /opt/QQ/resources/app/package.json.bak /opt/QQ/resources/app/package.json
    exit 1
fi

echo "正在修补文件..."
sudo echo "(async () => {await import('file:///opt/QQ/resources/app/app_launcher/napcat/napcat.mjs');})();" > /opt/QQ/resources/app/loadNapCat.js
if [ $? -ne 0 ]; then
    echo "loadNapCat.js文件写入失败, 请以root身份运行。"
    clean
    exit 1
else
    echo "修补文件成功"
fi
