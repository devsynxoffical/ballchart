/** In-memory socket presence. Fine for a single Railway replica. */

const onlineUsers = new Map(); // userId -> Set(socketId)

function addSocket(userId, socketId) {
    const id = `${userId || ''}`;
    if (!id || id === 'undefined') return { becameOnline: false };
    if (!onlineUsers.has(id)) onlineUsers.set(id, new Set());
    const set = onlineUsers.get(id);
    const becameOnline = set.size === 0;
    set.add(socketId);
    return { becameOnline };
}

function removeSocket(userId, socketId) {
    const id = `${userId || ''}`;
    const set = onlineUsers.get(id);
    if (!set) return { becameOffline: false };
    set.delete(socketId);
    if (set.size === 0) {
        onlineUsers.delete(id);
        return { becameOffline: true };
    }
    return { becameOffline: false };
}

function isOnline(userId) {
    const set = onlineUsers.get(`${userId || ''}`);
    return !!(set && set.size > 0);
}

function onlineUserIds() {
    return [...onlineUsers.keys()];
}

module.exports = { addSocket, removeSocket, isOnline, onlineUserIds };
