#!/bin/bash
# cai dat phan ho tro
function deps() {
    yum install -y flex bison kernel-devel kernel-headers gcc gcc-c++ make wget epel-release lz4-devel
    yum install -y git libpcap zlib libyaml libpcap-devel jansson-devel pcre-devel lua-devel libmaxminddb-devel epel-release libnetfilter_queue-devel nss-devel libyaml-devel zlib-devel luajit-devel rustc cargo

}
function PF_RING() {
    cd ~ || exit
    git clone https://github.com/ntop/PF_RING.git
    ln -s /usr/src/kernels/3.10.0-1160.36.2.el7.x86_64 /lib/modules/3.10.0-1127.el7.x86_64/build -f
    cd ~/PF_RING || exit
    make
    ln -s /usr/src/kernels/3.10.0-1160.6.1.el7.x86_64 /lib/modules/3.10.0-1127.el7.x86_64/build -f
    make
    cd kernel || exit
    make && make install
    insmod pf_ring.ko
    cd ../userland/lib || exit
    ./configure && make && make install
    cd ../libpcap || exit
    ./configure && make && make install

}

function Luajit() {
    cd ~ || exit
    wget http://luajit.org/download/LuaJIT-2.0.4.tar.gz
    tar -xzvf LuaJIT-2.0.4.tar.gz && rm -f LuaJIT-2.0.4.tar.gz
    cd LuaJIT-2.0.4 || exit
    make && make install
}

function suricata() {
    cd ~ || exit
    wget https://www.openinfosecfoundation.org/download/suricata-6.0.3.tar.gz
    tar -xzvf suricata-6.0.3.tar.gz && rm -f suricata-6.0.3.tar.gz
    cd suricata-6.0.3 || exit
    LIBS="-lrt" ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-pfring --with-libpfring-includes=/usr/local/pfring/include --with-libpfring-libraries=/usr/local/pfring/lib --enable-geoip --enable-luajit --with-libluajit-includes=/usr/local/include/luajit-2.0/ --with-libluajit-libraries=/usr/local/lib/ --with-libhs-includes=/usr/local/include/hs/ --with-libhs-libraries=/usr/local/lib/ --enable-profiling --enable-nfqueue
    make clean && make && make install && ldconfig && ldconfig
    make instal-conf
    echo '/usr/local/lib' >>/etc/ld.so.conf
    ldconfig
}

function rules_default() {
    cd ~/suricata-6.0.3 || exit
    make install-conf
    make install-rules
    suricata-update || yum install -y python3-pip && python3 -m pip install --upgrade suricata-update
    suricata-update
}

function ft_config() {
    cd ~ || exit
    mv /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak
    cp suricata.yaml /etc/suricata/suricata.yaml
    cp suricata.service /usr/lib/systemd/system/suricata.service
    systemctl daemon-reload
    suricata-update

}

function suricata_start() {
    service suricata srtart
}

deps
PF_RING
Luajit
suricata
rules_default
ft_config
suricata_start
