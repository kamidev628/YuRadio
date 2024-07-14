pragma Singleton

import QtQml

QtObject {
    id: utils

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
}
