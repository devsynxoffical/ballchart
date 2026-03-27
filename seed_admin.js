async function seedAdmin() {
    try {
        const response = await fetch('http://localhost:5000/api/auth/admin/signup', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                username: 'admin_ballchart',
                email: 'admin@ballchart.com',
                password: 'admin123'
            })
        });

        const data = await response.json();

        if (response.ok) {
            console.log('Admin Created Successfully!');
            console.log('ID:', data._id);
        } else {
            console.error('Registration Failed:', data);
        }
    } catch (err) {
        console.error('Request Error:', err.message);
    }
}

seedAdmin();
