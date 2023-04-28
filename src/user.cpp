// user.cpp
#include "user.h"
#include "api.h"

#include <QString>
#include <QLatin1String>
#include <QNetworkRequest>
#include <QByteArray>
#include <QDebug>

#include "lib/qjson/serializer.h"

User::User(QObject *parent) : Client(parent)
{
}

void User::sendCode()
{
    // Code to send the code
    QLatin1String path("/auth/sendCode");
    QString endpoint = COSMOS_FM_API_ENDPIONT + path;

    QUrl url(endpoint);
    QNetworkRequest request(url);

    // Set the content type header to application/json
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // Create the JSON data
    QVariantMap jsonData;
    jsonData["mobilePhoneNumber"] = "12345";
    jsonData["areaCode"] = "+1";

    // Convert JSON data to QByteArray using QJson::Serializer
    QJson::Serializer serializer;
    QByteArray postData = serializer.serialize(jsonData);

    // Send the post request
    m_reply = m_nam->post(request, postData);

    qDebug() << "Code sent" << endpoint;
    qDebug() << "Json data" << postData;

    emit codeSent();
}
