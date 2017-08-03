#!/bin/bash
# Author:  admin@k0811.cn
# BLOG:  http://www.k0811.cn
#

#check  root
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script" && exit 1

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

clear;
echo '================================================================';
echo ' www.k0811.cn';
echo ' shadowoscks for manyuser';
echo '================================================================';


base_url="http://down.36zz.net"

cd ~

if [ -f /etc/redhat-release -o -n "`grep 'Linux release' /etc/issue`" ];then
    OS=CentOS
    [ -n "`grep ' 7\.' /etc/redhat-release`" ] && CentOS_RHEL_version=7
    [ -n "`grep ' 6\.' /etc/redhat-release`" -o -n "`grep 'Linux release6 15' /etc/issue`" ] && CentOS_RHEL_version=6
    [ -n "`grep ' 5\.' /etc/redhat-release`" -o -n "`grep 'Linux release5' /etc/issue`" ] && CentOS_RHEL_version=5
elif [ -n "`grep bian /etc/issue`" ];then
    OS=Debian
    Debian_version=`lsb_release -sr | awk -F. '{print $1}'`
elif [ -n "`grep Ubuntu /etc/issue`" ];then
    OS=Ubuntu
    Ubuntu_version=`lsb_release -sr | awk -F. '{print $1}'`
else
    echo "not support this OS"
    kill -9 $$
fi

if [ `getconf WORD_BIT` == 32 ] && [ `getconf LONG_BIT` == 64 ];then
    OS_BIT=64
    SYS_BIG_FLAG=x64 #jdk
    SYS_BIT_a=x86_64;SYS_BIT_b=x86_64; #mariadb
else
    OS_BIT=32
    SYS_BIG_FLAG=i586
    SYS_BIT_a=x86;SYS_BIT_b=i686;
fi


input_info() {
while :
do
                MYSQLHOST="www.k0811.cn"
        echo
        read -p "Please input mysql host(Default host: www.k0811.cn): " MYSQLHOST 
                if [ "${MYSQLHOST}" = "" ]; then
        MYSQLHOST="www.k0811.cn"
                fi
        [ -n "$MYSQLHOST" ] && break
done

while :
do
                MYSQLUSER="root"
        echo
        read -p "Please input database_username(Default username: root): " MYSQLUSER
                if [ "${MYSQLUSER}" = "" ]; then
        MYSQLUSER="root"
                fi
        [ -n "$MYSQLUSER" ] && break
done

while :
do
                MYSQLPASS="123456"
        echo
        read -p "Please input database_password(Default password: k0811.cn): " MYSQLPASS
                if [ "${MYSQLPASS}" = "" ]; then
        MYSQLPASS="123456"
                fi
        [ -n "$MYSQLPASS" ] && break
done

while :
do
                MYSQLDB="shadowsocks"
        echo
        read -p "Please input database_name(Default database_name: shadowsocks): " MYSQLDB
                if [ "${MYSQLDB}" = "" ]; then
        MYSQLDB="shadowsocks"
                fi
        [ -n "$MYSQLDB" ] && break
done

while :
do
                METHOD="rc4-md5"
        echo
        read -p "Please input shadowoscks method:(Default method: aes-256.cfb) " METHOD
                if [ "${METHOD}" = "" ]; then
        METHOD="rc4-md5"
                fi
        [ -n "$METHOD" ] && break
done
}

OS_debian(){
apt-get -y update

for ss_pag in gcc g++ python-pip git python-m2crypto supervisor build-essential autoconf libtool libssl-dev curl python-dev libevent-dev libxml2-dev libxslt-dev python-gevent
do
	apt-get install -y $ss_pag
done

pip install cymysql

git clone -b manyuser https://github.com/mengskysama/shadowsocks.git

cat <<EOF>> /etc/supervisor/conf.d/shadowsocks.conf
[program:shadowsocks]
command=python /root/shadowsocks/shadowsocks/server.py -c /root/shadowsocks/shadowsocks/config.json
autorestart=true
user=root
EOF

echo "ulimit -n 51200" >> /etc/profile
echo "ulimit -Sn 4096" >> /etc/profile
echo "ulimit -Hn 8192" >> /etc/profile
echo "ulimit -n 51200" >> /etc/default/supervisor
echo "ulimit -Sn 4096" >> /etc/default/supervisor
echo "ulimit -Hn 8192" >> /etc/default/supervisor
supervisorctl reload
}

OS_centos(){
#yum -y update

for ss_pag1 in wget git gcc g++ m2crypto setuptool unzip zip libevent-devel python-devel 
do
        yum -y install $ss_pag1
done

#install easy_install
wget $base_url/python/ez_setup.py
python ez_setup.py

#install supervisor
for ss_pag2 in supervisor pip
do
        easy_install $ss_pag2
done

#install cymysql
pip install cymysql 
pip install greenlet
pip install gevent

#install shadowsocks for manyuser
git clone -b manyuser https://github.com/mengskysama/shadowsocks.git

#supervisor Configuration 
mkdir supervisor_log        #Create log files
echo "ulimit -n 51200">> /etc/default/supervisor  #ulimit -n 51200

#create shadowsocks program for supervisor
echo_supervisord_conf > /etc/supervisord.conf
cat <<EOF>> /etc/supervisord.conf
[program:shadowsocks]
command=python /root/shadowsocks/shadowsocks/server.py -c /root/shadowsocks/shadowsocks/config.json
autorestart=true
user=root
stdout_logfile=/root/supervisor_log/shadowsocks.log
EOF

supervisord -c /etc/supervisord.conf     #write in
supervisorctl reload
}

OS_install(){
    if [ $OS == 'CentOS' ];then
        echo "your system is centos."
        OS_centos
    elif [ $OS == 'Debian' -o $OS == 'Ubuntu' ];then
        echo "your system is debian or ubuntu."
        OS_debian
    else
        echo "Not support this OS, Please contact the author! "
        kill -9 $$
    fi
}




#information
set_info(){
sed -i "s@rc4-md5@$METHOD@g" /root/shadowsocks/shadowsocks/config.json
sed -i "s@MYSQL_USER = 'ss'@MYSQL_USER = '$MYSQLUSER'@g" /root/shadowsocks/shadowsocks/Config.py
sed -i 's@mdss.mengsky.net@'$MYSQLHOST'@g' /root/shadowsocks/shadowsocks/Config.py
sed -i "s@MYSQL_PASS = 'ss'@MYSQL_PASS = '$MYSQLPASS'@g" /root/shadowsocks/shadowsocks/Config.py
sed -i "s@shadowsocks@$MYSQLDB@g" /root/shadowsocks/shadowsocks/Config.py
}

#iptables
set_iptables(){
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --dport 80,443,3306 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --sport 80,443,3306 -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sport 1080,22 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dport 1080,22 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 50000:60000 -j ACCEPT
iptables -A OUTPUT -p udp --sport 50000:60000 -j ACCEPT
iptables -A INPUT -p tcp --dport 50000:60000 -j ACCEPT
iptables -A INPUT -p udp --dport 50000:60000 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 50000:60000 -m connlimit --connlimit-above 20 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp --dport 50000:60000 -m connlimit --connlimit-above 20 -j REJECT --reject-with tcp-reset
iptables -A OUTPUT -p tcp -m multiport --dports 25,26,109,110,143,220,366,465,587,691,993,995,2710,6881 -j REJECT --reject-with tcp-reset
iptables -A OUTPUT -p udp -m multiport --dports 25,26,109,110,143,220,366,465,587,691,993,995,2710,6881 -j DROP
#save
iptables-save > /etc/iptables
touch /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables
echo "#!/bin/sh" >> /etc/network/if-pre-up.d/iptables
echo "/sbin/iptables-restore < /etc/iptables" >> /etc/network/if-pre-up.d/iptables
iptables-save > /etc/iptables
}


menu(){
echo -e '\t\tshadowsocks installation'
echo -e '\t1.install shadowsocks'
echo -e '\t2.reload shadowsocks'
echo -e '\t3.shadowsocks status'
echo -e '\t4.remove shadowsocks'
read -p "please enter option:" option
case $option in
1)
	input_info&&
    OS_install&&
	set_info&&
	set_iptables;
	rm -rf ez_setup.py get-pip.py;;
2)
	supervisorctl reload;;
3)
	supervisorctl tail -f shadowsocks stderr;;
4)
	rm -rf /root/shadowsocks;
	supervisorctl stop shadowsocks;;
*)
	echo "error option!";;
esac
}
clear


#===install====
menu
echo '================================================================';
	echo -e '\tshadowsocks.';
	echo 'More help please visit:http://www.k0811.cn';
echo '================================================================';





