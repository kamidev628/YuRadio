pragma Singleton

import QtQml
import QtQuick
import QtQuick.LocalStorage

QtObject {
    id: root

    property var database: null
    property ListModel bookmarkModel: ListModel {}
    property Timer voteUpdateTimer: Timer {
        interval: 10 * 60 * 1000 // 10 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.removeExpiredVotes(interval / 1000);
        }
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
            maybeDatabase.transaction(function (tx) {
                tx.executeSql(`CREATE TABLE IF NOT EXISTS vote (
                  stationuuid TEXT PRIMARY KEY,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

    function addVote(stationUUID) {
        databaseInstance().transaction(function (tx) {
            tx.executeSql("INSERT INTO vote (stationuuid) VALUES (?)", [stationUUID]);
        });
    }

    function existsVote(stationUUID) {
        let exists = false;
        databaseInstance().transaction(function (tx) {
            let results = tx.executeSql("SELECT 1 FROM vote WHERE stationuuid = ?", [stationUUID]);
            exists = !!results.rows.length;
        });
        return exists;
    }

    function removeExpiredVotes(timeoutSec) {
        databaseInstance().transaction(function (tx) {
            console.log("REMOVING EXPIRED VOTES", timeoutSec);
            tx.executeSql("DELETE FROM vote WHERE strftime('%s', 'now') - strftime('%s', created_at) >= ?", [timeoutSec]);
        });
    }
}
