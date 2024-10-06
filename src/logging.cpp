#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>

#include "logging.h"
#include "memoryliterals.h"

using namespace Qt::StringLiterals;
using namespace MemoryLiterals;

QtMessageHandler g_originalHandler = nullptr;

constexpr qint64 MAX_LOG_FILE_SIZE = 1_MiB;

static void logToFileMessageHandler(QtMsgType type,
                                    const QMessageLogContext &context,
                                    const QString &msg) {
#ifndef Q_OS_ANDROID
  QString message = qFormatLogMessage(type, context, msg);
  QString logPath = Logging::logFilePath();
  static FILE *f = fopen(qPrintable(logPath), "a");
  if (f) {
    fprintf(f, "%s\n", qPrintable(message));
    fflush(f);
  }
#endif

  if (g_originalHandler) {
    (*g_originalHandler)(type, context, msg);
  }
}

void Logging::initialize() {
  /* Format logging messages */
  qSetMessagePattern(
    u"%{if-info}\033[38;2;251;241;199m\033[48;2;7;102;120m%{endif}%{if-warning}"
    u"\033[38;2;251;241;199m\033[48;2;181;118;20m%{endif}%{if-critical}\033[38;"
    u"2;230;198;163m\033[48;2;157;0;6m%{endif}%{if-"
    u"fatal}\033[38;2;230;198;163m\033[48;2;157;0;6m%{"
    u"endif}%{if-"
    u"category}%{category} %{endif}[%{time yyyy/MM/dd h:mm:ss.zzz} "
    "%{if-debug}Debug%{endif}%{if-info}Info%{endif}%{if-"
    "warning}Warning%{endif}"
    "%{if-critical}Critical%{endif}%{if-fatal}Fatal%{endif}]"
#ifdef QT_DEBUG
    " %{file}:%{line}"
#endif /* QT_DEBUG */
    " - %{message}\033[0m"_s);

  g_originalHandler = qInstallMessageHandler(logToFileMessageHandler);

  /* Create AppDataLocation if not exists */
  QDir().mkpath(
    QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));

  QString logPath = logFilePath();

  QFile logFile(logPath);
  bool ok = logFile.open(QIODevice::ReadWrite);

  if (ok && logFile.size() > MAX_LOG_FILE_SIZE) {
    qint64 overgrow = logFile.size() - MAX_LOG_FILE_SIZE;
    Q_ASSERT(overgrow > 0);

    logFile.skip(static_cast<qint64>(200_KiB) + overgrow);

    QByteArray newData = logFile.readAll();
    logFile.resize(0);
    logFile.write(newData);
  }
}

QString Logging::logFilePath() {
  QString logFileName = u"log.txt"_s;
  QDir appDataLocation(
    QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));

  return appDataLocation.filePath(logFileName);
}
