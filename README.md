# Nextcloud Provider per KDE Plasma Picture of the Day

Provider per il plugin "Picture of the Day" di KDE Plasma che permette di utilizzare immagini da Nextcloud.

## Caratteristiche

- ✅ **Supporto WebDAV**: Connessione diretta a Nextcloud via WebDAV
- ✅ **Percorso Locale**: Supporto per cartelle sincronizzate localmente
- ✅ **Autenticazione App Password**: Supporto per App Password di Nextcloud
- ✅ **Selezione Casuale**: Seleziona immagini casualmente dalla cartella
- ✅ **Ricerca Ricorsiva**: Cerca immagini in tutte le sottocartelle
- ✅ **Limite Immagini**: Opzione per limitare il numero di immagini caricate
- ⚠️ **Rotazione Automatica**: Non disponibile (vedi [CAMBIA_IMMAGINE.md](CAMBIA_IMMAGINE.md))

## Integrazione in kdeplasma-addons

Per integrare questo provider nel repository kdeplasma-addons:

1. Copia i file nella struttura corretta:
   ```bash
   cp plugins/providers/* /path/to/kdeplasma-addons/wallpapers/potd/plugins/providers/
   ```

2. Aggiungi al `CMakeLists.txt`:
   ```cmake
   kcoreaddons_add_plugin(plasma_potd_nextcloudprovider SOURCES nextcloudprovider.cpp INSTALL_NAMESPACE "potd")
   target_link_libraries(plasma_potd_nextcloudprovider plasmapotdprovidercore plasma_wallpaper_potdplugin_debug KF6::KIOCore KF6::CoreAddons Qt6::Network)
   ```

3. Modifica `package/contents/ui/config.qml` per aggiungere i campi di configurazione quando `cfg_Provider === "nextcloud"`:

   Aggiungi dopo il selettore Provider (circa riga 124):
   ```qml
   // Nextcloud Configuration (visible only when Nextcloud provider is selected)
   Kirigami.Separator {
       Layout.fillWidth: true
       Layout.topMargin: Kirigami.Units.smallSpacing
       Layout.bottomMargin: Kirigami.Units.smallSpacing
       visible: cfg_Provider === "nextcloud"
   }

   QtControls2.CheckBox {
       id: useLocalPathCheck
       visible: cfg_Provider === "nextcloud"
       Kirigami.FormData.label: i18n("Mode:")
       text: i18n("Use local synchronized folder")
       checked: nextcloudConfig.useLocalPath
       onToggled: nextcloudConfig.useLocalPath = checked
   }

   QtControls2.TextField {
       id: localPathField
       visible: cfg_Provider === "nextcloud" && useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Local Path:")
       text: nextcloudConfig.localPath
       onTextChanged: nextcloudConfig.localPath = text
   }

   QtControls2.TextField {
       id: nextcloudUrlField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Nextcloud URL:")
       text: nextcloudConfig.nextcloudUrl
       onTextChanged: nextcloudConfig.nextcloudUrl = text
   }

   QtControls2.TextField {
       id: nextcloudPathField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("WebDAV Path:")
       text: nextcloudConfig.nextcloudPath
       onTextChanged: nextcloudConfig.nextcloudPath = text
   }

   QtControls2.TextField {
       id: usernameField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Username:")
       text: nextcloudConfig.username
       onTextChanged: nextcloudConfig.username = text
   }

   QtControls2.TextField {
       id: passwordField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Password or App Password:")
       echoMode: TextInput.Password
       text: nextcloudConfig.password
       onTextChanged: nextcloudConfig.password = text
   }
   ```

   E aggiungi un componente per gestire la configurazione (prima di `Kirigami.FormLayout`):
   ```qml
   // Nextcloud Configuration Manager
   QtObject {
       id: nextcloudConfig
       property bool useLocalPath: false
       property string localPath: ""
       property string nextcloudUrl: ""
       property string nextcloudPath: ""
       property string username: ""
       property string password: ""

       function saveConfig() {
           const configPath = Qt.resolvedUrl("file://" + StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/plasma_engine_potd/nextcloudprovider.conf");
           // Salva configurazione usando KConfig o altro metodo
       }

       function loadConfig() {
           // Carica configurazione
       }

       Component.onCompleted: loadConfig()
   }
   ```

## Configurazione

Il provider legge la configurazione da:
`~/.config/plasma_engine_potd/nextcloudprovider.conf`

Formato:
```ini
[Nextcloud]
Url=https://nextcloud.example.com
Path=/remote.php/dav/files/USERNAME/Immagini
Username=username
Password=app_password_here
UseLocalPath=false
LocalPath=/home/user/Nextcloud/Immagini
MaxImages=0  # Numero massimo di immagini da caricare (0 = illimitato)
```

Vedi [CONFIGURAZIONE.md](CONFIGURAZIONE.md) per dettagli completi.

## Compilazione

```bash
cd /path/to/kdeplasma-addons
mkdir build && cd build
cmake ..
make
sudo make install
```

## Uso

1. Vai in Impostazioni → Aspetto → Sfondo
2. Seleziona "Picture of the Day"
3. Nel menu "Provider" seleziona "Nextcloud"
4. Configura il provider (vedi [CONFIGURAZIONE.md](CONFIGURAZIONE.md))
5. Riavvia Plasma: `killall plasmashell && kstart plasmashell`

## Documentazione

- [CONFIGURAZIONE.md](CONFIGURAZIONE.md) - Come configurare il provider
- [CAMBIA_IMMAGINE.md](CAMBIA_IMMAGINE.md) - Come cambiare l'immagine
- [QUANDO_AGGIORNA_LISTA.md](QUANDO_AGGIORNA_LISTA.md) - Quando viene creata/aggiornata la lista
- [UNINSTALL.md](UNINSTALL.md) - Come rimuovere il provider

