cd ~/
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
apt-get -y upgrade
apt-get -q -y install git cmake make gcc g++ libmysqlclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev mysql-server p7zip zip nano
mysqladmin -u root password $ROOTPASS
wget http://dev.mysql.com/get/mysql-apt-config_0.7.3-1_all.deb
debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-server select mysql-5.7'
dpkg -i mysql-apt-config_0.7.3-1_all.deb
apt-get -y update
apt-get -y install mysql-community-server
mysql_upgrade -u root -p$ROOTPASS --force
cd /etc/mysql/mysql.conf.d
rm mysqld.cnf
wget http://www.mediafire.com/file/zse3gl8bm3wrgbl/mysqld.cnf
cd ~/
service mysql restart
myhost=$(hostname)
mysql -u root -p$ROOTPASS -D mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOTPASS';"
mysql -u root -p$ROOTPASS -D mysql -e "ALTER USER 'root'@'127.0.0.1' IDENTIFIED BY '$ROOTPASS';"
mysql -u root -p$ROOTPASS -D mysql -e "ALTER USER 'root'@'::1' IDENTIFIED BY '$ROOTPASS';"
mysql -u root -p$ROOTPASS -D mysql -e "ALTER USER 'root'@'$myhost' IDENTIFIED BY '$ROOTPASS';"
mysql -u root -p$ROOTPASS -e "FLUSH PRIVILEGES;"
mysql -u root -p$ROOTPASS -e "GRANT USAGE ON * . * TO '$TCSQLUSER'@'%' IDENTIFIED BY '$TCSQLPASS' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
mysql -u root -p$ROOTPASS -e "GRANT ALL PRIVILEGES ON *.* TO '$TCSQLUSER'@'%' WITH GRANT OPTION;"
mysql -u root -p$ROOTPASS -e "GRANT USAGE ON *.* TO 'trinity'@'localhost' IDENTIFIED BY 'trinity' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;"
mysql -u root -p$ROOTPASS -e "CREATE DATABASE world DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p$ROOTPASS -e "CREATE DATABASE characters DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p$ROOTPASS -e "CREATE DATABASE auth DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p$ROOTPASS -e "GRANT ALL PRIVILEGES ON world.* TO 'trinity'@'localhost' WITH GRANT OPTION;"
mysql -u root -p$ROOTPASS -e "GRANT ALL PRIVILEGES ON characters.* TO 'trinity'@'localhost' WITH GRANT OPTION;"
mysql -u root -p$ROOTPASS -e "GRANT ALL PRIVILEGES ON auth.* TO 'trinity'@'localhost' WITH GRANT OPTION;"
mysql -u root -p$ROOTPASS -e "FLUSH PRIVILEGES;"
git clone -b 3.3.5 git://github.com/TrinityCore/TrinityCore.git
cd TrinityCore
mkdir build
cd build
CPU=$(grep -c ^processor /proc/cpuinfo)
cmake ../ -DCMAKE_INSTALL_PREFIX=/home/$USER/server -DTOOLS=1 -DWITH_WARNINGS=1 && make -j $CPU && make install
cd /home/root/server
mkdir logs
mkdir data
cd etc
wget http://www.mediafire.com/file/cl6r6rrb31985r6/authserver.conf
wget http://www.mediafire.com/file/qaddsi9im9b1dmv/worldserver.conf
cd /home/root/server/bin
wget https://github.com/TrinityCore/TrinityCore/releases/download/TDB335.62/TDB_full_335.62_2016_10_17.7z
p7zip -d TDB_full_335.62_2016_10_17.7z
cp TDB_full_335.62_2016_10_17/TDB_full_world_335.62_2016_10_17.sql ./
wget http://www.mediafire.com/file/z4157ov94pczv31/world_start.sh
wget http://www.mediafire.com/file/erdayvkmnc2dw93/auth_start.sh
wget http://www.mediafire.com/file/az98x25czxcsi6z/world_restarter.sh
wget http://www.mediafire.com/file/zl0qslx7ch5tkq0/auth_restarter.sh
chmod +x  world_restarter.sh
chmod +x  auth_restarter.sh
chmod +x  world_start.sh
chmod +x  auth_start.sh
./worldserver
realm=$(hostname)
ip=$(hostname  -i | cut -f1 -d' ')
mysql -u root -p$ROOTPASS -D auth -e "UPDATE realmlist SET name= '$realm', address='$ip' WHERE id=1;"
wget http://www.mediafire.com/file/5l7bcfni4lwlwi2/firewall.sh
chmod +x firewall.sh
./firewall.sh
cd /home/root/server/data
wget http://www.mediafire.com/file/0hvyy64vrt4zdym/dbc.7z
wget http://www.mediafire.com/file/84jp4vcagme0aoo/maps.7z
wget http://www.mediafire.com/file/hv1lnin7b1qa6ci/vmaps.7z
wget http://www.mediafire.com/file/g3bc4mwkmhhztvm/mmaps.7z
p7zip -d dbc.7z
p7zip -d maps.7z
p7zip -d vmaps.7z
p7zip -d mmaps.7z
crontab -l | { cat; echo "@reboot /home/root/server/bin/auth_start.sh"; } | crontab -
crontab -l | { cat; echo "@reboot /home/root/server/bin/world_start.sh"; } | crontab -
crontab -l | { cat; echo "@reboot /usr/local/bin/runonce.sh"; } | crontab -
mkdir -p /etc/local/runonce.d/ran
cd /usr/local/bin
wget http://www.mediafire.com/file/l3om6m1ue87m49s/runonce.sh
chmod +x runonce.sh
/home/root/server/bin/auth_start.sh
/home/root/server/bin/world_start.sh
END=$(date +%s);
TIME=$((END-START))
export DEBIAN_FRONTEND=newt
show_time $TIME
