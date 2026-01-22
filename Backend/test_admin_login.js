async function testLogin() {
    try {
        const response = await fetch('http://localhost:5000/api/auth/admin/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: 'admin@hoopstar.com',
                password: 'admin123'
            })
        });

        const data = await response.json();

        if (response.ok) {
            console.log('Login Successful!');
            console.log('Token:', data.token ? 'Received' : 'Missing');
            console.log('Role:', data.role);
        } else {
            console.error('Login Failed:', data);
        }
    } catch (err) {
        console.error('Request Error:', err.message);
    }
}

testLogin();
