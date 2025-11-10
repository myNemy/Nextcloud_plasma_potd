# Changelog

## [1.0.0] - 2024

### Added
- Nextcloud provider for KDE Plasma Picture of the Day
- WebDAV support for direct connection to Nextcloud
- Local path support for synchronized folders
- App Password authentication
- Random image selection
- Recursive search in all subfolders
- MaxImages option to limit the number of images loaded
- Unique identifier per image to bypass potd cache

### Notes
- Automatic rotation is not available because potd destroys the provider after `finished()`
- To change image, restart Plasma or change provider
- Each time the provider is recreated, it selects a new random image
