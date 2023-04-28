#ifndef CLIENT_H
#define CLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class Client : public QObject
{
    Q_OBJECT

public:
    explicit Client(QObject *parent = 0);

    ~Client();

private slots:
    void onNetworkReply(QNetworkReply *reply);

signals:
    void clientCallFinished(bool success);

protected:
    QNetworkAccessManager *m_nam;
    QNetworkReply *m_reply;

    QString m_error;
};

#endif // CLIENT_H