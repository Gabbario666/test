#!/bin/bashclear
date=$(date +%m.%d.%Y.%H.%M.%S)
getroot(){
if [ "${EUID}" -ne 0 ]; then
    echo "Script neds to be run as root (sudo ./update.sh)"
else
    dependencies
fi
}
update(){
clear
echo "This will install ${version} server emulator"
echo ""
echo "Source"
echo "${source}"
echo "Database"
echo "${database}"
echo ""
read -p "Press [enter] to continue" read
echo ""
if [ -d "${installpath}" ]; then
    echo "This will move the current folder /opt/${game} to /opt/${game}.bak"
    echo ""
    read -p "Press [enter] to continue"
    sudo mv "${installpath}" "${installpath}.bak"
fi
sudo mkdir "${installpath}"
sudo mkdir "${installpath}/sql"
sudo mkdir "${installpath}/source"
sudo git clone --recursive "${source}" "${sourcepath}"
sudo mkdir "${sourcepath}/build"
cd "${sourcepath}/build"
cmake -DBUILD_EXTRACTORS=1 -DTOOLS=1 -DCMAKE_INSTALL_PREFIX="${installpath}" "${sourcepath}"
sudo make -j4
sudo make install
if [ "${game}" = "wow" ]; then
    sudo git clone --recursive "${database}" "${installpath}/sql/${dbname}"
    echo "${dbname} database created on ${date}" > "${installpath}/sql/${dbname}.log"
elif [ "${game}" = "tbc" ]; then
    sudo git clone --recursive "${database}" "${installpath}/sql/${dbname}"
    echo "${dbname} database created on ${date}" > "${installpath}/sql/${dbname}.log"
elif [ "${game}" = "wotlk" ]; then
    cd "${sourcepath}/bin/db_assembler"
    echo 1 | sudo ./db_assembler.sh
    sudo mv output "${installpath}/sql/${dbname}"
    echo "${dbname} database created on ${date}" > "${installpath}/sql/${dbname}.log"
elif [ "${game}" = "cata" ]; then
    echo ""
    echo "Please visit the website below to download the latest database."
    echo "${database}"
    echo ""
elif [ "${game}" = "mop" ]; then
    echo ""
    echo "Please visit the website below to download the latest database."
    echo "${database}"
    echo ""
elif [ "${game}" = "wod" ]; then
    echo ""
elif [ "${game}" = "legion" ]; then
    echo ""
    echo "Please visit the website below to download the latest database."
    echo "${database}"
    echo ""
fi
}
start(){
clear
echo "Which server would you like to install?"
echo ""
echo "1) World of Warcraft (Drums of War) 1.12.1 [5875]"
echo "2) The Burning Crusade (Fury of the Sunwell) 2.4.3 [8606]"
echo "3) Wrath of the Lich King (Fall of the Lich King) 3.3.5a [12340]"
echo "4) Cataclysm (Hour of Twilight) 4.3.4 [15595]"
echo "5) Mists of Pandaria (Siege of Orgrimmar) 5.4.8 [18414]"
echo "6) Warlords of Dreanor (Fury of Hellfire) 6.2.4a [21676] (No Servers Available)"
echo "7) Legion (Tomb of Sargeras) 7.2.0 [24015]"
echo ""
read -p "Choose [1-7] " read
if [ "${read}" = "1" ]; then
    game="wow"
    server="cmangos"
    version="World of Warcraft (Drums of War) 1.12.1 [5875]"
    source="https://github.com/cmangos/mangos-classic"
    database="https://github.com/cmangos/classic-db"
    dbname="classic-db"
elif [ "${read}" = "2" ]; then
    game="tbc"
    server="cmangos"
    version="The Burning Crusade (Fury of the Sunwell) 2.4.3 [8606]"
    source="https://github.com/cmangos/mangos-tbc"
    database="https://github.com/cmangos/tbc-db"
    dbname="tbc-db"
elif [ "${read}" = "3" ]; then
    game="wotlk"
    server="azeroth"
    version="Wrath of the Lich King (Fall of the Lich King) 3.3.5a [12340]"
    source="https://github.com/azerothcore/azerothcore-wotlk"
    database="Available inside source"
    dbname="wotlk-db"
elif [ "${read}" = "4" ]; then
    game="cata"
    server="trinity"
    version="Cataclysm (Hour of Twilight) 4.3.4 [15595]"
    source="https://gitlab.com/trinitycore/TrinityCore_434"
    database="https://github.com/TrinityCoreLegacy/TrinityCore/releases"
elif [ "${read}" = "5" ]; then
    game="mop"
    server="skyfire"
    version="Mists of Pandaria (Siege of Orgrimmar) 5.4.8 [18414]"
    source="https://github.com/ProjectSkyfire/SkyFire.548"
    database="https://www.projectskyfire.org/index.php?/files/"
    dbname="SkyFireDB"
elif [ "${read}" = "6" ]; then
    game="wod"
    server=""
    version="Warlords of Dreanor (Fury of Hellfire) 6.2.4a [21676]"
    source=""
    database=""
    dbname=""
    start
elif [ "${read}" = "7" ]; then
    game="legion"
    server="trinity"
    version="Legion (Tomb of Sargeras) 7.2.0 [24015]"
    source="https://github.com/TrinityCore/TrinityCore"
    database="https://github.com/TrinityCore/TrinityCore/releases"
else
    start
fi
installpath="/opt/${game}"
sourcepath="${installpath}/source/${server}"
update
}
dependencies(){
    echo "Installing dependencies"
    echo ""
    sudo apt-get -y install build-essential autoconf libtool gcc g++ make cmake subversion git patch wget links zip unzip openssl libssl-dev mysql-server mysql-client libmysqlclient-dev libmysql++-dev lib64readline6-dev zlib1g-dev libbz2-dev git-core libace-dev openssl libssl-dev ace automake git-core libtool grep binutils zlibc libc6 libboost-all-dev clang libreadline-dev libncurses-dev libace-6.* p7zip-full
    clear
    start
}
getroot
