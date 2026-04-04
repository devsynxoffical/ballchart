const axios = require('axios');

async function testLogin() {
    try {
        console.log('Testing login with uppercase email: Admin@hoopstar.com');
        const response = await axios.post('http://localhost:5000/api/auth/admin/login', {
            email: 'Admin@hoopstar.com', // Uppercase
            password: 'admin123'
        });

        if (response.data.token) {
            console.log('Login Successful with uppercase email!');
            console.log('Token received.');
        } else {
            console.log('Login Failed: No token.');
        }
    } catch (err) {
        console.error('Login Error:', err.response?.data?.message || err.message);
    }
}

testLogin();
