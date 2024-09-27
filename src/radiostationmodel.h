#ifndef RADIOSTATIONMODEL_H
#define RADIOSTATIONMODEL_H

#include "network/abstractrestmodel.h"
#include "radiostation.h"

struct QmlForeignQAbstractRestListModel {
  Q_GADGET
  QML_FOREIGN(QAbstractListModel)
  QML_ANONYMOUS
};

class RadioStationModel : public AbstractRestListModel {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit RadioStationModel(QObject *parent = nullptr);

  enum Roles {
    UUIDRole = Qt::UserRole + 1,
    TagsRole,
    CountryRole,
    CountryCodeRole,
    LanguageRole,
    StateRole,
    NameRole,
    CodecRole,
    UrlRole,
    HomepageRole,
    FaviconRole,
    VotesRole,
    BitrateRole,
    GeoLatitudeRole,
    GeoLongitudeRole
  };
  Q_ENUM(Roles)

  int rowCount(const QModelIndex &parent) const override;
  QVariant data(const QModelIndex &index, int role) const override;
  void reset() override;

  Q_INVOKABLE RadioStation get(int row);

  QHash<int, QByteArray> roleNames() const override;

protected:
  void handleRequestData(const QByteArray &data) override;

private:
  QList<RadioStation> m_stations;
};

#endif /* !RADIOSTATIONMODEL_H */
