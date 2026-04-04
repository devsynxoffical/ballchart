const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
const http = require('http');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cors());

// Mock data for testing
const mockUsers = {
    admin: {
        _id: 'admin1',
        username: 'test_admin',
        email: 'admin@test.com',
        role: 'admin',
        academyName: 'Test Academy',
        profileCompleted: true
    },
    coach: {
        _id: 'coach1', 
        username: 'test_coach',
        email: 'coach@test.com',
        role: 'coach',
        profileCompleted: true
    },
    player: {
        _id: 'player1',
        username: 'test_player', 
        email: 'player@test.com',
        role: 'player',
        profileCompleted: true
    }
};

// Make io available in req
app.use((req, res, next) => {
    req.io = io;
    next();
});

// Routes
app.get('/', (req, res) => {
    res.send('BallChart Backend Test Server is running!');
});

// Auth routes
app.post('/api/auth/admin/login', (req, res) => {
    const { email, password } = req.body;
    if (email === 'admin@test.com' && password === 'password123') {
        res.json({
            ...mockUsers.admin,
            token: 'mock_admin_token'
        });
    } else {
        res.status(400).json({ message: 'Invalid Admin credentials' });
    }
});

app.post('/api/auth/coach/login', (req, res) => {
    const { email, password } = req.body;
    if (email === 'coach@test.com' && password === 'password123') {
        res.json({
            ...mockUsers.coach,
            token: 'mock_coach_token'
        });
    } else {
        res.status(400).json({ message: 'Invalid Coach credentials' });
    }
});

app.post('/api/auth/player/login', (req, res) => {
    const { email, password } = req.body;
    if (email === 'player@test.com' && password === 'password123') {
        res.json({
            ...mockUsers.player,
            token: 'mock_player_token'
        });
    } else {
        res.status(400).json({ message: 'Invalid Player credentials' });
    }
});

app.get('/api/auth/profile', (req, res) => {
    // Mock profile endpoint
    res.json(mockUsers.admin);
});

app.get('/api/auth/admin/overview', (req, res) => {
    res.json({
        admin: mockUsers.admin,
        staff: [mockUsers.coach],
        teams: [{
            _id: 'team1',
            name: 'Test Team',
            ageGroup: 'Open',
            colorValue: 0xFFF59E0B,
            players: [mockUsers.player]
        }]
    });
});

app.get('/api/auth/dashboard/coach', (req, res) => {
    res.json({
        profile: mockUsers.coach,
        teams: [{
            _id: 'team1',
            name: 'Test Team',
            ageGroup: 'Open',
            colorValue: 0xFFF59E0B,
            players: [mockUsers.player]
        }],
        staff: [mockUsers.coach]
    });
});

app.get('/api/auth/dashboard/player', (req, res) => {
    res.json({
        profile: mockUsers.player,
        team: {
            _id: 'team1',
            name: 'Test Team',
            players: [mockUsers.player]
        },
        coachingStaff: [mockUsers.coach],
        teammates: []
    });
});

// Battle routes
app.get('/api/battles', (req, res) => {
    res.json([
        {
            _id: 'battle1',
            location: 'Test Court',
            dateTime: new Date().toISOString(),
            status: 'pending',
            hostId: 'admin1',
            participants: []
        }
    ]);
});

// Socket.io Connection
io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
    console.log(`Test server running on port ${PORT}`);
    console.log('Test credentials:');
    console.log('Admin: admin@test.com / password123');
    console.log('Coach: coach@test.com / password123');
    console.log('Player: player@test.com / password123');
});
