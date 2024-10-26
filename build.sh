#!/bin/bash

# napcat_version=$(curl "https://api.github.com/repos/NapNeko/NapCatQQ/releases/latest" | jq -r '.tag_name')
napcat_version=$(curl "https://nclatest.znin.net/" | jq -r '.tag_name')

if [ -z $napcat_version ]; then
    exit 1
fi

wget --no-cache -O napcat.packet.py https://github.moeyy.xyz/https://github.com/NapNeko/NapCatQQ/releases/download/$napcat_version/napcat.packet.production.py

# cat <<EOF > "Dockerfile"
# FROM docker.rainbond.cc/python:3.10.12-slim-buster
# RUN apt-get update && apt-get install -y \
#     binutils \
#     && rm -rf /var/lib/apt/lists/*
# COPY napcat.packet.py /
# RUN pip install frida websockets pyinstaller && pyinstaller --onefile napcat.packet.py
# EOF
cat <<EOF > "Dockerfile"
FROM docker.rainbond.cc/debian:10-slim
RUN sed -i 's|http://deb.debian.org/debian|http://mirrors.tuna.tsinghua.edu.cn/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
    software-properties-common \
    build-essential \
    wget \
    uuid-dev \
    tk-dev \
    binutils \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libssl-dev \
    libsqlite3-dev \
    libreadline-dev \
    libffi-dev \
    libbz2-dev \
    liblzma-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN wget https://www.python.org/ftp/python/3.13.0/Python-3.13.0.tar.xz && \
    tar -xf Python-3.13.0.tar.xz && \
    cd Python-3.13.0 && \
    ./configure --enable-optimizations --enable-shared && \
    make -j 4 && \
    make altinstall && \
    cd .. && \
    rm -rf Python-3.13.0 Python-3.13.0.tar.xz
COPY napcat.packet.py /
RUN cp /usr/local/lib/libpython3.13.so* /usr/lib/ && ldconfig
RUN python3.13 -m pip install frida websockets pyinstaller -i https://mirrors.ustc.edu.cn/pypi/simple && python3.13 -m PyInstaller --onefile napcat.packet.py
EOF

docker build -t packet_container .
docker create --name temp_container packet_container

if [ -f "napcat.packet" ]; then
    rm -rf "napcat.packet"
fi

docker cp temp_container:/dist/napcat.packet .

docker rm temp_container
docker rmi packet_container
rm -rf napcat.packet.py
rm -rf Dockerfile

chmod +x napcat.packet