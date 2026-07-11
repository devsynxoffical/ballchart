const asyncHandler = require('express-async-handler');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Coach = require('../models/Coach');
const Player = require('../models/Player');
const Team = require('../models/Team');
const { findUserById, academyScopeId, participantDto } = require('../utils/userLookup');

function userInConversation(conversation, userId) {
    return conversation.participants.some((p) => `${p.userId}` === `${userId}`);
}

function otherParticipant(conversation, userId) {
    const other = conversation.participants.find((p) => `${p.userId}` !== `${userId}`);
    return other;
}

function unreadForUser(conversation, userId) {
    const read = conversation.readBy.find((r) => `${r.userId}` === `${userId}`);
    const since = read?.lastReadAt || new Date(0);
    return Message.countDocuments({
        conversationId: conversation._id,
        senderId: { $ne: userId },
        createdAt: { $gt: since },
    });
}

async function conversationSummary(conversation, userId) {
    const otherRef = otherParticipant(conversation, userId);
    let other = null;
    if (otherRef) other = await findUserById(otherRef.userId);
    const unreadCount = await unreadForUser(conversation, userId);
    return {
        _id: conversation._id,
        id: conversation._id,
        kind: conversation.kind,
        teamId: conversation.teamId,
        teamName: conversation.teamName,
        lastMessagePreview: conversation.lastMessagePreview || '',
        lastMessageAt: conversation.lastMessageAt,
        unreadCount,
        unread: unreadCount,
        other: other ? participantDto(other) : null,
    };
}

async function emitMessageNew(io, conversationId, messageDoc) {
    if (!io) return;
    const payload = {
        conversationId: `${conversationId}`,
        ...messageDoc,
        _id: messageDoc._id,
        id: messageDoc._id,
    };
    io.emit('MESSAGE_NEW', payload);
    io.emit('message:new', payload);
}

async function createNotification(io, { userId, title, message, type, managedBy, relatedUserId }) {
    const n = await Notification.create({
        userId,
        title,
        message,
        type: type || 'message',
        managedBy,
        relatedUserId,
        isRead: false,
    });
    if (io) {
        io.emit('NOTIFICATION_NEW', { userId: `${userId}`, notificationId: `${n._id}` });
        io.emit('NOTIFICATION_CREATED', { userId: `${userId}`, notificationId: `${n._id}` });
    }
}

const getEligibleContacts = asyncHandler(async (req, res) => {
    const scope = academyScopeId(req.user);
    const coaches = await Coach.find({ managedBy: scope }).select('-password');
    const teams = await Team.find({ managedBy: scope }).populate('players', 'username email role');
    const players = teams.flatMap((t) => t.players || []);
    const seen = new Set([`${req.user._id}`]);
    const out = [];
    for (const c of coaches) {
        if (seen.has(`${c._id}`)) continue;
        seen.add(`${c._id}`);
        out.push(participantDto(c));
    }
    for (const p of players) {
        if (!p || seen.has(`${p._id}`)) continue;
        seen.add(`${p._id}`);
        out.push(participantDto(p));
    }
    res.json(out);
});

const listConversations = asyncHandler(async (req, res) => {
    const scope = academyScopeId(req.user);
    const conversations = await Conversation.find({
        managedBy: scope,
        'participants.userId': req.user._id,
    }).sort({ lastMessageAt: -1, updatedAt: -1 });
    const summaries = await Promise.all(conversations.map((c) => conversationSummary(c, req.user._id)));
    res.json(summaries);
});

const createOrGetConversation = asyncHandler(async (req, res) => {
    const { participantId } = req.body;
    if (!participantId) {
        res.status(400);
        throw new Error('participantId is required');
    }
    const other = await findUserById(participantId);
    if (!other) {
        res.status(404);
        throw new Error('Participant not found');
    }
    const scope = academyScopeId(req.user);
    let conversation = await Conversation.findOne({
        kind: 'direct',
        managedBy: scope,
        'participants.userId': { $all: [req.user._id, other._id] },
        participants: { $size: 2 },
    });
    if (!conversation) {
        conversation = await Conversation.create({
            kind: 'direct',
            managedBy: scope,
            participants: [
                { userId: req.user._id, role: req.user.role },
                { userId: other._id, role: other.role },
            ],
            readBy: [
                { userId: req.user._id, lastReadAt: new Date() },
                { userId: other._id, lastReadAt: new Date(0) },
            ],
        });
    }
    res.status(201).json(await conversationSummary(conversation, req.user._id));
});

const getMessages = asyncHandler(async (req, res) => {
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation || !userInConversation(conversation, req.user._id)) {
        res.status(404);
        throw new Error('Conversation not found');
    }
    const messages = await Message.find({ conversationId: conversation._id })
        .sort({ createdAt: 1 })
        .limit(100);
    const otherRef = otherParticipant(conversation, req.user._id);
    const otherRead = conversation.readBy.find((r) => otherRef && `${r.userId}` === `${otherRef.userId}`);
    res.json({
        messages: messages.map((m) => ({
            _id: m._id,
            id: m._id,
            senderId: m.senderId,
            body: m.body,
            type: m.type,
            voiceUrl: m.voiceUrl,
            voiceDurationMs: m.voiceDurationMs,
            fileUrl: m.fileUrl,
            fileName: m.fileName,
            mimeType: m.mimeType,
            replyToMessageId: m.replyToMessageId,
            replyBody: m.replyBody,
            replySenderId: m.replySenderId,
            createdAt: m.createdAt,
        })),
        peerLastReadAt: otherRead?.lastReadAt || null,
    });
});

const sendMessage = asyncHandler(async (req, res) => {
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation || !userInConversation(conversation, req.user._id)) {
        res.status(404);
        throw new Error('Conversation not found');
    }
    const {
        body = '',
        type = 'text',
        voiceUrl,
        voiceDurationMs,
        fileUrl,
        fileName,
        mimeType,
        replyToMessageId,
    } = req.body;

    let replyBody;
    let replySenderId;
    if (replyToMessageId) {
        const replied = await Message.findById(replyToMessageId);
        if (replied) {
            replyBody = replied.body;
            replySenderId = replied.senderId;
        }
    }

    const preview = type === 'voice'
        ? '🎤 Voice message'
        : type === 'file'
            ? (fileName ? `📄 ${fileName}` : '📄 PDF report')
            : body;

    const message = await Message.create({
        conversationId: conversation._id,
        senderId: req.user._id,
        body: body || preview,
        type,
        voiceUrl,
        voiceDurationMs,
        fileUrl,
        fileName,
        mimeType,
        replyToMessageId,
        replyBody,
        replySenderId,
    });

    conversation.lastMessagePreview = preview;
    conversation.lastMessageAt = message.createdAt;
    await conversation.save();

    const payload = {
        _id: message._id,
        id: message._id,
        conversationId: conversation._id,
        senderId: message.senderId,
        body: message.body,
        type: message.type,
        voiceUrl: message.voiceUrl,
        voiceDurationMs: message.voiceDurationMs,
        fileUrl: message.fileUrl,
        fileName: message.fileName,
        mimeType: message.mimeType,
        replyToMessageId: message.replyToMessageId,
        replyBody: message.replyBody,
        replySenderId: message.replySenderId,
        createdAt: message.createdAt,
    };

    await emitMessageNew(req.io, conversation._id, payload);

    const otherRef = otherParticipant(conversation, req.user._id);
    if (otherRef) {
        await createNotification(req.io, {
            userId: otherRef.userId,
            title: 'New message',
            message: preview,
            type: 'message',
            managedBy: conversation.managedBy,
            relatedUserId: req.user._id,
        });
    }

    res.status(201).json(payload);
});

const markRead = asyncHandler(async (req, res) => {
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation || !userInConversation(conversation, req.user._id)) {
        res.status(404);
        throw new Error('Conversation not found');
    }
    const idx = conversation.readBy.findIndex((r) => `${r.userId}` === `${req.user._id}`);
    if (idx >= 0) {
        conversation.readBy[idx].lastReadAt = new Date();
    } else {
        conversation.readBy.push({ userId: req.user._id, lastReadAt: new Date() });
    }
    await conversation.save();
    if (req.io) {
        const otherRef = otherParticipant(conversation, req.user._id);
        req.io.emit('CONVERSATION_READ', {
            conversationId: `${conversation._id}`,
            readerUserId: `${req.user._id}`,
            lastReadAt: new Date().toISOString(),
            peerUserId: otherRef ? `${otherRef.userId}` : null,
        });
    }
    res.json({ ok: true });
});

module.exports = {
    getEligibleContacts,
    listConversations,
    createOrGetConversation,
    getMessages,
    sendMessage,
    markRead,
};
