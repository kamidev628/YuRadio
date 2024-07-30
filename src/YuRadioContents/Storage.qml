pragma Singleton

import QtQml
import QtQuick
import QtQuick.LocalStorage

QtObject {
    id: root

    property var database: null
    property ListModel bookmarkModel: ListModel {}

    Component.onCompleted: {
        databaseInstance();
    }

    function databaseInstance() {
        if (database)
            return database;
        try {
            let maybeDatabase = LocalStorage.openDatabaseSync("YuRadio", "1.0", "YuRadio app database");
            maybeDatabase.transaction(function (tx) {
                tx.executeSql(`CREATE TABLE IF NOT EXISTS bookmark (
                  stationuuid TEXT PRIMARY KEY,
                  object TEXT
                  )`);
            });
            database = maybeDatabase;
            getBookmarks().forEach(item => {
                bookmarkModel.append(item);
            });
        } catch (error) {
            console.log("Error opening database: " + error);
        }
        return database;
    }

    function addBookmark(station) {
        databaseInstance().transaction(function (tx) {
            let object = Object.assign({}, station);
            Object.keys(object).forEach(k => object[k] == null && delete object[k]);
            tx.executeSql("INSERT INTO bookmark (stationuuid, object) VALUES (?, ?)", [object.stationuuid, JSON.stringify(object)]);
            bookmarkModel.append(object);
        });
    }

    function existsBookmark(stationUUID) {
        let exists = false;
        databaseInstance().transaction(function (tx) {
            let results = tx.executeSql("SELECT 1 FROM bookmark WHERE stationuuid = ?", [stationUUID]);
            exists = !!results.rows.length;
        });
        return exists;
    }

    function getBookmarks() {
        let bookmarks = [];
        databaseInstance().transaction(function (tx) {
            let results = tx.executeSql("SELECT object FROM bookmark");
            for (let i = 0; i < results.rows.length; i++) {
                bookmarks.push(JSON.parse(results.rows.item(i).object));
            }
        });
        return bookmarks;
    }

    function deleteBookmark(stationUUID) {
        databaseInstance().transaction(function (tx) {
            tx.executeSql("DELETE FROM bookmark WHERE stationuuid = ?", [stationUUID]);
            for (let i = 0; i < bookmarkModel.count; ++i) {
                if (bookmarkModel.get(i).stationuuid == stationUUID) {
                    bookmarkModel.remove(i);
                }
            }
        });
    }
}
