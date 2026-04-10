const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
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

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/battles', require('./routes/battleRoutes'));
app.use('/api/strategies', require('./routes/strategyRoutes'));
app.use('/api/teams', require('./routes/teamRoutes'));

// Make io available in req
app.use((req, res, next) => {
    req.io = io;
    next();
});

app.use(notFound);
app.use(errorHandler);

// Routes Placeholder
app.get('/', (req, res) => {
    res.send('BallChart Backend is running!');
});

// Socket.io Connection
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);

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
