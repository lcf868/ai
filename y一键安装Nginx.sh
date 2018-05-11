#!/bin/bash
echo "********Auto install nginxnginx-1.14.0-zjc********"
#----------------------------------------------------检测YUM源
yum clean all &>/dev/null
n=`yum repolist | awk '/repolist:/{print$2}' | sed 's/,//g'` #通过检测安装个数做判断
[ $n -lt 10 ] && echo '你的YUM源没配置成功!' && exit

#-----------------------------------------------------检测和安装nginx的依赖包
sw=(gcc make openssl-devel pcre mariadb mariadb-server mariadb-devel php php-fpm php-mysql zlib-devel)                    #配置要安装哪些依赖包
for y in ${sw[@]};do                    
        yum -y install $y | awk '/(已安装)|(installed)/{print}'
        [ $? -eq 0 ] && ck='yes' || ck='no' 
done
[ $ck = 'no' ] && echo "有依赖包没安装成功，请检查..." && exit

#----------------------------------------------------检测nginx是否装好，没安装就先寻找本地有没有nginx.1.14的安装包，没有就去网上下载
n=`find / -name 'nginx' -type f | awk '/sbin\/nginx/{print}'`
n=${n:-null}
if [ -z $n ];then         
	tmp=`find / -name "nginx-1.14*.gz" -type f | head -1`
	if [ $? -ne 0 ];then
		cd /tmp/
        	wget http://nginx.org/download/nginx-1.14.0.tar.gz
            [ $? -ne 0 ] && echo "nginx.1.14 下载失败!" && exit
	fi
	tar -xpf $tmp -C /tmp
      cd /tmp/nginx-1.14*
      ./configure
      sleep2
      make && make install
else
	echo  'Nginx已经安装好，默认目录是：/usr/local/nginx/sbin/nginx'
fi

#----------------------------------------------------建一个system的nginx服务脚本，让nginx也可以用systemctl来操作。
n=`find / -name "nginx.service" -type f`
if [ $n != '/usr/lib/systemd/system/nginx.service' ];then
echo '[Unit]
Description=nginx
After=network.target
[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true
[Install]
WantedBy=multi-user.target' >/usr/lib/systemd/system/nginx.service
fi

#----------------------------------------------------循环检测80端口使用的进程，再把检测到的80相关进程全部关闭掉。
while :
do
        jc=`lsof -i:80 | awk 'NR==2{print $1}'`
        [ -z $jc ] && break
        killall -q $jc
done

#----------------------------------------------------启动nginx服务
systemctl restart nginx.service
systemctl enable nginx.service




  

