# When the Image List is Created and Updated

## List Creation

The list is created **only once** when:

1. **The provider is instantiated** (constructor `NextcloudProvider::NextcloudProvider`)
   - This happens when:
     - Plasma starts and the Nextcloud provider is selected
     - You change provider from another to Nextcloud
     - You restart Plasma

2. **In the constructor the following is called:**
   - `loadConfig()` - loads configuration
   - `fetchImagesFromWebDAV()` or `fetchImagesFromLocal()` - creates the list

## List Update

The list **is NOT updated automatically**. It remains in memory until:

- The provider is destroyed (when you change provider or restart Plasma)
- `refresh()` is manually called when the list is empty

## Current Behavior

```
Plasma Start / Select Nextcloud
    ↓
NextcloudProvider() Constructor
    ↓
loadConfig()
    ↓
fetchImagesFromWebDAV() or fetchImagesFromLocal()
    ↓
Create m_imageUrls list (ALL images)
    ↓
Randomize list (std::shuffle)
    ↓
Select first random image
    ↓
Provider destroyed by potd after finished()
```

## When the List is Reloaded

The list is reloaded **only** if:

1. **You call `refresh()` and the list is empty:**
   ```cpp
   void NextcloudProvider::refresh() {
       if (m_imageUrls.isEmpty()) {
           // Reload from source
           fetchImagesFromWebDAV() or fetchImagesFromLocal()
       } else {
           // Only select new image from existing list
           selectRandomImage();
       }
   }
   ```

2. **The provider is destroyed and recreated:**
   - Change provider and return to Nextcloud
   - Restart Plasma

## Implications

- ✅ **Advantage**: The list remains in memory, changing image is fast (just random selection)
- ❌ **Disadvantage**: If you add new images to Nextcloud, they won't be seen until you reload

## How to Reload the List

To see new images added to Nextcloud, just:

1. **Restart the Plasma session:**
   ```bash
   killall plasmashell && kstart plasmashell
   ```

2. **Change provider and return to Nextcloud:**
   - Go to Settings → Background → Picture of the Day
   - Change provider (e.g. Bing)
   - Return to Nextcloud

The list will be automatically reloaded when the provider is recreated.
