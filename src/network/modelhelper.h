#ifndef MODELHELPER_H
#define MODELHELPER_H

#define CHECK_ROWCOUNT(index)                                                  \
  if (!checkIndex(index))                                                      \
  return 0

#define CHECK_COLUMNCOUNT(index)                                               \
  if (!checkIndex(index))                                                      \
  return 0

#define CHECK_DATA(index)                                                      \
  if ((qobject_cast<const QAbstractTableModel *>(this) ||                      \
       qobject_cast<const QAbstractListModel *>(this)) &&                      \
      !checkIndex(index,                                                       \
                  QAbstractItemModel::CheckIndexOption::IndexIsValid |         \
                    QAbstractItemModel::CheckIndexOption::ParentIsInvalid))    \
    return {};                                                                 \
                                                                               \
  if (!checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid))  \
    return {}

#define CHECK_SETDATA(index) CHECK_DATA(index)

#define CHECK_CANFETCHMORE(index)                                              \
  if (!checkIndex(index))                                                      \
  return false

#define CHECK_FETCHMORE(index)                                                 \
  if (!checkIndex(index))                                                      \
  return

#define CHECK_HEADERDATA(section, orientation)                                 \
  if ((section) < 0)                                                           \
    return {};                                                                 \
  if ((orientation) == Qt::Horizontal && (section) >= columnCount({}))         \
    return {};                                                                 \
  if ((orientation) == Qt::Vertical && (section) >= rowCount({}))              \
    return {}

#define CHECK_SETHEADERDATA(section, orientation)                              \
  CHECK_HEADERDATA(section, orientation)

#define CHECK_FLAGS(index)                                                     \
  if (!checkIndex(index))                                                      \
    return {}

#define CHECK_PARENT(parent)                                                   \
  if (!checkIndex(parent,                                                      \
                  QAbstractItemModel::CheckIndexOption::DoNotUseParent))       \
    return {}

#define CHECK_INSERTROWS(row, count, parent)                                   \
  if (!checkIndex(parent) || (row) < 0 || (row) >= rowCount(parent) ||         \
      !(count))                                                                \
  return

#define CHECK_REMOVEROWS(row, count, parent)                                   \
  if (!checkIndex(parent) || (row) < 0 ||                                      \
      ((row) + (count)) > rowCount(parent) || !(count))                        \
  return false

#endif /* !MODELHELPER_H */
