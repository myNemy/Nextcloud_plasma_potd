/*
 *   SPDX-FileCopyrightText: 2024 Nextcloud Wallpaper Plugin
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QMessageBox>
#include <QProcess>
#include <QStandardPaths>

#include <KConfigGroup>
#include <KSharedConfig>

class ConfigManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString nextcloudUrl READ nextcloudUrl WRITE setNextcloudUrl NOTIFY nextcloudUrlChanged)
    Q_PROPERTY(QString nextcloudPath READ nextcloudPath WRITE setNextcloudPath NOTIFY nextcloudPathChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(bool useLocalPath READ useLocalPath WRITE setUseLocalPath NOTIFY useLocalPathChanged)
    Q_PROPERTY(QString localPath READ localPath WRITE setLocalPath NOTIFY localPathChanged)
    Q_PROPERTY(int maxImages READ maxImages WRITE setMaxImages NOTIFY maxImagesChanged)

public:
    explicit ConfigManager(QObject *parent = nullptr)
        : QObject(parent)
        , m_useLocalPath(false)
        , m_maxImages(0)
    {
        loadConfig();
    }

    QString nextcloudUrl() const { return m_nextcloudUrl; }
    void setNextcloudUrl(const QString &url) {
        if (m_nextcloudUrl != url) {
            m_nextcloudUrl = url;
            emit nextcloudUrlChanged();
        }
    }

    QString nextcloudPath() const { return m_nextcloudPath; }
    void setNextcloudPath(const QString &path) {
        if (m_nextcloudPath != path) {
            m_nextcloudPath = path;
            emit nextcloudPathChanged();
        }
    }

    QString username() const { return m_username; }
    void setUsername(const QString &user) {
        if (m_username != user) {
            m_username = user;
            emit usernameChanged();
        }
    }

    QString password() const { return m_password; }
    void setPassword(const QString &pass) {
        if (m_password != pass) {
            m_password = pass;
            emit passwordChanged();
        }
    }

    bool useLocalPath() const { return m_useLocalPath; }
    void setUseLocalPath(bool use) {
        if (m_useLocalPath != use) {
            m_useLocalPath = use;
            emit useLocalPathChanged();
        }
    }

    QString localPath() const { return m_localPath; }
    void setLocalPath(const QString &path) {
        if (m_localPath != path) {
            m_localPath = path;
            emit localPathChanged();
        }
    }

    int maxImages() const { return m_maxImages; }
    void setMaxImages(int max) {
        if (m_maxImages != max) {
            m_maxImages = max;
            emit maxImagesChanged();
        }
    }

    Q_INVOKABLE void loadConfig() {
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
        m_maxImages = nextcloudGroup.readEntry("MaxImages", 0);

        emit nextcloudUrlChanged();
        emit nextcloudPathChanged();
        emit usernameChanged();
        emit passwordChanged();
        emit useLocalPathChanged();
        emit localPathChanged();
        emit maxImagesChanged();
    }

    Q_INVOKABLE bool saveConfig() {
        const QString configFileName = QStringLiteral("nextcloudprovider.conf");
        const QString configDir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/plasma_engine_potd/");
        const QString configPath = configDir + configFileName;

        // Create directory if it doesn't exist
        QDir dir;
        if (!dir.exists(configDir)) {
            dir.mkpath(configDir);
        }

        auto config = KSharedConfig::openConfig(configPath, KConfig::NoGlobals);
        KConfigGroup nextcloudGroup = config->group(QStringLiteral("Nextcloud"));

        nextcloudGroup.writeEntry("Url", m_nextcloudUrl);
        nextcloudGroup.writeEntry("Path", m_nextcloudPath);
        nextcloudGroup.writeEntry("Username", m_username);
        nextcloudGroup.writeEntry("Password", m_password);
        nextcloudGroup.writeEntry("UseLocalPath", m_useLocalPath);
        nextcloudGroup.writeEntry("LocalPath", m_localPath);
        nextcloudGroup.writeEntry("MaxImages", m_maxImages);

        config->sync();
        return true;
    }

    Q_INVOKABLE QString validateConfig() {
        if (m_useLocalPath) {
            if (m_localPath.isEmpty()) {
                return QStringLiteral("Local path is required when using local path mode");
            }
            QDir dir(m_localPath);
            if (!dir.exists()) {
                return QStringLiteral("Local path does not exist");
            }
        } else {
            if (m_nextcloudUrl.isEmpty()) {
                return QStringLiteral("Nextcloud URL is required");
            }
            if (m_nextcloudPath.isEmpty()) {
                return QStringLiteral("WebDAV path is required");
            }
            if (m_username.isEmpty()) {
                return QStringLiteral("Username is required");
            }
            if (m_password.isEmpty()) {
                return QStringLiteral("Password is required");
            }
        }
        return QString();
    }

    Q_INVOKABLE QString getInstallInstructions() {
        return QStringLiteral("To install the provider:\n\n"
                             "1. Compile the provider:\n"
                             "   cd build\n"
                             "   cmake ..\n"
                             "   make\n"
                             "   sudo make install\n\n"
                             "2. Restart Plasma:\n"
                             "   killall plasmashell && kstart plasmashell");
    }

signals:
    void nextcloudUrlChanged();
    void nextcloudPathChanged();
    void usernameChanged();
    void passwordChanged();
    void useLocalPathChanged();
    void localPathChanged();
    void maxImagesChanged();

private:
    QString m_nextcloudUrl;
    QString m_nextcloudPath;
    QString m_username;
    QString m_password;
    bool m_useLocalPath;
    QString m_localPath;
    int m_maxImages;
};

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Nextcloud Wallpaper Config"));
    app.setApplicationVersion(QStringLiteral("1.0.0"));

    QQmlApplicationEngine engine;

    ConfigManager configManager;
    engine.rootContext()->setContextProperty(QStringLiteral("configManager"), &configManager);

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}

#include "main.moc"

