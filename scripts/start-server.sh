#!/bin/bash
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    echo "SteamCMD not found!"
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
if [ "${USERNAME}" == "" ]; then
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login anonymous \
    +quit
else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${USERNAME} ${PASSWRD} \
    +quit
fi

echo "---Update Server---"
if [ "${USERNAME}" == "" ]; then
    if [ "${VALIDATE}" == "true" ]; then
    	echo "---Validating installation---"
        ${STEAMCMD_DIR}/steamcmd.sh \
        +login anonymous \
        +force_install_dir ${SERVER_DIR} \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +login anonymous \
        +force_install_dir ${SERVER_DIR} \
        +app_update ${GAME_ID} \
        +quit
    fi
else
    if [ "${VALIDATE}" == "true" ]; then
    	echo "---Validating installation---"
        ${STEAMCMD_DIR}/steamcmd.sh \
        +login ${USERNAME} ${PASSWRD} \
        +force_install_dir ${SERVER_DIR} \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +login ${USERNAME} ${PASSWRD} \
        +force_install_dir ${SERVER_DIR} \
        +app_update ${GAME_ID} \
        +quit
    fi
fi

if [ "${OXIDE_MOD}" == "true" ]; then
  echo "---Oxide Mod enabled!---"
  CUR_V="$(find ${SERVER_DIR} -maxdepth 1 -name rustinstalledv* | cut -d 'v' -f4-)"
  LAT_V="$(wget -qO- https://api.github.com/repos/OxideMod/Oxide.Rust/releases/latest | grep tag_name | cut -d '"' -f4)"

  if [ -z ${LAT_V} ]; then
    if [ -z ${CUR_V} ]; then
      echo "---Can't get latest Oxide Mod version and found no installed version, putting server into sleep mode!---"
      sleep infinity
    else
      echo "---Can_t get latest Oxide Mod version, falling back to installed v${CUR_V}!---"
      LAT_V="${CUR_V}"
    fi
  fi

  if [ -z "$CUR_V" ]; then
    echo "---Oxide Mod not found, downloading!---"
    cd ${SERVER_DIR}
    if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/OxideMod.zip "https://github.com/OxideMod/Oxide.Rust/releases/download/${LAT_V}/Oxide.Rust-linux.zip" ; then
        echo "---Successfully downloaded Oxide Mode v${LAT_V}!---"
    else
        echo "---Something went wrong, can't download Oxide Mod v${LAT_V}, putting server in sleep mode---"
        sleep infinity
    fi
    unzip -o ${SERVER_DIR}/OxideMod.zip -d ${SERVER_DIR}
    touch ${SERVER_DIR}/rustinstalledv${LAT_V}
    rm -rf ${SERVER_DIR}/OxideMod.zip
  elif [ "$LAT_V" != "$CUR_V" ]; then
    cd ${SERVER_DIR}
    rm -rf ${SERVER_DIR}/rustinstalledv*
    echo "---Newer version of Oxide Mod v${LAT_V} found, currently installed: v${CUR_V}---"
    rm ${SERVER_DIR}/${JAR_NAME}.jar
    if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/OxideMod.zip "https://github.com/OxideMod/Oxide.Rust/releases/download/${LAT_V}/Oxide.Rust-linux.zip" ; then
        echo "---Successfully downloaded Oxide Mod v${LAT_V}!---"
    else
        echo "---Something went wrong, can't download Oxide Mod v${LAT_V}, putting server in sleep mode---"
        sleep infinity
    fi
    unzip -o ${SERVER_DIR}/OxideMod.zip -d ${SERVER_DIR}
    touch ${SERVER_DIR}/rustinstalledv${LAT_V}
    rm -rf ${SERVER_DIR}/OxideMod.zip
  elif [ "$LAT_V" == "$CUR_V" ]; then
    echo "---Oxide Mod v${CUR_V} is Up-To-Date!---"
  fi
fi

echo "---Prepare Server---"
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Setting Library path---"
export LD_LIBRARY_PATH=:/bin/RustDedicated_Data/Plugins/x86_64
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}
${SERVER_DIR}/RustDedicated -batchmode +server.port ${GAME_PORT} +server.hostname "${SERVER_NAME}" +server.description "${SERVER_DISCRIPTION}" ${GAME_PARAMS}