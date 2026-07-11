const express = require('express');
const path = require('path');
const dotenv = require('dotenv');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const connectDB = require('./config/db');
const { Server } = require('socket.io');
const http = require('http');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*", // Allow all origins for now (Flutter app)
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cors());

// Connect to Database
connectDB();

const { notFound, errorHandler } = require('./middleware/errorMiddleware');

// Make io available in req
app.use((req, res, next) => {
    req.io = io;
    next();
});

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/', (_req, res) => {
    res.send('BallChart Backend is running!');
});

app.get('/health', (_req, res) => {
    res.status(200).json({ ok: true, service: 'ballchart-api' });
});

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/battles', require('./routes/battleRoutes'));
app.use('/api/strategies', require('./routes/strategyRoutes'));
app.use('/api/teams', require('./routes/teamRoutes'));
app.use('/api/messages', require('./routes/messagingRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/upload', require('./routes/uploadRoutes'));
app.use('/api/player-development', require('./routes/playerDevelopmentRoutes'));

app.use(notFound);
app.use(errorHandler);

io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) {
        next(new Error('Unauthorized'));
        return;
    }
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decoded.id;
        socket.userRole = decoded.role;
        next();
    } catch (err) {
        next(new Error('Unauthorized'));
    }
});

// Socket.io Connection
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id, socket.userId || '');

    socket.on('join_tactical_room', ({ battleId }) => {
        if (battleId) socket.join(`tactical:${battleId}`);
    });

    socket.on('TACTICAL_ANIMATION_FRAME', (payload) => {
        if (!payload || !payload.battleId) return;
        socket.to(`tactical:${payload.battleId}`).emit('TACTICAL_ANIMATION_FRAME', payload);
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
