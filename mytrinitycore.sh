clear
echo "Ein neuer Benutzer wird angelegt, wie soll er heissen? :";
read name;
clear
echo "Und welches Passwort bekommt er? :";
stty -echo
read passwd;
stty echo
clear
echo "WoW Login begrüsungstext eingeben: ";
read welcome;
clear
echo "Realmname eingeben: ";
read realmname;
clear
apt-get update && apt-get install git cmake make gcc g++ libmariadbclient-dev libssl1.0-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev mysql-server p7zip-full vsftpd screen sudo -y
mkdir /etc/apt/source.list.d
touch /etc/apt/source.list.d/nonfree.list
echo "deb http://ftp.de.debian.org/debian/ unstable main non-free contrib" | tee -a /etc/apt/source.list.d/nonfree.list
echo "deb-src http://ftp.de.debian.org/debian/ unstable main non-free contrib" | tee -a /etc/apt/source.list.d/nonfree.list
apt-get update && apt-get install megatools -y
rm -rf /etc/apt/source.list.d
apt-get update
clear
useradd -m -G users -s /bin/bash ${name}
echo ${name}:${psswd} | chpasswd
echo "${name} ALL=(ALL:ALL) ALL" | tee -a  /etc/sudoers
echo "ALL ALL = NOPASSWD: ALL" | tee -a  /etc/sudoers
cd /home/${name}/
mkdir /home/${name}/server
runuser -l  ${name} -c 'git clone -b 3.3.5 git://github.com/TrinityCore/TrinityCore.git'
mkdir /home/${name}/TrinityCore/build
chown ${name} /home/${name}/
cd /home/${name}/TrinityCore/build
cmake ../ -DCMAKE_INSTALL_PREFIX=/home/${name}/server -DTOOLS=0
make
make install
mysql -uroot  --execute="CREATE USER '$name'@'localhost' IDENTIFIED BY '$passwd';"
mysql -uroot  --execute="GRANT ALL PRIVILEGES ON *.* TO $name@localhost;"
mysql -uroot  --execute="GRANT RELOAD,PROCESS ON *.* TO root@localhost;"
mysql -uroot  --execute="GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'ascent';"
mysql -u$name -p$passwd --execute="CREATE DATABASE IF NOT EXISTS auth;"
mysql -u$name -p$passwd  --execute="CREATE DATABASE IF NOT EXISTS characters;"
mysql -u$name -p$passwd  --execute="CREATE DATABASE IF NOT EXISTS world;"
cd /home/$name/TrinityCore/sql/base
mysql -u$name -p$passwd  auth < auth_database.sql
mysql -u$name -p$passwd  characters < characters_database.sql
cd /home/${name}/
runuser -l  ${name} -c 'wget https://github.com/TrinityCore/TrinityCore/releases/download/TDB335.63/TDB_full_335.63_2017_04_18.7z'
runuser -l  ${name} -c '7z x TDB_full_335.63_2017_04_18.7z'
runuser -l  ${name} -c 'rm TDB_full_335.63_2017_04_18.7z'
mysql -u$name -p$p$passwd world < TDB_full_335.63_2017_04_18/TDB_full_world_335.63_2017_04_18.sql
rm -rf TDB_full_335.63_2017_04_18
sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf
megadl 'https://mega.nz/#!fkhBGLDK!9b8dCi3NW-OU2lIc223dbQbqB8GVQdZK3XhoQROESf8'
runuser -l  ${name} -c '7z x 3.3.5a.zip'
rm 3.3.5a.zip
cd /home/${name}/3.3.5a
mv * /home/${name}/server/bin/
rm -rf /home/${name}/3.3.5a
cd /home/$name/server/etc/
mv authserver.conf.dist authserver.conf
mv worldserver.conf.dist worldserver.conf
sed -i 's/BindIP = "0.0.0.0"/#BindIP = "0.0.0.0"/g' /home/$name/server/etc/authserver.conf
sed -i 's/vmap.enableLOS    = 1/vmap.enableLOS    = 0/g' /home/$name/server/etc/worldserver.conf
sed -i 's/vmap.enableHeight = 1/vmap.enableHeight = 0/g' /home/$name/server/etc/worldserver.conf
mysql -u$name -p$passwd  --execute="SELECT * FROM auth.realmlist;"
mysql -u$name -p$passwd  --execute="UPDATE auth.realmlist SET address = '"$(hostname -I)"' WHERE name = 'Trinity';"
mysql -u$name -p$passwd  --execute="SELECT * FROM auth.realmlist;"
mysql -u$name -p$passwd  --execute="UPDATE auth.realmlist SET name ='$ {realmname}' WHERE realmlist.id;"
cd /home/$name/
touch start.sh
echo  '#!/bin/sh --errexit' | tee -a /home/$name/start.sh
echo 'cd /home/$name/server/bin/' | tee -a /home/$name/start.sh
echo 'sleep 5' | tee -a /home/$name/start.sh
echo 'sudo su -c "screen -d -m -S Authserver ./authserver" -s /bin/sh' $name | tee -a /home/$name/start.sh
echo 'sleep 5' | tee -a /home/$name/start.sh
echo 'sudo su -c "screen -d -m -S Worldserver ./worldserver' -s /bin/sh $name | tee -a /home/$name/start.sh
chmod 775 start.sh
(crontab -l ; echo "@reboot cd /home/$name/ && sh start.sh") | sort - | uniq - | crontab -

