# How to Change the Nextcloud Provider Image

After the provider has loaded the first image, there are several ways to change it:

## Method 1: Restart Plasma (Simplest)

```bash
killall plasmashell && kstart plasmashell
```

This forces the provider to reload and select a new random image.

## Method 2: Change Provider and Return to Nextcloud

1. Go to **Settings → Appearance → Background**
2. Select "Picture of the Day"
3. Change the provider (e.g. select "Bing")
4. Wait for it to load
5. Return to selecting "Nextcloud"

This forces a new load.

## Method 3: Script for Quick Change

Create a script `~/bin/nextcloud-wallpaper-refresh.sh`:

```bash
#!/bin/bash
# Force Nextcloud image change

# Method 1: Restart only plasmashell (faster)
killall plasmashell && kstart plasmashell

# Or method 2: Touching the configuration file (if supported)
# touch ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

Make it executable:
```bash
chmod +x ~/bin/nextcloud-wallpaper-refresh.sh
```

Then you can call it when you want to change the image.

## ⚠️ Automatic Rotation NOT Available

**IMPORTANT**: Automatic rotation via timer is NOT possible because potd destroys the provider after loading the image. The timer would be destroyed before it can fire.

To change the image, you must use the manual methods above (restart Plasma or change provider).

## Technical Note

The provider follows the standard PotdProvider API. To change the image, the provider must be recreated by restarting Plasma or changing providers.

## Tip

If you change images often, the fastest method is to create an alias in your `.bashrc`:

```bash
alias nextcloud-refresh="killall plasmashell && kstart plasmashell"
```

Then you can simply run `nextcloud-refresh` in the terminal.
