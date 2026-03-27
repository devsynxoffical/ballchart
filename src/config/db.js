const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        const dbUri = process.env.MONGO_URI || process.env.MONGO_URL || process.env.DATABASE_URL;
        if (!dbUri) {
            throw new Error('MongoDB URI is not defined in environment variables (MONGO_URI, MONGO_URL, or DATABASE_URL)');
        }
        const conn = await mongoose.connect(dbUri); // No deprecated options needed in Mongoose 6+
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;
