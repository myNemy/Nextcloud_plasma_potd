# Quando viene creata e aggiornata la lista delle immagini

## Creazione della lista

La lista viene creata **una sola volta** quando:

1. **Il provider viene istanziato** (costruttore `NextcloudProvider::NextcloudProvider`)
   - Questo avviene quando:
     - Plasma si avvia e il provider Nextcloud è selezionato
     - Cambi il provider da un altro a Nextcloud
     - Riavvii Plasma

2. **Nel costruttore viene chiamato:**
   - `loadConfig()` - carica la configurazione
   - `fetchImagesFromWebDAV()` o `fetchImagesFromLocal()` - crea la lista

## Aggiornamento della lista

La lista **NON viene aggiornata automaticamente**. Rimane in memoria finché:

- Il provider viene distrutto (quando cambi provider o riavvii Plasma)
- Viene chiamato manualmente `refresh()` quando la lista è vuota

## Comportamento attuale

```
Avvio Plasma / Selezioni Nextcloud
    ↓
Costruttore NextcloudProvider()
    ↓
loadConfig()
    ↓
fetchImagesFromWebDAV() o fetchImagesFromLocal()
    ↓
Crea lista m_imageUrls (TUTTE le immagini)
    ↓
Randomizza lista (std::shuffle)
    ↓
Seleziona prima immagine casuale
    ↓
Provider viene distrutto da potd dopo finished()
```

## Quando la lista viene ricaricata

La lista viene ricaricata **solo** se:

1. **Chiami `refresh()` e la lista è vuota:**
   ```cpp
   void NextcloudProvider::refresh() {
       if (m_imageUrls.isEmpty()) {
           // Ricarica da sorgente
           fetchImagesFromWebDAV() o fetchImagesFromLocal()
       } else {
           // Solo seleziona nuova immagine dalla lista esistente
           selectRandomImage();
       }
   }
   ```

2. **Il provider viene distrutto e ricreato:**
   - Cambi provider e torni a Nextcloud
   - Riavvii Plasma

## Implicazioni

- ✅ **Vantaggio**: La lista rimane in memoria, cambiare immagine è veloce (solo selezione casuale)
- ❌ **Svantaggio**: Se aggiungi nuove immagini su Nextcloud, non vengono viste finché non ricarichi

## Come ricaricare la lista

Per vedere nuove immagini aggiunte su Nextcloud, basta:

1. **Riavviare la sessione Plasma:**
   ```bash
   killall plasmashell && kstart plasmashell
   ```

2. **Cambiare provider e tornare a Nextcloud:**
   - Vai in Impostazioni → Sfondo → Immagine del giorno
   - Cambia provider (es. Bing)
   - Torna a Nextcloud

La lista verrà ricaricata automaticamente quando il provider viene ricreato.

