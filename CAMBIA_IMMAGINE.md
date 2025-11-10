# Come cambiare l'immagine del provider Nextcloud

Dopo che il provider ha caricato la prima immagine, ci sono diversi modi per cambiarne una:

## Metodo 1: Riavviare Plasma (più semplice)

```bash
killall plasmashell && kstart plasmashell
```

Questo forza il provider a ricaricare e selezionare una nuova immagine casuale.

## Metodo 2: Cambiare provider e tornare a Nextcloud

1. Vai in **Impostazioni → Aspetto → Sfondo**
2. Seleziona "Picture of the Day"
3. Cambia il provider (es. seleziona "Bing")
4. Aspetta che carichi
5. Torna a selezionare "Nextcloud"

Questo forza un nuovo caricamento.

## Metodo 3: Script per cambiare rapidamente

Crea uno script `~/bin/nextcloud-wallpaper-refresh.sh`:

```bash
#!/bin/bash
# Forza il cambio dell'immagine Nextcloud

# Metodo 1: Riavvia solo plasmashell (più veloce)
killall plasmashell && kstart plasmashell

# Oppure metodo 2: Toccando il file di configurazione (se supportato)
# touch ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

Rendilo eseguibile:
```bash
chmod +x ~/bin/nextcloud-wallpaper-refresh.sh
```

Poi puoi chiamarlo quando vuoi cambiare immagine.

## ⚠️ Rotazione automatica NON disponibile

**IMPORTANTE**: La rotazione automatica tramite timer NON è possibile perché potd distrugge il provider dopo aver caricato l'immagine. Il timer verrebbe distrutto prima di poter scattare.

Per cambiare immagine, devi usare i metodi manuali sopra (riavviare Plasma o cambiare provider).

## Nota tecnica

Il provider ha un metodo `refresh()` che può selezionare una nuova immagine casuale dalla lista già caricata, ma per usarlo serve modificare il backend di potd per esporre questa funzionalità nell'interfaccia QML.

## Suggerimento

Se cambi spesso immagine, il metodo più veloce è creare un alias nel tuo `.bashrc`:

```bash
alias nextcloud-refresh="killall plasmashell && kstart plasmashell"
```

Poi puoi semplicemente eseguire `nextcloud-refresh` nel terminale.

