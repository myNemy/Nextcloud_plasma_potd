# How to Configure the Nextcloud Provider

The Nextcloud provider has appeared in the list! Now you need to configure it.

## Manual Configuration

Create the file `~/.config/plasma_engine_potd/nextcloudprovider.conf`:

```bash
mkdir -p ~/.config/plasma_engine_potd
nano ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

Paste this content and modify the values:

```ini
[Nextcloud]
Url=https://nextcloud.example.com
Path=/remote.php/dav/files/USERNAME/Images
Username=your_username
Password=your_app_password
UseLocalPath=false
LocalPath=
MaxImages=0  # Maximum number of images to load (0 = unlimited)
```

### To use locally synchronized path:

```ini
[Nextcloud]
Url=
Path=
Username=
Password=
UseLocalPath=true
LocalPath=/home/user/Nextcloud/Images
```

## Configuration Details

### Nextcloud URL
The complete URL of your Nextcloud server, e.g.:
- `https://nextcloud.example.com`
- `https://cloud.mydomain.com`

### WebDAV Path
The WebDAV path of the folder containing images. Format:
```
/remote.php/dav/files/USERNAME/FolderName
```

Examples:
- `/remote.php/dav/files/mario/Images`
- `/remote.php/dav/files/mario/Wallpapers`

### Username
Your Nextcloud username.

### Password or App Password
**Recommended: use an App Password instead of your main password!**

To generate an App Password:
1. Go to Nextcloud → Settings → Security
2. Scroll to "App Password"
3. Generate a new App Password
4. Use that password here

### UseLocalPath
- `false` = use WebDAV (direct connection)
- `true` = use locally synchronized folder

### LocalPath
If `UseLocalPath=true`, specify the local path of the synchronized folder, e.g.:
- `/home/user/Nextcloud/Images`
- `/home/user/Documents/Nextcloud/Wallpapers`

### MaxImages
Maximum number of images to load from the folder:
- `0` = unlimited (loads all images found)
- `100` = loads maximum 100 images
- `1000` = loads maximum 1000 images

**Note**: The limit is applied during scanning, so if you set `MaxImages=100`, it will load the first 100 images found (not the best 100).

## After Configuration

1. **Restart Plasma:**
   ```bash
   killall plasmashell && kstart plasmashell
   ```

2. **Go to Settings → Appearance → Background**

3. **Select "Picture of the Day"**

4. **In the "Provider" menu select "Nextcloud"**

5. The provider should load an image from your Nextcloud folder!

## Verify Configuration

To verify that the configuration is correct:

```bash
cat ~/.config/plasma_engine_potd/nextcloudprovider.conf
```

## Troubleshooting

### Provider doesn't load images

1. Verify that the configuration file exists:
   ```bash
   ls -la ~/.config/plasma_engine_potd/nextcloudprovider.conf
   ```

2. Check Plasma logs:
   ```bash
   journalctl --user -f | grep -i nextcloud
   ```

3. Verify that:
   - The URL is correct and reachable
   - The WebDAV path is correct
   - Username and password are correct
   - The folder contains image files (jpg, png, etc.)

### Authentication error

- Make sure you're using an App Password, not your main password
- Verify that username and password are correct
- Check that the URL doesn't have a trailing slash

### No images found

- Verify that the folder contains image files
- Check folder permissions on Nextcloud
- Make sure the WebDAV path is correct
