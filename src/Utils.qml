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
}
