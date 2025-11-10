# Come rimuovere il provider Nextcloud

Se l'installazione non ha funzionato o vuoi rimuovere il provider, segui questi passaggi:

## 1. Rimuovere i file installati

```bash
# Rimuovere il plugin .so da /usr/lib (posizione corretta)
sudo rm -f /usr/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so

# Rimuovere il file JSON da /usr/lib (posizione corretta)
sudo rm -f /usr/lib/qt6/plugins/potd/nextcloudprovider.json

# Rimuovere il plugin .so da /usr/local/lib (se installato lì per errore)
sudo rm -f /usr/local/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so

# Rimuovere il file JSON da /usr/local/lib (se installato lì per errore)
sudo rm -f /usr/local/lib/qt6/plugins/potd/nextcloudprovider.json

# Rimuovere il file JSON installato in posizione sbagliata (/potd/)
sudo rm -f /potd/nextcloudprovider.json
sudo rmdir /potd 2>/dev/null || true
```

## 2. Rimuovere la configurazione (opzionale)

```bash
# Rimuovere il file di configurazione del provider
rm -f ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

## 3. Riavviare Plasma

```bash
killall plasmashell && kstart plasmashell
```

## 4. Verificare che sia stato rimosso

```bash
# Verificare che i file non esistano più
ls -la /usr/lib/qt6/plugins/potd/ | grep nextcloud
ls -la /potd/ 2>/dev/null || echo "OK: /potd/ non esiste"
```

## 5. Rimuovere i file di build (opzionale)

```bash
# Se vuoi pulire anche i file di compilazione
cd /home/nemeyes/nextcloud-wallpaper
rm -rf build/
```

