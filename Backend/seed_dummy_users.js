require('dotenv').config();

const bcrypt = require('bcryptjs'); // Import bcryptjs

const connectDB = require('./src/config/db');
const Coach = require('./src/models/Coach');
const Player = require('./src/models/Player');

async function seedDummyUsers() {
    try {
        await connectDB();

        console.log('Clearing existing coaches and players...');
        await Coach.deleteMany({});
        await Player.deleteMany({});

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt);

        const coaches = [
            {
                username: 'coach_jordan',
                email: 'coach.jordan@example.com',
                password: hashedPassword, // Use hashed password
                role: 'coach',
                experienceLevel: 'Expert',
                sports: ['Basketball'],
                achievements: ['State Champion', 'Coach of the Year'],
                additionalInfo: 'Specializes in offensive strategies.',
                teamName: 'HoopStars Elite',
                profileCompleted: true,
                isVerified: true,
            },
            {
                username: 'coach_lee',
                email: 'coach.lee@example.com',
                password: hashedPassword, // Use hashed password
                role: 'coach',
                experienceLevel: 'Intermediate',
                sports: ['Basketball', 'Fitness'],
                achievements: ['Regional Finalist'],
                additionalInfo: 'Focuses on player development and conditioning.',
                teamName: 'Downtown Ballers',
                profileCompleted: true,
                isVerified: false,
            },
        ];

        const players = [
            {
                username: 'player_ace',
                email: 'player.ace@example.com',
                password: hashedPassword,
                role: 'player',
                position: 'Point Guard',
                ageRange: '18-24',
                experienceLevel: 'Advanced',
                goals: ['Improve 3PT shooting', 'Increase assist rate'],
                additionalGoals: 'Get scouted for semi-pro league.',
                profileCompleted: true,
                isVerified: true,
                rank: 1,
                stats: {
                    matchesPlayed: 42,
                    wins: 30,
                    points: 780,
                },
            },
            {
                username: 'player_rookie',
                email: 'player.rookie@example.com',
                password: hashedPassword,
                role: 'player',
                position: 'Small Forward',
                ageRange: '16-18',
                experienceLevel: 'Beginner',
                goals: ['Build confidence', 'Improve defense'],
                additionalGoals: '',
                profileCompleted: false,
                isVerified: false,
                rank: 12,
                stats: {
                    matchesPlayed: 10,
                    wins: 4,
                    points: 120,
                },
            },
        ];

        console.log('Inserting dummy coaches and players...');
        await Coach.insertMany(coaches);
        await Player.insertMany(players);

        console.log('✅ Dummy coaches and players created successfully.');
        process.exit(0);
    } catch (err) {
        console.error('❌ Error seeding dummy users:', err.message);
        process.exit(1);
    }
}

seedDummyUsers();

