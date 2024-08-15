#include <QGuiApplication>
#include <QLocale>
#include <QTranslator>

#include <QQmlApplicationEngine>

#include "languagetranslator.h"

using namespace Qt::StringLiterals;

LanguageTranslator::LanguageTranslator(QObject *parent)
    : QObject(parent), m_translator(new QTranslator(this)) {
  QGuiApplication::installTranslator(m_translator);

  QDirIterator it(u":/i18n"_s, {u"*"_s}, QDir::Files,
                  QDirIterator::Subdirectories);
  while (it.hasNext()) {
    QString translationFile = it.next();
    translationFile.truncate(translationFile.lastIndexOf('.'_L1));
    translationFile.remove(0, translationFile.indexOf('_'_L1) + 1);
    m_locales << translationFile;
  }
}

bool LanguageTranslator::load(const QString &language) {
  if (m_translator->load(QLocale(language), u"YuRadio"_s, u"_"_s,
                         u":/i18n"_s)) {
    qmlEngine(this)->retranslate();
    return true;
  }
  return false;
}

bool LanguageTranslator::loadSystemLanguage() {
  if (m_translator->load(QLocale(), u"YuRadio"_s, u"_"_s, u":/i18n"_s)) {
    qmlEngine(this)->retranslate();
    return true;
  }
  return false;
}

QStringList LanguageTranslator::locales() const {
  return m_locales;
};
