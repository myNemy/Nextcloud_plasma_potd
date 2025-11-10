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
#include <algorithm>

#include <KConfigGroup>
#include <KIO/StoredTransferJob>
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
    
    // NOTE: Timer-based rotation is NOT possible because potd destroys the provider
    // after finished() signal (see potdengine.cpp line 137: provider->deleteLater())
    // The timer would be destroyed before it can fire.
    // To change images, user must restart Plasma or change provider.
    
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
    // Make identifier unique per image to bypass potd cache
    // Use a hash of the selected image URL/path
    if (m_selectedImageUrl.isEmpty()) {
        // Fallback to base identifier if no image selected yet
        return PotdProvider::identifier();
    }
    
    // Create a unique identifier based on the image URL/path
    // This ensures each image has a different cache key
    QCryptographicHash hash(QCryptographicHash::Md5);
    hash.addData(m_selectedImageUrl.toUtf8());
    QString hashString = hash.result().toHex().left(8); // Use first 8 chars of hash
    
    // Combine base identifier with hash
    return PotdProvider::identifier() + QLatin1String("_") + hashString;
}

void NextcloudProvider::loadConfig()
{
    const QString configFileName = QStringLiteral("nextcloudprovider.conf");
    const QString configPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/plasma_engine_potd/") + configFileName;

    auto config = KSharedConfig::openConfig(configPath, KConfig::NoGlobals);
    KConfigGroup nextcloudGroup = config->group(QStringLiteral("Nextcloud"));

    m_nextcloudUrl = nextcloudGroup.readEntry("Url", QString());
    m_nextcloudPath = nextcloudGroup.readEntry("Path", QString());
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
    QString baseUrl = m_nextcloudUrl;
    if (!baseUrl.endsWith(QLatin1Char('/'))) {
        baseUrl += QLatin1Char('/');
    }
    QString path = m_nextcloudPath;
    if (!path.startsWith(QLatin1Char('/'))) {
        path = QLatin1Char('/') + path;
    }
    QUrl webdavUrl(baseUrl + path);

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

    QString baseUrl = m_nextcloudUrl;
    if (!baseUrl.endsWith(QLatin1Char('/'))) {
        baseUrl += QLatin1Char('/');
    }
    QString path = m_nextcloudPath;
    if (!path.startsWith(QLatin1Char('/'))) {
        path = QLatin1Char('/') + path;
    }

    const QRegularExpression imageExtRegex(QStringLiteral("\\.(jpg|jpeg|png|bmp|webp|gif)$"), QRegularExpression::CaseInsensitiveOption);

    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.isStartElement() && xml.name() == QLatin1String("href")) {
            QString href = xml.readElementText();
            if (href.endsWith(QLatin1Char('/'))) {
                continue; // Skip directories
            }
            if (imageExtRegex.match(href).hasMatch()) {
                QString fullUrl = baseUrl + href;
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

    // Shuffle the list for random order
    std::shuffle(m_imageUrls.begin(), m_imageUrls.end(), *QRandomGenerator::global());

    selectRandomImage();
}

void NextcloudProvider::refresh()
{
    if (m_imageUrls.isEmpty()) {
        // If list is empty, reload from source
        if (m_useLocalPath) {
            fetchImagesFromLocal();
        } else {
            fetchImagesFromWebDAV();
        }
    } else {
        // Select a new random image from existing list
        selectRandomImage();
    }
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
            Q_EMIT finished(this, m_image);
            
            // Timer rotation removed - potd destroys provider after finished()
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
        Q_EMIT finished(this, m_image);
        
        // Timer rotation removed - potd destroys provider after finished()
    }
}

K_PLUGIN_CLASS_WITH_JSON(NextcloudProvider, "nextcloudprovider.json")

#include "nextcloudprovider.moc"

