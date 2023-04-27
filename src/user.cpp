#include "user.h"

#include <QDebug>

User::User(QObject *parent) : QObject(parent)
{
}

bool sendCode(QString mobilePhoneNumber, QString areaCode)
{
    qDebug() << "Request Data: " << areaCode;
    return true;
}

User::~User()
{
}
