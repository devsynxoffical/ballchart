const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const User = require('./src/models/User');
const Coach = require('./src/models/Coach');

dotenv.config();

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/hoopstar');
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

const seedData = async () => {
    await connectDB();

    const salt = await bcrypt.genSalt(10);
    const password = await bcrypt.hash('password123', salt);

    const users = [
        {
            username: 'Head Coach User',
            email: 'headcoach@example.com',
            password: password,
            role: 'head_coach',
            teamName: 'Golden State Warriors',
        },
        {
            username: 'Assistant Coach User',
            email: 'asstcoach@example.com',
            password: password,
            role: 'assistant_coach',
            teamName: 'Golden State Warriors',
        },
        {
            username: 'Coach User',
            email: 'coach@example.com',
            password: password,
            role: 'coach',
            teamName: 'Chicago Bulls',
        },
    ];

    try {
        // Clear existing users with these emails to avoid duplicates
        await User.deleteMany({ email: { $in: users.map(u => u.email) } });
        await Coach.deleteMany({ email: { $in: users.map(u => u.email) } });

        for (const user of users) {
            // Create User entry
            const createdUser = await User.create(user);
            console.log(`Created User: ${createdUser.username}`);

            // Create Coach entry (since they are all types of coaches)
            await Coach.create({
                username: user.username,
                email: user.email,
                password: user.password, // hashed
                role: user.role, // specific role
                teamName: user.teamName,
                assignedTeams: [user.teamName, 'Development Squad'], // Dummy assigned teams
                profileCompleted: true,
            });
            console.log(`Created Coach Profile for: ${user.username}`);
        }

        console.log('Data Imported!');
        process.exit();
    } catch (error) {
        console.error(`${error}`);
        process.exit(1);
    }
};

seedData();
