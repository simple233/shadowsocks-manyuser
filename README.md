# shadowsocks-manyuser
shadowsocks-manyuser 数据库版 适用于ss-panel V2
请先准备好Mysql数据库，并且将ss-panel的SQL文件导入

# Debian7 ubuntu14 一键脚本，按照提示操作！

本脚本是在debian7、ubuntu14上测试可行，采用supervisor进程守护。

wget https://raw.githubusercontent.com/simple233/shadowsocks-manyuser/master/ss.sh && chmod +x ss.sh && ./ss.sh

重载下supervisor：

supervisorctl reload

查看状态：

supervisorctl tail -f shadowsocks stderr

# CENTOS比较麻烦，按教程来吧！

1.下载Shadowsocks-manyuser

wget https://raw.githubusercontent.com/simple233/shadowsocks-manyuser/master/shadowsocks.zip

2.安装unzip(没有安装的话)

yum install unzip

3.解压Shadowsocks-manyuser

unzip shadowsocks.zip

4.进入Shadowsocks-manyuser目录

cd /root/shadowsocks 

5.编辑数据库信息

vi Config.py

6.执行安装脚本

sh install.sh

7.编辑加密方式建议aes-256-cfb

vi /root/shadowsocks/config.json

8.手动运行看看是否成功 可省略直接使用下面的开机自动运行设置后重启即可

python server.py

9.首先我们需要安装screen，编辑系统开机启动配置文件将下面的两行命令放进去

9.1.安装screen

yum install screen

9.2.编辑开机启动文件

vi /etc/rc.local

9.3.将下面的两行命令加入开机启动即可

cd /root/shadowsocks/

screen -dmS Shadowsocks python server.py 

# Centos6也许你需要关闭防火墙：

service iptables stop #停止

chkconfig iptables off #禁用 
