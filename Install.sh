#!/bin/bash

# 1. Pulisci tutto (anche da /usr/local)
sudo rm -f /usr/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so
sudo rm -f /usr/lib/qt6/plugins/potd/nextcloudprovider.json
sudo rm -f /usr/local/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so
sudo rm -f /usr/local/lib/qt6/plugins/potd/nextcloudprovider.json

# 2. Ricompila e installa
cd build
rm -rf *
cmake ..
make -j$(nproc)
sudo make install

# 3. Verifica che sia in /usr/lib (non /usr/local)
ls -la /usr/lib/qt6/plugins/potd/ | grep nextcloud

# 4. Riavvia Plasma
killall plasmashell && kstart plasmashell