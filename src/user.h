// user.h
#ifndef USER_H
#define USER_H

#include "client.h"

#include <QObject>
#include <QString>

class User : public Client
{
    Q_OBJECT

public:
    explicit User(QObject *parent = 0);

public slots:
    void sendCode();

signals:
    void codeSent();
};

#endif // USER_H