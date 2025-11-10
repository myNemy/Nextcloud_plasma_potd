/*
 *   SPDX-FileCopyrightText: 2024 Nextcloud Wallpaper Plugin
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include "potdprovider.h"

#include <QDate>
#include <QDir>
#include <QNetworkReply>

#include <KJob>

/**
 * This class provides images from Nextcloud via WebDAV or local synchronized folder
 */
class NextcloudProvider : public PotdProvider
{
    Q_OBJECT

public:
    explicit NextcloudProvider(QObject *parent, const KPluginMetaData &data, const QVariantList &args);
    ~NextcloudProvider() override;
    
    /**
     * Override identifier() to make each image unique and bypass potd cache
     */
    QString identifier() const override;
    
    /**
     * Select a new random image from the already loaded list
     * Can be called to change the current image
     */
    Q_INVOKABLE void refresh();

private Q_SLOTS:
    void propfindRequestFinished(QNetworkReply *reply);
    void imageRequestFinished(QNetworkReply *reply);

private:
    void loadConfig();
    void fetchImagesFromWebDAV();
    void fetchImagesFromLocal();
    void selectRandomImage();

    // Configuration
    QString m_nextcloudUrl;
    QString m_nextcloudPath;
    QString m_username;
    QString m_password;
    bool m_useLocalPath;
    QString m_localPath;

    // Image list
    QStringList m_imageUrls;
    QString m_selectedImageUrl;
    QImage m_image;
    
    // Maximum number of images to load (0 = unlimited)
    int m_maxImages;
};

