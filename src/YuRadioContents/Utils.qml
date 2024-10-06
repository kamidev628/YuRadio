pragma Singleton

import QtQml

QtObject {
    id: utils

    readonly property int maxInteger: 2147483646

    function clamp(number, min, max) {
        return Math.max(min, Math.min(number, max));
    }

    function sameSign(lhs, rhs) {
        return lhs * rhs >= 0;
    }

    function isEmpty(value) {
        return (
            // null or undefined
            (value == null) ||

            // has length and it's zero
            (value.hasOwnProperty('length') && value.length === 0) ||

            // is an Object and has no keys
            (value.constructor === Object && Object.keys(value).length === 0));
    }

    /* Maximum and minimum is inclusive */
    function getRandomInt(min, max) {
        const minCeiled = Math.ceil(min);
        const maxFloored = Math.floor(max);
        return Math.floor(Math.random() * (maxFloored - minCeiled + 1) + minCeiled); // The maximum is inclusive and the minimum is inclusive
    }

    function isNumericChar(c): bool {
        return /\d/.test(c);
    }

    function execLater(contextObject, delay, callback, args) {
        let timer = Qt.createQmlObject("import QtQml 2.15; Timer { }", contextObject);
        timer.interval = delay === undefined ? 100 : delay;
        timer.repeat = false;
        timer.triggered.connect(() => {
            callback(args);
            timer.destroy();
        });
        timer.start();
    }

    function shortDate(d: date, locale: var): string {
        return d.toLocaleDateString(locale, Locale.ShortFormat) + " " + d.toLocaleTimeString(locale, Locale.ShortFormat);
    }

    function isDateValid(d: date): bool {
        return !Number.isNaN(d.valueOf());
    }

    function dateToISOString(d: date): string {
        return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2);
    }

    function mysql_real_escape_string(str: string): string {
        return str.replace(/[\0\x08\x09\x1a\n\r"'\\\%]/g, function (c) {
            switch (c) {
            case "\0":
                return "\\0";
            case "\x08":
                return "\\b";
            case "\x09":
                return "\\t";
            case "\x1a":
                return "\\z";
            case "\n":
                return "\\n";
            case "\r":
                return "\\r";
            case "\"":
            case "'":
            case "\\":
            case "%":
                return "\\" + c; // prepends a backslash to backslash, percent,
            // and double/single quotes
            default:
                return c;
            }
        });
    }
}
