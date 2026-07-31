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
    return conversation.participants.find((p) => `${p.userId}` !== `${userId}`);
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

function addId(set, raw) {
    if (!raw) return;
    const id = `${raw._id || raw}`;
    if (id && id !== 'undefined' && id !== 'null') set.add(id);
}

/** Collect every coach + player id on a team roster. */
function collectTeamMemberIds(team) {
    const ids = new Set();
    addId(ids, team.headCoach);
    addId(ids, team.coachStaffId);
    addId(ids, team.assistantCoachStaffId);
    for (const c of team.coachingStaff || []) addId(ids, c);
    for (const p of team.players || []) addId(ids, p);
    return [...ids];
}

function userOnTeam(team, userId) {
    return collectTeamMemberIds(team).includes(`${userId}`);
}

async function conversationSummary(conversation, userId) {
    const unreadCount = await unreadForUser(conversation, userId);
    let other = null;
    // Team chats use teamName in the client — skip picking a random "other".
    if (conversation.kind !== 'team') {
        const otherRef = otherParticipant(conversation, userId);
        if (otherRef) {
            const found = await findUserById(otherRef.userId);
            if (found) other = participantDto(found);
        }
    }
    return {
        _id: conversation._id,
        id: conversation._id,
        kind: conversation.kind || 'direct',
        teamId: conversation.teamId,
        teamName: conversation.teamName,
        lastMessagePreview: conversation.lastMessagePreview || '',
        lastMessageAt: conversation.lastMessageAt,
        unreadCount,
        unread: unreadCount,
        other,
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

async function buildParticipantsFromIds(ids) {
    const participants = [];
    const readBy = [];
    for (const id of ids) {
        const user = await findUserById(id);
        if (!user) continue;
        participants.push({ userId: user._id, role: user.role || 'player' });
        readBy.push({ userId: user._id, lastReadAt: new Date(0) });
    }
    return { participants, readBy };
}

/**
 * Create or refresh a whole-team conversation so production clients with
 * existing team-chat UI start seeing group threads without an app update.
 */
async function ensureTeamConversation(team, scope) {
    const memberIds = collectTeamMemberIds(team);
    if (!memberIds.length) return null;

    let conversation = await Conversation.findOne({
        kind: 'team',
        managedBy: scope,
        teamId: team._id,
    });

    const { participants, readBy } = await buildParticipantsFromIds(memberIds);
    if (!participants.length) return null;

    if (!conversation) {
        conversation = await Conversation.create({
            kind: 'team',
            teamId: team._id,
            teamName: team.name || 'Team chat',
            managedBy: scope,
            participants,
            readBy,
            lastMessagePreview: '',
        });
        return conversation;
    }

    conversation.teamName = team.name || conversation.teamName || 'Team chat';
    const prevRead = new Map(
        (conversation.readBy || []).map((r) => [`${r.userId}`, r.lastReadAt])
    );
    conversation.participants = participants;
    conversation.readBy = participants.map((p) => ({
        userId: p.userId,
        lastReadAt: prevRead.get(`${p.userId}`) || new Date(0),
    }));
    await conversation.save();
    return conversation;
}

async function teamsVisibleToUser(req) {
    const scope = academyScopeId(req.user);
    const uid = `${req.user._id}`;
    const role = (req.user.role || '').toLowerCase();

    if (role === 'admin') {
        return Team.find({ managedBy: scope });
    }

    const teams = await Team.find({ managedBy: scope });
    return teams.filter((t) => userOnTeam(t, uid));
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

    // Backend-only enablement: auto-create team group chats for rosters the
    // user belongs to. Existing app UI already renders kind:"team".
    try {
        const teams = await teamsVisibleToUser(req);
        await Promise.all(teams.map((t) => ensureTeamConversation(t, scope)));
    } catch (_) {
        // Listing must still succeed if sync fails.
    }

    const conversations = await Conversation.find({
        managedBy: scope,
        'participants.userId': req.user._id,
    }).sort({ lastMessageAt: -1, updatedAt: -1 });
    const summaries = await Promise.all(conversations.map((c) => conversationSummary(c, req.user._id)));
    res.json(summaries);
});

const createOrGetConversation = asyncHandler(async (req, res) => {
    const { participantId, teamId } = req.body || {};

    // Optional: newer clients can open a specific team chat explicitly.
    if (teamId) {
        const scope = academyScopeId(req.user);
        const team = await Team.findOne({ _id: teamId, managedBy: scope });
        if (!team) {
            res.status(404);
            throw new Error('Team not found');
        }
        const role = (req.user.role || '').toLowerCase();
        if (role !== 'admin' && !userOnTeam(team, req.user._id)) {
            res.status(403);
            throw new Error('You are not on this team');
        }
        const conversation = await ensureTeamConversation(team, scope);
        if (!conversation) {
            res.status(400);
            throw new Error('Team has no members yet');
        }
        if (!userInConversation(conversation, req.user._id)) {
            res.status(403);
            throw new Error('You are not in this team chat');
        }
        return res.status(201).json(await conversationSummary(conversation, req.user._id));
    }

    if (!participantId) {
        res.status(400);
        throw new Error('participantId or teamId is required');
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

    const participants = [];
    for (const p of conversation.participants || []) {
        const user = await findUserById(p.userId);
        if (user) participants.push(participantDto(user));
    }

    const otherRef = otherParticipant(conversation, req.user._id);
    const otherRead = conversation.readBy.find((r) => otherRef && `${r.userId}` === `${otherRef.userId}`);
    res.json({
        messages: messages.map((m) => ({
            _id: m._id,
            id: m._id,
            senderId: `${m.senderId}`,
            body: m.body,
            type: m.type,
            voiceUrl: m.voiceUrl,
            voiceDurationMs: m.voiceDurationMs,
            fileUrl: m.fileUrl,
            fileName: m.fileName,
            mimeType: m.mimeType,
            replyToMessageId: m.replyToMessageId ? `${m.replyToMessageId}` : undefined,
            replyBody: m.replyBody,
            replySenderId: m.replySenderId ? `${m.replySenderId}` : undefined,
            createdAt: m.createdAt,
        })),
        peerLastReadAt: otherRead?.lastReadAt || null,
        participants,
        kind: conversation.kind,
        teamId: conversation.teamId,
        teamName: conversation.teamName,
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
        conversationId: `${conversation._id}`,
        senderId: `${message.senderId}`,
        body: message.body,
        type: message.type,
        voiceUrl: message.voiceUrl,
        voiceDurationMs: message.voiceDurationMs,
        fileUrl: message.fileUrl,
        fileName: message.fileName,
        mimeType: message.mimeType,
        replyToMessageId: message.replyToMessageId ? `${message.replyToMessageId}` : undefined,
        replyBody: message.replyBody,
        replySenderId: message.replySenderId ? `${message.replySenderId}` : undefined,
        createdAt: message.createdAt,
    };

    await emitMessageNew(req.io, conversation._id, payload);

    // Notify every other member for team chats (not just one peer).
    const recipients = (conversation.participants || [])
        .map((p) => p.userId)
        .filter((id) => `${id}` !== `${req.user._id}`);

    const title = conversation.kind === 'team'
        ? (conversation.teamName ? conversation.teamName : 'Team message')
        : 'New message';

    await Promise.all(
        recipients.map((userId) =>
            createNotification(req.io, {
                userId,
                title,
                message: preview,
                type: 'message',
                managedBy: conversation.managedBy,
                relatedUserId: req.user._id,
            })
        )
    );

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

    await Notification.updateMany(
        {
            userId: req.user._id,
            isRead: false,
            type: { $in: ['message', 'chat', 'message_received'] },
        },
        { isRead: true }
    );

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
