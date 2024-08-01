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

    function init() {
        databaseInstance();
        getBookmarks().forEach(item => {
            bookmarkModel.append(item);
        });
        removeExpiredTags(14 * 24 * 60 * 60); // 2 weeks
    }

    function databaseInstance() {
        if (database)
            return database;
        try {
            let maybeDatabase = LocalStorage.openDatabaseSync("YuRadio", "1.0", "YuRadio app database");
            maybeDatabase.transaction(tx => {
                tx.executeSql(`CREATE TABLE IF NOT EXISTS bookmark (
                  stationuuid TEXT PRIMARY KEY,
                  object TEXT
                )`);
                tx.executeSql(`CREATE TABLE IF NOT EXISTS vote (
                  stationuuid TEXT PRIMARY KEY,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )`);
                tx.executeSql(`CREATE TABLE IF NOT EXISTS language (
                  name TEXT PRIMARY KEY
                )`);
                tx.executeSql(`CREATE TABLE IF NOT EXISTS country (
                  name TEXT PRIMARY KEY
                )`);
                tx.executeSql(`CREATE TABLE IF NOT EXISTS tag (
                  tag_id INTEGER PRIMARY KEY,
                  name TEXT UNIQUE,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )`);
            });
            database = maybeDatabase;
        } catch (error) {
            console.log("Error opening database: " + error);
        }
        return database;
    }

    function addBookmark(station) {
        databaseInstance().transaction(tx => {
            let object = Object.assign({}, station);
            Object.keys(object).forEach(k => object[k] == null && delete object[k]);
            tx.executeSql("INSERT INTO bookmark (stationuuid, object) VALUES (?, ?)", [object.stationuuid, JSON.stringify(object)]);
            bookmarkModel.append(object);
        });
    }

    function existsBookmark(stationUUID) {
        let exists = false;
        databaseInstance().transaction(tx => {
            let results = tx.executeSql("SELECT 1 FROM bookmark WHERE stationuuid = ?", [stationUUID]);
            exists = !!results.rows.length;
        });
        return exists;
    }

    function getBookmarks() {
        let bookmarks = [];
        databaseInstance().transaction(tx => {
            let results = tx.executeSql("SELECT object FROM bookmark");
            for (let i = 0; i < results.rows.length; i++) {
                bookmarks.push(JSON.parse(results.rows.item(i).object));
            }
        });
        return bookmarks;
    }

    function deleteBookmark(stationUUID) {
        databaseInstance().transaction(tx => {
            tx.executeSql("DELETE FROM bookmark WHERE stationuuid = ?", [stationUUID]);
            for (let i = 0; i < bookmarkModel.count; ++i) {
                if (bookmarkModel.get(i).stationuuid == stationUUID) {
                    bookmarkModel.remove(i);
                }
            }
        });
    }

    function addVote(stationUUID) {
        databaseInstance().transaction(tx => {
            tx.executeSql("INSERT INTO vote (stationuuid) VALUES (?)", [stationUUID]);
        });
    }

    function existsVote(stationUUID) {
        let exists = false;
        databaseInstance().transaction(tx => {
            let results = tx.executeSql("SELECT 1 FROM vote WHERE stationuuid = ?", [stationUUID]);
            exists = !!results.rows.length;
        });
        return exists;
    }

    function removeExpiredVotes(timeoutSec) {
        databaseInstance().transaction(tx => {
            tx.executeSql("DELETE FROM vote WHERE strftime('%s', 'now') - strftime('%s', created_at) >= ?", [timeoutSec]);
        });
    }

    function removeExpiredTags(timeoutSec) {
        databaseInstance().transaction(tx => {
            tx.executeSql("DELETE FROM tag WHERE strftime('%s', 'now') - strftime('%s', created_at) >= ?", [timeoutSec]);
        });
    }

    function addCountries(countries) {
        databaseInstance().transaction(tx => {
            const binds = countries.map(x => "(?)").join(",");
            tx.executeSql(`INSERT OR IGNORE INTO country (name) VALUES ${binds}`, [...countries]);
        });
    }

    function getCountries() {
        let countries = [];
        databaseInstance().transaction(tx => {
            let results = tx.executeSql("SELECT name FROM country");
            for (let i = 0; i < results.rows.length; i++) {
                let row = results.rows.item(i);
                countries.push(row.name);
            }
        });
        return countries;
    }

    function addLanguages(languages) {
        databaseInstance().transaction(tx => {
            const binds = languages.map(x => "(?)").join(",");
            tx.executeSql(`INSERT OR IGNORE INTO language (name) VALUES ${binds}`, [...languages]);
        });
    }

    function getLanguages() {
        let languages = [];
        databaseInstance().transaction(tx => {
            let results = tx.executeSql("SELECT name FROM language");
            for (let i = 0; i < results.rows.length; i++) {
                let row = results.rows.item(i);
                languages.push(row.name);
            }
        });
        return languages;
    }

    function addTags(tags) {
        databaseInstance().transaction(tx => {
            const binds = tags.map(x => "(?)").join(",");
            tx.executeSql(`INSERT OR IGNORE INTO tag (name) VALUES ${binds}`, [...tags]);
        });
    }

    function getTags() {
        let tags = [];
        databaseInstance().transaction(tx => {
            let results = tx.executeSql("SELECT name FROM tag ORDER BY tag_id ASC");
            for (let i = 0; i < results.rows.length; i++) {
                let row = results.rows.item(i);
                tags.push(row.name);
            }
        });
        return tags;
    }
}
