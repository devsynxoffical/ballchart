const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
    getEligibleContacts,
    listConversations,
    createOrGetConversation,
    getMessages,
    sendMessage,
    markRead,
    getPresence,
} = require('../controllers/messagingController');

router.get('/eligible-contacts', protect, getEligibleContacts);
router.get('/presence', protect, getPresence);
router.get('/conversations', protect, listConversations);
router.post('/conversations', protect, createOrGetConversation);
router.get('/conversations/:id/messages', protect, getMessages);
router.post('/conversations/:id/messages', protect, sendMessage);
router.post('/conversations/:id/read', protect, markRead);

module.exports = router;
