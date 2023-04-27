/**
 * @file user_model.h
 */

#ifndef USER_H
#define USER_H

#include <QObject>
#include <QString>

class User : public QObject
{
    Q_OBJECT

private:
    /* data */
public:
    User(QObject *parent = 0);

    bool sendCode(QString mobilePhoneNumber, QString areaCode = "86");

    ~User();
};

#endif // USER_H