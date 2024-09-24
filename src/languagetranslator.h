#ifndef LANGUAGETRANSLATOR_H
#define LANGUAGETRANSLATOR_H

#include <QObject>
#include <QtQmlIntegration>

class QTranslator;

class LanguageTranslator : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit LanguageTranslator(QObject *parent = nullptr);

  Q_INVOKABLE bool load(const QString &language);
  Q_INVOKABLE bool loadSystemLanguage();
  Q_INVOKABLE QStringList locales() const;

private:
  bool load(const QLocale &locale);

private:
  QTranslator *m_translator;
  QTranslator *m_qtTrasnlator;
  QStringList m_locales;
};

#endif /* !LANGUAGETRANSLATOR_H */
