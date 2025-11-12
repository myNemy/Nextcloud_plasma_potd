/*
 *   SPDX-FileCopyrightText: 2024 Nextcloud Wallpaper Plugin
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "nextcloudprovider.h"

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QAuthenticator>
#include <QXmlStreamReader>
#include <QStandardPaths>
#include <QDateTime>
#include <QRegularExpression>
#include <QRandomGenerator>
#include <QCryptographicHash>
#include <QFile>
#include <algorithm>

#include <KConfigGroup>
#include <KPluginFactory>
#include <KSharedConfig>

#include "debug.h"

Q_LOGGING_CATEGORY(WALLPAPERPOTD, "kde.wallpapers.potd", QtInfoMsg)

NextcloudProvider::NextcloudProvider(QObject *parent, const KPluginMetaData &data, const QVariantList &args)
    : PotdProvider(parent, data, args)
    , m_useLocalPath(false)
    , m_maxImages(0) // Default: unlimited
{
    loadConfig();
    
    // WORKAROUND: Invalidate cache by making it "old" (> 1 day)
    // potd uses static identifier "nextcloud" for cache: ~/.cache/plasma_engine_potd/nextcloud
    // isCached() checks if file modification time is >= 1 day old (cachedprovider.cpp line 144).
    // By setting modification time to > 1 day ago, we force isCached() to return false,
    // which makes potd create our provider instead of CachedProvider.
    //
    // However, potd checks cache BEFORE creating provider. So if cache exists and is valid,
    // potd creates CachedProvider and this constructor is never called.
    //
    // Solution: We invalidate the cache by setting its modification time to > 1 day ago.
    // This must be done BEFORE potd checks, but we can't do that from the provider.
    // So we do it in selectRandomImage() after the image is selected, which ensures
    // the NEXT time potd checks (at midnight or manual refresh), the cache will be invalid.
    //
    // Actually, we also do it here as a fallback - if potd somehow creates our provider
    // even with cache existing, we invalidate it so the next check will fetch a new image.
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + QStringLiteral("/plasma_engine_potd/");
    const QString cacheFile = cacheDir + QStringLiteral("nextcloud");
    
    if (QFile::exists(cacheFile)) {
        // Set modification time to 2 days ago to invalidate cache
        // This makes isCached() return false (file is > 1 day old)
        QFile file(cacheFile);
        if (file.open(QIODevice::ReadWrite)) {
            QDateTime oldDate = QDateTime::currentDateTime().addDays(-2);
            file.setFileTime(oldDate, QFileDevice::FileModificationTime);
            file.close();
            qCDebug(WALLPAPERPOTD) << "Invalidated cache file (set mod time to 2 days ago):" << cacheFile;
        }
    }
    
    if (m_useLocalPath) {
        fetchImagesFromLocal();
    } else {
        fetchImagesFromWebDAV();
    }
}

NextcloudProvider::~NextcloudProvider()
{
    qCDebug(WALLPAPERPOTD) << "NextcloudProvider destructor called";
}

QString NextcloudProvider::identifier() const
{
    // IMPORTANT: potd engine uses the static identifier from metadata.json ("nextcloud")
    // for cache path generation, NOT this method. This method is only called when
    // the provider is saved to cache, but the cache path is already determined.
    // 
    // The cache path is: ~/.cache/plasma_engine_potd/{static_identifier}{args}
    // Since args is empty for our provider, the path is always the same.
    // 
    // To make each image unique, we need to include the image URL in the identifier
    // returned here, which will be used when saving to cache.
    // However, potd uses m_identifier (static) + m_args for cache lookup.
    //
    // The real solution: we need to make sure each image gets a different cache file.
    // Since we can't change m_identifier or m_args, we rely on the fact that
    // isCached() checks file modification time - if the file is older than 1 day,
    // it's considered invalid and a new image will be loaded.
    //
    // But this means the same image will be cached for 1 day. To get different images,
    // we need to clear the cache or wait for it to expire.
    
    if (m_selectedImageUrl.isEmpty()) {
        return PotdProvider::identifier();
    }
    
    // Include hash of image URL in identifier to make cache path unique
    // This ensures each image gets saved to a different cache file
    QCryptographicHash hash(QCryptographicHash::Md5);
    hash.addData(m_selectedImageUrl.toUtf8());
    QString hashString = hash.result().toHex().left(12); // Use 12 chars for better uniqueness
    
    // Format: nextcloud_<hash>
    // This will be used when saving to cache, making each image unique
    return PotdProvider::identifier() + QLatin1String("_") + hashString;
}

void NextcloudProvider::loadConfig()
{
    const QString configFileName = QStringLiteral("nextcloudprovider.conf");
    const QString configPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/plasma_engine_potd/") + configFileName;

    auto config = KSharedConfig::openConfig(configPath, KConfig::NoGlobals);
    KConfigGroup nextcloudGroup = config->group(QStringLiteral("Nextcloud"));

    // Read and normalize URL: remove trailing slash
    m_nextcloudUrl = nextcloudGroup.readEntry("Url", QString());
    if (m_nextcloudUrl.endsWith(QLatin1Char('/'))) {
        m_nextcloudUrl.chop(1);
    }
    
    // Read and normalize Path: ensure it starts with /
    m_nextcloudPath = nextcloudGroup.readEntry("Path", QString());
    if (!m_nextcloudPath.startsWith(QLatin1Char('/'))) {
        m_nextcloudPath = QLatin1Char('/') + m_nextcloudPath;
    }
    
    m_username = nextcloudGroup.readEntry("Username", QString());
    m_password = nextcloudGroup.readEntry("Password", QString());
    m_useLocalPath = nextcloudGroup.readEntry("UseLocalPath", false);
    m_localPath = nextcloudGroup.readEntry("LocalPath", QString());
    
    // Maximum number of images to load (0 = unlimited, default: 0)
    m_maxImages = nextcloudGroup.readEntry("MaxImages", 0);
}

void NextcloudProvider::fetchImagesFromWebDAV()
{
    if (m_nextcloudUrl.isEmpty() || m_nextcloudPath.isEmpty() || m_username.isEmpty() || m_password.isEmpty()) {
        qCWarning(WALLPAPERPOTD) << "Nextcloud configuration incomplete";
        Q_EMIT error(this);
        return;
    }

    // Build WebDAV URL
    // m_nextcloudUrl is normalized (no trailing slash)
    // m_nextcloudPath is normalized (starts with /)
    QUrl webdavUrl(m_nextcloudUrl + m_nextcloudPath);

    // Create PROPFIND request with Depth: infinity to search recursively
    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    QNetworkRequest request(webdavUrl);
    request.setRawHeader("Depth", "infinity");
    request.setRawHeader("Content-Type", "application/xml");

    // Set authentication
    QString concatenated = m_username + QLatin1Char(':') + m_password;
    QByteArray data = concatenated.toLocal8Bit().toBase64();
    QString headerData = QStringLiteral("Basic ") + data;
    request.setRawHeader("Authorization", headerData.toLocal8Bit());

    // PROPFIND XML body
    QByteArray propfindXml = R"(<?xml version="1.0"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:resourcetype/>
    <d:getcontenttype/>
    <d:displayname/>
  </d:prop>
</d:propfind>)";

    QNetworkReply *reply = manager->sendCustomRequest(request, "PROPFIND", propfindXml);
    connect(reply, &QNetworkReply::finished, this, [this, reply, manager]() {
        propfindRequestFinished(reply);
        reply->deleteLater();
        manager->deleteLater();
    });
}

void NextcloudProvider::propfindRequestFinished(QNetworkReply *reply)
{
    if (!reply) {
        Q_EMIT error(this);
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        qCWarning(WALLPAPERPOTD) << "PROPFIND error:" << reply->errorString();
        Q_EMIT error(this);
        return;
    }

    // Parse XML response
    QXmlStreamReader xml(reply->readAll());
    m_imageUrls.clear();

    // m_nextcloudUrl is normalized (no trailing slash)
    // href from PROPFIND is relative to the WebDAV root and starts with /
    QString baseUrl = m_nextcloudUrl;

    const QRegularExpression imageExtRegex(QStringLiteral("\\.(jpg|jpeg|png|bmp|webp|gif)$"), QRegularExpression::CaseInsensitiveOption);

    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.isStartElement() && xml.name() == QLatin1String("href")) {
            QString href = xml.readElementText();
            if (href.endsWith(QLatin1Char('/'))) {
                continue; // Skip directories
            }
            if (imageExtRegex.match(href).hasMatch()) {
                // href from PROPFIND is relative to the WebDAV root and starts with /
                // baseUrl has no trailing slash, so concatenation is: baseUrl + href
                // Example: "https://nemeyes.xyz" + "/remote.php/dav/files/..." = "https://nemeyes.xyz/remote.php/..."
                QString fullUrl = baseUrl + href;
                qCDebug(WALLPAPERPOTD) << "Building URL - baseUrl:" << baseUrl << "href:" << href << "fullUrl:" << fullUrl;
                m_imageUrls.append(fullUrl);
                
                // Limit the number of images if MaxImages is set
                if (m_maxImages > 0 && m_imageUrls.size() >= m_maxImages) {
                    break;
                }
            }
        }
    }

    if (m_imageUrls.isEmpty()) {
        qCWarning(WALLPAPERPOTD) << "No images found in Nextcloud";
        Q_EMIT error(this);
        return;
    }

    // IMPORTANT: Invalidate cache BEFORE selecting random image
    // This ensures that potd will use the correct image for preview
    // If we invalidate after, potd might generate preview from old cache
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + QStringLiteral("/plasma_engine_potd/");
    const QString cacheFile = cacheDir + QStringLiteral("nextcloud");
    
    if (QFile::exists(cacheFile)) {
        // Set modification time to 2 days ago to invalidate cache
        QFile file(cacheFile);
        if (file.open(QIODevice::ReadWrite)) {
            QDateTime oldDate = QDateTime::currentDateTime().addDays(-2);
            file.setFileTime(oldDate, QFileDevice::FileModificationTime);
            file.close();
            qCDebug(WALLPAPERPOTD) << "Invalidated cache file before image selection (set mod time to 2 days ago):" << cacheFile;
        }
    }

    // Shuffle the list for random order
    std::shuffle(m_imageUrls.begin(), m_imageUrls.end(), *QRandomGenerator::global());

    selectRandomImage();
}

void NextcloudProvider::fetchImagesFromLocal()
{
    if (m_localPath.isEmpty()) {
        qCWarning(WALLPAPERPOTD) << "Local path not configured";
        Q_EMIT error(this);
        return;
    }

    QDir dir(m_localPath);
    if (!dir.exists()) {
        qCWarning(WALLPAPERPOTD) << "Local path does not exist:" << m_localPath;
        Q_EMIT error(this);
        return;
    }

    m_imageUrls.clear();
    const QStringList imageFilters = {QStringLiteral("*.jpg"), QStringLiteral("*.jpeg"), QStringLiteral("*.png"), QStringLiteral("*.bmp"), QStringLiteral("*.webp"), QStringLiteral("*.gif")};
    
    // Search recursively in all subdirectories
    QDirIterator it(m_localPath, imageFilters, QDir::Files | QDir::Readable, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        m_imageUrls.append(it.next());
        
        // Limit the number of images if MaxImages is set
        if (m_maxImages > 0 && m_imageUrls.size() >= m_maxImages) {
            break;
        }
    }

    if (m_imageUrls.isEmpty()) {
        qCWarning(WALLPAPERPOTD) << "No images found in local path";
        Q_EMIT error(this);
        return;
    }

    // IMPORTANT: Invalidate cache BEFORE selecting random image
    // This ensures that potd will use the correct image for preview
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + QStringLiteral("/plasma_engine_potd/");
    const QString cacheFile = cacheDir + QStringLiteral("nextcloud");
    
    if (QFile::exists(cacheFile)) {
        // Set modification time to 2 days ago to invalidate cache
        QFile file(cacheFile);
        if (file.open(QIODevice::ReadWrite)) {
            QDateTime oldDate = QDateTime::currentDateTime().addDays(-2);
            file.setFileTime(oldDate, QFileDevice::FileModificationTime);
            file.close();
            qCDebug(WALLPAPERPOTD) << "Invalidated cache file before image selection (local, set mod time to 2 days ago):" << cacheFile;
        }
    }

    // Shuffle the list for random order
    std::shuffle(m_imageUrls.begin(), m_imageUrls.end(), *QRandomGenerator::global());

    selectRandomImage();
}

void NextcloudProvider::selectRandomImage()
{
    if (m_imageUrls.isEmpty()) {
        qCWarning(WALLPAPERPOTD) << "Cannot select random image: list is empty";
        Q_EMIT error(this);
        return;
    }

    // Select random image from the shuffled list
    // Since the list is already shuffled, we can just pick sequentially or randomly
    // Using random selection for better distribution
    int index = QRandomGenerator::global()->bounded(m_imageUrls.size());
    m_selectedImageUrl = m_imageUrls.at(index);
    qCDebug(WALLPAPERPOTD) << "Selected random image" << index << "of" << m_imageUrls.size() << ":" << m_selectedImageUrl;

    // CRITICAL: Set remoteUrl IMMEDIATELY after selection
    // This ensures that if potd queries remoteUrl() for preview generation,
    // it will get the correct image URL, not an empty or cached one
    if (m_selectedImageUrl.startsWith(QStringLiteral("http://")) || m_selectedImageUrl.startsWith(QStringLiteral("https://"))) {
        m_remoteUrl = QUrl(m_selectedImageUrl);
    } else {
        // For local paths, use file:// URL
        m_remoteUrl = QUrl::fromLocalFile(m_selectedImageUrl);
    }
    
    // Also set title immediately so preview shows correct filename
    QFileInfo fileInfo(m_selectedImageUrl);
    m_title = fileInfo.fileName();
    
    // Set optional metadata fields
    
    // infoUrl: URL to the Nextcloud folder or the image itself
    if (m_useLocalPath) {
        // For local paths, use the folder path
        m_infoUrl = QUrl::fromLocalFile(fileInfo.absolutePath());
    } else {
        // For WebDAV, use the Nextcloud folder URL
        // m_nextcloudUrl is normalized (no trailing slash)
        // m_nextcloudPath is normalized (starts with /)
        m_infoUrl = QUrl(m_nextcloudUrl + m_nextcloudPath);
        qCDebug(WALLPAPERPOTD) << "Building InfoUrl - baseUrl:" << m_nextcloudUrl << "path:" << m_nextcloudPath << "InfoUrl:" << m_infoUrl.toString();
    }
    
    // author: Nextcloud username (if available) or empty
    // Note: title was already set immediately after image selection above
    m_author = m_username.isEmpty() ? QString() : m_username;
    
    // Debug: Log metadata fields to verify they are set before finished() is emitted
    qCDebug(WALLPAPERPOTD) << "Metadata set - RemoteUrl:" << m_remoteUrl.toString()
                           << "InfoUrl:" << m_infoUrl.toString()
                           << "Title:" << m_title
                           << "Author:" << m_author;
    
    // Note: Cache invalidation is now done BEFORE selectRandomImage() is called
    // (in propfindRequestFinished() or fetchImagesFromLocal())
    // This ensures potd generates preview from the correct image

    // Download image if it's a URL, or load directly if it's a local path
    if (m_selectedImageUrl.startsWith(QStringLiteral("http://")) || m_selectedImageUrl.startsWith(QStringLiteral("https://"))) {
        QUrl imageUrl(m_selectedImageUrl);
        QNetworkAccessManager *manager = new QNetworkAccessManager(this);
        QNetworkRequest request(imageUrl);

        // Set authentication
        QString concatenated = m_username + QLatin1Char(':') + m_password;
        QByteArray data = concatenated.toLocal8Bit().toBase64();
        QString headerData = QStringLiteral("Basic ") + data;
        request.setRawHeader("Authorization", headerData.toLocal8Bit());

        QNetworkReply *reply = manager->get(request);
        connect(reply, &QNetworkReply::finished, this, [this, reply, manager]() {
            imageRequestFinished(reply);
            reply->deleteLater();
            manager->deleteLater();
        });
    } else {
        // Local file
        m_image = QImage(m_selectedImageUrl);
        if (m_image.isNull()) {
            Q_EMIT error(this);
        } else {
            // Debug: Verify metadata is set before emitting finished()
            qCDebug(WALLPAPERPOTD) << "Emitting finished() (local) - RemoteUrl:" << m_remoteUrl.toString()
                                   << "InfoUrl:" << m_infoUrl.toString()
                                   << "Title:" << m_title
                                   << "Author:" << m_author;
            Q_EMIT finished(this, m_image);
        }
    }
}

void NextcloudProvider::imageRequestFinished(QNetworkReply *reply)
{
    if (!reply) {
        Q_EMIT error(this);
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        qCWarning(WALLPAPERPOTD) << "Image download error:" << reply->errorString();
        Q_EMIT error(this);
        return;
    }

    QByteArray imageData = reply->readAll();
    m_image = QImage::fromData(imageData);

    if (m_image.isNull()) {
        qCWarning(WALLPAPERPOTD) << "Failed to load image from data";
        Q_EMIT error(this);
    } else {
        // Debug: Verify metadata is still set before emitting finished()
        qCDebug(WALLPAPERPOTD) << "Emitting finished() - RemoteUrl:" << m_remoteUrl.toString()
                               << "InfoUrl:" << m_infoUrl.toString()
                               << "Title:" << m_title
                               << "Author:" << m_author;
        Q_EMIT finished(this, m_image);
    }
}

K_PLUGIN_CLASS_WITH_JSON(NextcloudProvider, "nextcloudprovider.json")

#include "nextcloudprovider.moc"

