#!/bin/sh --errexit

cd ~/TrinityCore/
git pull origin 3.3.5
sleep 10
cd /home/gabbario/server/bin/
sudo su -c "sleep 5" -s /bin/sh gabbario
sudo su -c "screen -d -m -S Authserver ./authserver" -s /bin/sh gabbario
sudo su -c "sleep 5" -s /bin/sh start.sh
sudo su -c "screen -d -m -S Worldserver ./worldserver" -s /bin/sh gabbario

exit 0
