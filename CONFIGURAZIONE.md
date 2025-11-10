# Come configurare il Provider Nextcloud

Il provider Nextcloud è apparso nella lista! Ora devi configurarlo.

## Metodo 1: Script interattivo (consigliato)

```bash
# Esegui lo script di configurazione
bash /tmp/setup_nextcloud_config.sh
```

Lo script ti chiederà:
- URL Nextcloud (es. `https://nextcloud.example.com`)
- Percorso WebDAV (es. `/remote.php/dav/files/USERNAME/Immagini`)
- Username
- Password o App Password
- Se vuoi usare un percorso locale sincronizzato

## Metodo 2: Configurazione manuale

Crea il file `~/.config/plasma_engine_potd/nextcloudprovider.conf`:

```bash
mkdir -p ~/.config/plasma_engine_potd
nano ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

Incolla questo contenuto e modifica i valori:

```ini
[Nextcloud]
Url=https://nextcloud.example.com
Path=/remote.php/dav/files/USERNAME/Immagini
Username=tuo_username
Password=tua_app_password
UseLocalPath=false
LocalPath=
MaxImages=0  # Numero massimo di immagini da caricare (0 = illimitato)
```

### Per usare percorso locale sincronizzato:

```ini
[Nextcloud]
Url=
Path=
Username=
Password=
UseLocalPath=true
LocalPath=/home/user/Nextcloud/Immagini
```

## Dettagli configurazione

### URL Nextcloud
L'URL completo del tuo server Nextcloud, es.:
- `https://nextcloud.example.com`
- `https://cloud.miodominio.it`

### Percorso WebDAV
Il percorso WebDAV della cartella contenente le immagini. Formato:
```
/remote.php/dav/files/USERNAME/NomeCartella
```

Esempi:
- `/remote.php/dav/files/mario/Immagini`
- `/remote.php/dav/files/mario/Wallpapers`

### Username
Il tuo username Nextcloud.

### Password o App Password
**Consigliato: usa un'App Password invece della password principale!**

Per generare un'App Password:
1. Vai su Nextcloud → Impostazioni → Sicurezza
2. Scorri fino a "App Password"
3. Genera una nuova App Password
4. Usa quella password qui

### UseLocalPath
- `false` = usa WebDAV (connessione diretta)
- `true` = usa cartella locale sincronizzata

### LocalPath
Se `UseLocalPath=true`, specifica il percorso locale della cartella sincronizzata, es.:
- `/home/user/Nextcloud/Immagini`
- `/home/user/Documents/Nextcloud/Wallpapers`

### MaxImages
Numero massimo di immagini da caricare dalla cartella:
- `0` = illimitato (carica tutte le immagini trovate)
- `100` = carica massimo 100 immagini
- `1000` = carica massimo 1000 immagini

**Nota**: Il limite viene applicato durante la scansione, quindi se imposti `MaxImages=100`, caricherà le prime 100 immagini trovate (non le migliori 100).

## Dopo la configurazione

1. **Riavvia Plasma:**
   ```bash
   killall plasmashell && kstart plasmashell
   ```

2. **Vai in Impostazioni → Aspetto → Sfondo**

3. **Seleziona "Picture of the Day"**

4. **Nel menu "Provider" seleziona "Nextcloud"**

5. Il provider dovrebbe caricare un'immagine dalla tua cartella Nextcloud!

## Verifica configurazione

Per verificare che la configurazione sia corretta:

```bash
cat ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

## Risoluzione problemi

### Il provider non carica immagini

1. Verifica che il file di configurazione esista:
   ```bash
   ls -la ~/.config/plasma_engine_potd/nextcloudprovider.conf
   ```

2. Controlla i log di Plasma:
   ```bash
   journalctl --user -f | grep -i nextcloud
   ```

3. Verifica che:
   - L'URL sia corretto e raggiungibile
   - Il percorso WebDAV sia corretto
   - Username e password siano corretti
   - La cartella contenga file immagine (jpg, png, etc.)

### Errore di autenticazione

- Assicurati di usare un'App Password, non la password principale
- Verifica che username e password siano corretti
- Controlla che l'URL non abbia uno slash finale

### Nessuna immagine trovata

- Verifica che la cartella contenga file immagine
- Controlla i permessi della cartella su Nextcloud
- Assicurati che il percorso WebDAV sia corretto

