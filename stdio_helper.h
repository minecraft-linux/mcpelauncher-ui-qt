#pragma once
#include <QObject>
#include <QString>
#include <iostream>

class StdioHelper : public QObject {
    Q_OBJECT
public:
    explicit StdioHelper(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void write(const QString &msg);
    Q_INVOKABLE void error(const QString &msg);
};
