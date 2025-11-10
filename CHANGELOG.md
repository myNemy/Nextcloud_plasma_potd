# Changelog

## [1.0.0] - 2024

### Aggiunto
- Provider Nextcloud per KDE Plasma Picture of the Day
- Supporto WebDAV per connessione diretta a Nextcloud
- Supporto percorso locale per cartelle sincronizzate
- Autenticazione con App Password
- Selezione casuale di immagini
- Ricerca ricorsiva in tutte le sottocartelle
- Opzione MaxImages per limitare il numero di immagini caricate
- Identifier unico per immagine per bypassare la cache di potd

### Note
- La rotazione automatica non è disponibile perché potd distrugge il provider dopo `finished()`
- Per cambiare immagine, riavviare Plasma o cambiare provider
- Ogni volta che il provider viene ricreato, seleziona una nuova immagine casuale

