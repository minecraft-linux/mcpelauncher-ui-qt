#pragma once

#include <QObject>

class Gamepad : public QObject {
    Q_OBJECT

    Q_PROPERTY(QList<bool> buttons READ buttons NOTIFY inputChanged)
    Q_PROPERTY(QList<int> hats READ buttons NOTIFY inputChanged)
    Q_PROPERTY(QList<double> axes READ axes NOTIFY inputChanged)

private:
    QList<bool> m_buttons;
    QList<int> m_hats;
    QList<double> m_axes;

public:
    QList<bool> buttons() {
        return m_buttons;
    }
    QList<int> hats() {
        return m_hats;
    }
    QList<double> axes() {
        return m_axes;
    }
signals:
    inputChanged();
};

class GamepadManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QStringList errors READ errors NOTIFY errorAdded)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled)
    Q_PROPERTY(QList<Gamepad*> gamepads READ gamepads NOTIFY gamepadsChanged)

private:
    QStringList m_errors;
    QList<Gamepad*> m_gamepads;

public:
    QStringList addError(QString error) {
        m_errors << error;
        errorAdded();
    }

    QStringList errors() {
        return m_errors;
    }

    bool enabled() {
        return enabled;
    }

    void setEnabled(bool enabled) {
        m_enabled = enabled;
    }

    QList<Gamepad*> gamepads() {
        return m_gamepads;
    }

signals:
    void errorAdded();

    void gamepadsChanged();

public slots:

    void clearErrors() {
        m_errors.clear();
    }
};
