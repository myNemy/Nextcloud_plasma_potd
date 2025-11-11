# How to Remove the Nextcloud Provider

If the installation didn't work or you want to remove the provider, follow these steps:

## 1. Remove Installed Files

```bash
# Remove the .so plugin from /usr/lib (correct location)
sudo rm -f /usr/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so

# Remove the JSON file from /usr/lib (correct location)
sudo rm -f /usr/lib/qt6/plugins/potd/nextcloudprovider.json

# Remove the .so plugin from /usr/local/lib (if installed there by mistake)
sudo rm -f /usr/local/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so

# Remove the JSON file from /usr/local/lib (if installed there by mistake)
sudo rm -f /usr/local/lib/qt6/plugins/potd/nextcloudprovider.json

# Remove the JSON file installed in wrong location (/potd/)
sudo rm -f /potd/nextcloudprovider.json
sudo rmdir /potd 2>/dev/null || true
```

## 2. Remove Configuration (Optional)

```bash
# Remove the provider configuration file
rm -f ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

## 3. Restart Plasma

```bash
killall plasmashell && kstart plasmashell
```

## 4. Verify Removal

```bash
# Verify that files no longer exist
ls -la /usr/lib/qt6/plugins/potd/ | grep nextcloud
ls -la /potd/ 2>/dev/null || echo "OK: /potd/ does not exist"
```

## 5. Remove Build Files (Optional)

```bash
# If you want to clean up compilation files too
# Navigate to your project directory
cd /path/to/nextcloud-wallpaper
rm -rf build/
```
