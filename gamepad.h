#pragma once

#include <QObject>

class Gamepad : public QObject {
    Q_OBJECT

    Q_PROPERTY(int id MEMBER m_id)
    Q_PROPERTY(QString guid MEMBER m_guid)
    Q_PROPERTY(QString name MEMBER m_name)
    Q_PROPERTY(QVector<unsigned char> buttons READ buttons NOTIFY inputChanged)
    Q_PROPERTY(QVector<unsigned char> hats READ hats NOTIFY inputChanged)
    Q_PROPERTY(QVector<float> axes READ axes NOTIFY inputChanged)
    Q_PROPERTY(QString fakeGamePadMapping MEMBER m_fakeGamePadMapping)

private:
    int m_id;
    QString m_guid;
    QString m_name;
    QVector<unsigned char> m_buttons;
    QVector<unsigned char> m_hats;
    QVector<float> m_axes;
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

    QVector<unsigned char> buttons() const {
        return m_buttons;
    }
    QVector<unsigned char> hats() const {
        return m_hats;
    }
    QVector<float> axes() const {
        return m_axes;
    }

    void updateInput(const unsigned char* buttons, size_t numButtons, const unsigned char* hats, size_t numHats, const float* axes, size_t numAxes) {
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

    void addError(QString error) {
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
