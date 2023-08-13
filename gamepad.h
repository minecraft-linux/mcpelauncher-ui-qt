#pragma once

#include <QObject>
#include <fstream>

class Gamepad : public QObject {
    Q_OBJECT

    Q_PROPERTY(int id MEMBER m_id NOTIFY metaChanged)
    Q_PROPERTY(QString guid MEMBER m_guid NOTIFY metaChanged)
    Q_PROPERTY(QString name MEMBER m_name NOTIFY metaChanged)
    Q_PROPERTY(QVector<int> buttons READ buttons NOTIFY inputChanged)
    Q_PROPERTY(QVector<int> hats READ hats NOTIFY inputChanged)
    Q_PROPERTY(QVector<qreal> axes READ axes NOTIFY inputChanged)
    Q_PROPERTY(QString fakeGamePadMapping MEMBER m_fakeGamePadMapping NOTIFY metaChanged)
    Q_PROPERTY(bool hasMapping MEMBER m_hasMapping NOTIFY mappingChanged)

private:
    int m_id;
    QString m_guid;
    QString m_name;
    QVector<int> m_buttons;
    QVector<int> m_hats;
    QVector<qreal> m_axes;
    bool m_isGamePad = false;
    QString m_fakeGamePadMapping;
    bool m_hasMapping = false;

public:
    Gamepad(QObject* parent, int id, QString guid, QString name, QString fakeGamePadMapping) : QObject(parent) {
        m_id = id;
        m_guid = guid;
        m_name = name;
        m_fakeGamePadMapping = fakeGamePadMapping;
        metaChanged();
    }

    int id() const {
        return m_id;
    }

    QVector<int> buttons() const {
        return m_buttons;
    }
    QVector<int> hats() const {
        return m_hats;
    }
    QVector<qreal> axes() const {
        return m_axes;
    }

    void updateInput(const unsigned char* buttons, size_t numButtons, const unsigned char* hats, size_t numHats, const float* axes, size_t numAxes) {
        bool changed = false;
        if(m_buttons.size() != numButtons) {
            m_buttons.resize(numButtons);
            changed = true;
        }
        if(m_hats.size() != numHats) {
            m_hats.resize(numHats);
            changed = true;
        }
        if(m_axes.size() != numAxes) {
            m_axes.resize(numAxes);
            changed = true;
        }
        auto qbuttons = m_buttons.data();
        for(int i = 0; i < numButtons; i++) {
            if(qbuttons[i] != buttons[i]) {
                qbuttons[i] = buttons[i];
                changed = true;
            }
        }
        auto qhats = m_hats.data();
        for(int i = 0; i < numHats; i++) {
            if(qhats[i] != hats[i]) {
                qhats[i] = hats[i];
                changed = true;
            }
        }
        auto qaxes = m_axes.data();
        for(int i = 0; i < numAxes; i++) {
            if(qaxes[i] != axes[i]) {
                qaxes[i] = axes[i];
                changed = true;
            }
        }

        if(changed) {
            inputChanged();
        }
    }

    void setHasMapping(bool hasMapping) {
        if(m_hasMapping != hasMapping) {
            m_hasMapping = hasMapping;
            mappingChanged();
        }
    }
signals:
    void inputChanged();
    void metaChanged();
    void mappingChanged();
};

class GamepadManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QStringList errors READ errors NOTIFY errorAdded)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled)
    //  QList<Gamepad*> works in qt5.15+
    Q_PROPERTY(QList<QObject*> gamepads READ gamepads NOTIFY gamepadsChanged)

private:
    bool m_enabled = true;
    QStringList m_errors;
    QList<QObject*> m_gamepads;

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

    QList<QObject*>& gamepads() {
        return m_gamepads;
    }

signals:
    void errorAdded();

    void gamepadsChanged();

public slots:

    void clearErrors() {
        m_errors.clear();
    }

    void saveMapping(QString datadir, QString mapping) {
        std::ofstream gamepaddb((datadir.toStdString() + "/gamecontrollerdb.txt").data(), std::ios::binary | std::ios::ate | std::ios::app);
        if(gamepaddb.is_open()) {
            gamepaddb << "\n" << mapping.toStdString() << "\n";
        }
    }
};
