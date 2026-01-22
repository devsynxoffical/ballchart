async function diagnoseLogin() {
    try {
        console.log("Attempting login...");
        const response = await fetch('http://localhost:5000/api/auth/admin/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: 'admin@hoopstar.com',
                password: 'admin123'
            })
        });

        const data = await response.json();
        console.log(`Status: ${response.status} ${response.statusText}`);
        console.log('Response Body:', JSON.stringify(data, null, 2));

    } catch (err) {
        console.error('Request Error:', err.message);
    }
}
diagnoseLogin();
