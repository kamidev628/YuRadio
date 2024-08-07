#include <QGuiApplication>
#include <QLocale>
#include <QTranslator>

#include <QQmlApplicationEngine>

#include "languagetranslator.h"

using namespace Qt::StringLiterals;

LanguageTranslator::LanguageTranslator(QObject *parent)
    : QObject(parent), m_translator(new QTranslator(this)) {
  QGuiApplication::installTranslator(m_translator);

  QDirIterator it(":/i18n", {"*"}, QDir::Files, QDirIterator::Subdirectories);
  while (it.hasNext()) {
    QString translationFile = it.next();
    translationFile.truncate(translationFile.lastIndexOf("."));
    translationFile.remove(0, translationFile.indexOf('_') + 1);
    m_locales << translationFile;
  }
}

bool LanguageTranslator::load(const QString &language) {
  if (m_translator->load(QLocale(language), "YuRadio"_L1, "_"_L1,
                         ":/i18n"_L1)) {
    qmlEngine(this)->retranslate();
    return true;
  }
  return false;
}

bool LanguageTranslator::loadSystemLanguage() {
  if (m_translator->load(QLocale(), "YuRadio"_L1, "_"_L1, ":/i18n"_L1)) {
    qmlEngine(this)->retranslate();
    return true;
  }
  return false;
}

QStringList LanguageTranslator::locales() const {
  return m_locales;
};
