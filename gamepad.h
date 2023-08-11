#pragma once

#include <QObject>

class Gamepad : public QObject {
    Q_OBJECT

    Q_PROPERTY(int id MEMBER m_id)
    Q_PROPERTY(QString guid MEMBER m_guid)
    Q_PROPERTY(QString name MEMBER m_name)
    Q_PROPERTY(QVector<bool> buttons READ buttons NOTIFY inputChanged)
    Q_PROPERTY(QVector<int> hats READ buttons NOTIFY inputChanged)
    Q_PROPERTY(QVector<double> axes READ axes NOTIFY inputChanged)
    Q_PROPERTY(QString fakeGamePadMapping MEMBER m_fakeGamePadMapping)

private:
    int m_id;
    QString m_guid;
    QString m_name;
    QVector<bool> m_buttons;
    QVector<int> m_hats;
    QVector<double> m_axes;
    bool m_isGamePad = false;
    QString m_fakeGamePadMapping;

public:
    Gamepad(QObject* parent, int id, QString guid, QString name, QString fakeGamePadMapping) : QObject(parent) {
        m_id = 0;
        m_guid = guid;
        m_name = name;
        m_fakeGamePadMapping = fakeGamePadMapping;
    }

    int id() const {
        return m_id;
    }

    QVector<bool> buttons() const {
        return m_buttons;
    }
    QVector<int> hats() const {
        return m_hats;
    }
    QVector<double> axes() const {
        return m_axes;
    }

    void updateInput(bool* buttons, size_t numButtons, bool* hats, size_t numHats, double* axes, size_t numAxes) {
        m_buttons.resize(numButtons);
        m_hats.resize(numHats);
        m_axes.resize(numAxes);
        memcpy(m_buttons.data(), buttons, numButtons * sizeof(*buttons));
        memcpy(m_hats.data(), hats, numHats * sizeof(*hats));
        memcpy(m_axes.data(), axes, numAxes * sizeof(*axes));
        inputChanged();
    }
signals:
    void inputChanged();
};

class GamepadManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QStringList errors READ errors NOTIFY errorAdded)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled)
    Q_PROPERTY(QList<Gamepad*> gamepads READ gamepads NOTIFY gamepadsChanged)

private:
    bool m_enabled = true;
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
        return m_enabled;
    }

    void setEnabled(bool enabled) {
        m_enabled = enabled;
    }

    QList<Gamepad*>& gamepads() {
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
