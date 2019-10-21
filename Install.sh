安装编译所需软件
获取 TrinityCore 代码
用 cmake 生成 makefile
make && make install
用编译出的提取器提取地图
按需修改 etc/*.conf 文件
在 mysql 中创建 trinity 账户
下载相应 TDB ，将其中的 sql 文件解压至 bin/ 下
在 bin/ 下启动 worldserver 导入数据库
01 脚本tcinit简介
tcinit 是一个 bash 脚本，基于yum，你可以在RedHat系的distro中运行；但经过简单修改你就可以让它运行在debian上
tcinit 基本涵盖了上述除个别requirements的手动编译及下载TDB之外的所有步骤
将仓库路径写入环境变量，方便之后再次运行脚本
将安装路径写入环境变量，安装后可以直接用 tcinit 启动服务器
可选择分支 3.3.5 或 master
tcinit -h 可查看帮助
tcinit 的代码在 github 上
tcinit 的实现过程基本遵循官方 wiki
02 存在的问题
未检查 requirements，which I don't want to, 把任务丢给 yum install 吧
未检查目录是否是 TrinityCore 仓库
03 代码样本（可能已过时，github 上有更新）

#!/bin/bash
#
# tcinit
# version 1.2
#
# A Bash script for Redhat derivative to implement TrinityCore 3.3.5 or 6.x
# Including requirements installation, clone repo, cmake, make, sql import, maps extraction and more.
# All you need to do is download the TDB_full_*.7z from https://github.com/TrinityCore/TrinityCore/releases and put it into directory where tcinit at, tcinit --init will do the rest.
#
# Dot Craft(dotcra@gmail.com) Sep 5, 2016
# More details on http://dotcra.com
############### Variables ###############
# branch number
branum=
# TrinityCor repo dir
repodir=$repodir
# server dir
srvdir=$srvdir
# wow dir
wowdir=
# yum or dnf
type dnf &> /dev/null && yum=dnf || yum=yum
# required softwares version
ver=
# required softwares, used to contain cmake, gcc and boost which may not match the requirements in EL
requi1= requi2= requi3= requi4=
# OS distro
distro=$(awk '{print $1}' /etc/redhat-release)
# dir of this script
thisdir=$(dirname $0)
[ ${thisdir:0:1} == / ] || thisdir=$(pwd)/$thisdir
############### Functions ###############
# Show version
version() {
echo "tcinit 1.2 by Dot Craft(dotcra@gmail.com) Sep 7, 2016"
echo "More details on http://dotcra.com"
}
# Display help
readme() {
echo "\
tcinit is a script for Redhat derivative to implement TrinityCore 3.3.5 or 6.x
Including requirements installation, clone repo, cmake, make, sql import, maps extraction and more.
All you need to do is download the TDB_full_*.7z from https://github.com/TrinityCore/TrinityCore/releases and put it into directory where tcinit at, tcinit --init will do the rest.
Usage:
tcinit [option]
Options:
-s shutdown all servers
--init implement a brandnew TrinityCore
-d, --debug debug
-h display this help
-v display version information
-q run server in background
run server as interactive cli if no parameter is given
Visit http://dotcra.com for more details."
}
# check requirements
chkrequi() {
echo "Checking requirements."
# shoud I do the check here? cause yum and dnf will do it again.
}
# install requirements
requi (){
# if version not match the requirements, keep variable $requiN's value NULL, so it won't be installed in yum install
ver=$($yum info cmake | grep -m1 Version | awk '{print $3}')
[ "$ver" \< 3.0 ] && getcmake3 || requi1=cmake
ver=$($yum info gcc | grep -m1 Version | awk '{print $3}')
[ "$ver" \< 4.9.0 ] && echo "gcc $ver in repo not match requirements(4.9.0), you must compile it yourself. " || requi2="gcc gcc-c++"
ver=$($yum info boost | grep -m1 Version | awk '{print $3}')
[ "$ver" \< 1.55 ] && echo "Boost $ver in repo not match requirements(1.55), you must compile it yourself. " || requi3=boost-devel
[ "$distro" == CentOS -o "$distro" == Red ] && requi4="libquadmath-devel python-devel"
echo "Install requirements, root password is needed."
i=1
while [ "$i" == 1 ]
do
# install requirements, if cmake3 is installed, make a link to avoid future "cmake command not found"
# updatedb for locate in exmaps()
su -c "[ "$requi1" == cmake3 ] && ln -s /usr/bin/cmake3 /usr/bin/cmake 2> /dev/null; updatedb; $yum install -y git make mariadb-devel openssl-devel bzip2-devel readline-devel ncurses-devel $requi4 $requi1 $requi2 $requi3 mariadb-server p7zip"
i=$?
done
}
getcmake3() {
# if CentOS or RedHat distro, install EPEL repo
if [ "$distro" == CentOS -o "$distro" == Red ]; then
# if EPEL repo not installed, install
if ! rpm -q epel-release &> /dev/null; then
echo "Adding EPEL repo, root passowrd is needed"
i=1
while [ "$i" == 1 ]
do
su -c "yum install -y epel-release"
i=$?
done
fi
# if EPEL repo successfully installed, set $requi1 to cmake3 so it will be installed in requi()
rpm -q epel-release &> /dev/null && requi1=cmake3
else
echo "cmake $ver in repo not match requirements(3.0), you must compile it yourself."
fi
return 0
}
# choose branch
chbran (){
echo "Which branch you want?"
select branum in 3.3.5 6.x
do
[ -n "$branum" ] && break
done
echo "$branum branch will be implemented."
# choose repo dir
if [ -z $repodir ]; then
read -p "Specify the path of TrinityCore repository on your system, or type a name to clone a new one:" repodir
[ -z $repodir ] && repodir=~/TrinityCore
fi
# when $repodir exists, keep trying git clone or git checkout until success
i=1
while [ -d $repodir -a $i != 0 ]
do
# if $repodir is empty
if [ $(ls -a $repodir | wc -w) == 2 ]; then
# clone if empty
git clone -b $branum git://github.com/TrinityCore/TrinityCore.git $repodir && i=0
else
# try git checkout if not empty, ask for another directory when fails
cd $repodir
git checkout $branum 2> /dev/null
i=$?
[ $i == 0 ] && git pull
[ $i != 0 ] && read -p "$repodir is not empty, choose another directory:" repodir
[ -z $repodir ] && repodir=~/TrinityCore
cd -
fi
done
[ ! -d $repodir ] && git clone -b $branum git://github.com/TrinityCore/TrinityCore.git $repodir
[ "${repodir:0:1}" == / ] || repodir=$(pwd)/$repodir
if grep -q repodir ~/.bashrc; then
sed -i /repodir/s:=.*:=$repodir: ~/.bashrc
else
echo >> ~/.bashrc
echo "# Generated by tcinit" >> ~/.bashrc
echo "export repodir=$repodir" >> ~/.bashrc
fi
. ~/.bashrc
}
runcmake (){
# choose server dir
if [ -z $srvdir ]; then
read -p "Where do you want to place the server (default $HOME/server):" srvdir
[ -z $srvdir ] && srvdir=~/server
fi
[ "${srvdir:0:1}" != / ] && srvdir=$(pwd)/$srvdir
mkdir -p $repodir/build; cd $repodir/build && rm * -rf
echo "Running cmake with parameters: -DCMAKE_INSTALL_PREFIX=$srvdir -DTOOLS=1 -DWITH_WARNINGS=1"
cmake ../ -DCMAKE_INSTALL_PREFIX=$srvdir -DTOOLS=1 -DWITH_WARNINGS=1
}
# make & make install
runmake (){
IFS=,
i= # unnecessary but safer. read will set var to null when time out
read -p "Starting Make in 5 secconds, press any key to skip." -t5 -sn1 i
echo
# how to handle enter?
if [ -z $i ]; then
echo "################## start Make ##################"
echo -e "start make TrinityCore at\t$(date +%T)" > $repodir/build/make_tc_time_cost
make -j $(nproc)
echo -e "finish make TrinityCore at\t$(date +%T)" >> $repodir/build/make_tc_time_cost
make install
# make $srvdir environment so you can start the server via this script afterwards
if grep -q srvdir ~/.bashrc; then
sed -i /srvdir/s:=.*:=$srvdir: ~/.bashrc
else
echo >> ~/.bashrc
echo "# Generated by tcinit" >> ~/.bashrc
echo "export srvdir=$srvdir" >> ~/.bashrc
fi
. ~/.bashrc
else
return
fi
echo
}
# copy conf
setconf (){
mkdir -p $srvdir/log
cd $srvdir/etc
cp worldserver.conf.dist worldserver.conf
if [ "$branum" == 6.x ]; then
cp bnetserver.conf.dist bnetserver.conf
# edit "LogsDir" value to "$srvdir/log" in bnetserver.conf(6.x only), default "."
# there're slashes in $srvdir, so the delimiter / have to be replaced with : in sed substitution
sed -i /^LogsDir/s:\".*\":\"$srvdir/log\": bnetserver.conf
# edit path of "CertificateFile" and "PrivateKeyFile" in bnetserver.conf so server can be start at any PWD
sed -i /^Certific/s:\"\.:\"$srvdir/bin: bnetserver.conf
sed -i /^PrivateK/s:\"\.:\"$srvdir/bin: bnetserver.conf
else
cp authserver.conf.dist authserver.conf
# edit "LogsDir" value to "$srvdir/log" in authserver.conf(3.3.5 only), default "."
sed -i /^LogsDir/s:\".*\":\"$srvdir/log\": authserver.conf
fi
# edit "LogsDir" value to "$srvdir/log" in worldserver.conf, default "."
sed -i /^LogsDir/s:\".*\":\"$srvdir/log\": worldserver.conf
# edit "DataDir" value to "$srvdir/data" in worldserver.conf so server can be start at any PWD
sed -i /^DataDir/s:\".*\":\"$srvdir/data\": worldserver.conf
}
# import sql to create MySQL user & create tables & grant privilege
createsql (){
echo "Checking MySQL server status"
while ! systemctl status mariadb &> /dev/null
do
echo "MySQL server is not running, need root password to start it"
su -c "systemctl start mariadb"
done
echo "MySQL server is ready"
echo "Try to create trinity user in MySQL, MySQL root password is needed."
# once passwd wrong, no more chance?
mysql -u root -p < $repodir/sql/create/create_mysql.sql
}
# extract DBC & Maps
exmaps (){
echo "STARTING to extract Map and DBC."
if wowdir=$(dirname `locate Wow.exe` 2> /dev/null);then
cd $wowdir
$srvdir/bin/mapextractor
mkdir -p $srvdir/data
[ "$branum" == 6.x ] && (cp -r dbc maps gt $srvdir/data;) || cp -r dbc maps Cameras $srvdir/data
exvmap
exmmap
else
echo "Can't find wow directory"
[ "$branum" == 6.x ] && echo "You need to extract and place dbc/, maps/ and gt/ to where DataDir specified in $srvdir/etc/worldserver.conf by yourself." || echo "you need to extract and place dbc/ and maps/ to where DataDir specified in $srvdir/etc/worldserver.conf by yourself."
exit
fi
}
# extract VMaps & MMaps
exvmap (){
i= # unnecessary but safer. read will set var to null when time out
echo "STARTING to extract vmmaps in 5 sec."
read -p "START vmaps? [Y/n]" -t5 -n1 i
echo
if [ "$i" == n -o "$i" == N ];then
sed -i /^vmap/s/1/0/ $srvdir/etc/worldserver.conf
echo "\
!!! vmaps skipped !!!
Some corresponding changes have been made in $srvdir/etc/worldserver.conf to disable vmaps:
##########################################
vmap.enableLOS = 1 – set to 0
vmap.enableHeight = 1 – set to 0
vmap.petLOS = 1 – set to 0
vmap.enableIndoorCheck = 1 – set to 0
##########################################
If you change your mind and decide to extract and use vmaps later, make sure to change these values back to "1" to take advantage of them."
return
fi
cd $wowdir
$srvdir/bin/vmap4extractor
mkdir -p vmaps
$srvdir/bin/vmap4assembler Buildings vmaps
cp -r vmaps $srvdir/data
}
exmmap (){
echo "Extracting mmaps MAY TAKE UP TO HOURS."
echo "It's NOT necessary, SKIP in 10 seconds."
i= # unnecessary but safer. read will set var to null when time out
read -p "SKIP mmaps? [Y/n]" -t10 -n1 i
echo
[ "$i" != n -a "$i" != N ] && return
cd $wowdir
mkdir -p mmaps
$srvdir/bin/mmaps_generator
cp -r mmaps $srvdir/data
sed -i /^mmap/s/0/1/ $srvdir/etc/worldserver.conf
echo "\
!!! mmaps is ready! !!!
Corresponding change have been made in $srvdir/etc/worldserver.conf to enable mmaps:
##########################################
mmap.enablePathFinding = 0 – set to 1
##########################################
If you decide to disable mmaps later, just change this value back to "0"."
}
# place TDB_*.sql
tdb (){
# check if any TDB_full_* file in $srvdir/bin
echo "Checking TDB in $srvdir/bin."
cd $srvdir/bin
# if no TDB_* files in $srvdir/bin, try to fetch some from this script's dir then check again
# how to use text+regex instead of ls?
ls TDB_* &> /dev/null || mv $thisdir/TDB_* .
ls TDB_*.sql &> /dev/null && return
ls TDB_full_*/TDB_*.sql &> /dev/null && cp TDB_full_*/TDB_*.sql . && return
ls TDB_full_*.7z &> /dev/null && 7za x TDB_full_*.7z && cp TDB_full_*/TDB_*.sql . && return
echo "############### IMPORTANT !!! ###############"
echo "The required TDB_*.sql not found in $srvdir/bin"
echo "You need to download the corresponding TDB_full_*.7z file at https://github.com/TrinityCore/TrinityCore/releases, extract and place the TDB_*.sql file(s) at $srvdir/bin, then MUST go into $srvdir/bin use ./worldserver to import the world and hotfixes(6.x only) databases."
echo "############### IMPORTANT !!! ###############"
}
############### Main Part ###############
case $1 in
-s)
killall authserver
killall worldserver
exit 0
;;
--init)
chkrequi
requi
chbran
runcmake
runmake
setconf
createsql
exmaps
tdb
;;
-d | --debug)
chbran
runcmake
;;
-q)
[ -x $srvdir/bin/authserver ] && $srvdir/bin/authserver &
[ -x $srvdir/bin/bnetserver ] && $srvdir/bin/bnetserver &
$srvdir/bin/worldserver < /dev/null &> /dev/null &
exit 0
;;
-h)
readme
;;
-v)
version
;;
"")
[ -x $srvdir/bin/authserver ] && $srvdir/bin/authserver &
[ -x $srvdir/bin/bnetserver ] && $srvdir/bin/bnetserver &
$srvdir/bin/worldserver
;;
esac
