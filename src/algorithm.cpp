#include <QList>

#include "algorithm.h"

namespace algorithm {

qsizetype levenshteinDistance(const QString &source, const QString &target) {
  if (source == target) {
    return 0;
  }

  const qsizetype sourceCount = source.size();
  const qsizetype targetCount = target.size();

  if (source.isEmpty()) {
    return targetCount;
  }

  if (target.isEmpty()) {
    return sourceCount;
  }

  if (sourceCount > targetCount) {
    return levenshteinDistance(target, source);
  }

  QList<int> column;
  column.fill(0, targetCount + 1);
  QList<int> previousColumn;
  previousColumn.reserve(targetCount + 1);
  for (int i = 0; i < targetCount + 1; i++) {
    previousColumn.append(i);
  }

  for (int i = 0; i < sourceCount; i++) {
    column[0] = i + 1;
    for (int j = 0; j < targetCount; j++) {
      column[j + 1] =
        std::min({1 + column.at(j), 1 + previousColumn.at(1 + j),
                  previousColumn.at(j) + (source.at(i) != target.at(j))});
    }
    column.swap(previousColumn);
  }

  return previousColumn.at(targetCount);
}

}  // namespace algorithm
