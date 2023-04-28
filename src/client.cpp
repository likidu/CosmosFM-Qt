#include "client.h"

#include <QDebug>
#include <QVariantMap>
#include <QByteArray>

#include "lib/qjson/parser.h"

Client::Client(QObject *parent) : QObject(parent), m_reply(NULL)
{
    m_nam = new QNetworkAccessManager(this);
    connect(m_nam, SIGNAL(finished(QNetworkReply *)), SLOT(onNetworkReply(QNetworkReply *)));
}

// Connect to the finished signal to handle the response
void Client::onNetworkReply(QNetworkReply *reply)
{
    // if (reply != m_reply)
    // {
    //     // Reply not for the latest request. Ignore it.
    //     reply->deleteLater();
    //     return;
    // }

    // m_reply = NULL;

    // if (!checkReplyForErrors(reply))
    // {
    //     emit clientCallFinished(false);
    //     return;
    // }
    if (reply->error() == QNetworkReply::NoError)
    {
        // Request succeeded, process the response
        QByteArray responseData = reply->readAll();

        // Parse the JSON response using QJson::Parser
        bool ok;
        QVariantMap responseMap = QJson::Parser().parse(responseData, &ok).toMap();
        if (ok)
        {
            // Handle the response data
        }
        else
        {
            qDebug() << "Error parsing JSON response.";
        }
    }
    else
    {
        // Request failed, handle the error
        qDebug() << "Error: " << reply->errorString();
    }

    // const bool result = parseReply(reply->readAll());

    // Clean up
    reply->deleteLater();

    emit clientCallFinished(true);
}

Client::~Client()
{
}
