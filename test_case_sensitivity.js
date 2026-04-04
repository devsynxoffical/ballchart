const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Admin = require('./src/models/Admin');

dotenv.config();

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected');
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

const testCase = async () => {
    await connectDB();

    const emailLower = 'admin@hoopstar.com';
    const emailUpper = 'Admin@hoopstar.com';

    const adminLower = await Admin.findOne({ email: emailLower });
    console.log(`Searching for '${emailLower}':`, adminLower ? 'Found' : 'Not Found');

    const adminUpper = await Admin.findOne({ email: emailUpper });
    console.log(`Searching for '${emailUpper}':`, adminUpper ? 'Found' : 'Not Found');

    process.exit();
};

testCase();
