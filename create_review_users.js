const https = require('https');

const BASE_URL = 'https://ballchart-production.up.railway.app/api';

async function post(endpoint, data) {
    return new Promise((resolve, reject) => {
        const url = new URL(`${BASE_URL}${endpoint}`);
        const body = JSON.stringify(data);

        const options = {
            hostname: url.hostname,
            path: url.pathname,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(body),
            },
        };

        const req = https.request(options, (res) => {
            let resBody = '';
            res.on('data', (chunk) => resBody += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(resBody);
                    resolve({ statusCode: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ statusCode: res.statusCode, raw: resBody });
                }
            });
        });

        req.on('error', (err) => reject(err));
        req.write(body);
        req.end();
    });
}

async function createAndVerify() {
    console.log('🚀 Creating live demo users on Railway backend...');

    const users = [
        {
            role: 'admin',
            signupUrl: '/auth/admin/signup',
            loginUrl: '/auth/admin/login',
            payload: {
                username: 'BallChart Admin',
                email: 'admin.review@ballchart.com',
                password: 'BallChart2026!',
                academyName: 'BallChart Elite Academy'
            }
        },
        {
            role: 'coach',
            signupUrl: '/auth/coach/signup',
            loginUrl: '/auth/coach/login',
            payload: {
                username: 'Coach Jordan',
                email: 'coach.review@ballchart.com',
                password: 'BallChart2026!',
                academyName: 'BallChart Elite Academy'
            }
        },
        {
            role: 'player',
            signupUrl: '/auth/player/signup',
            loginUrl: '/auth/player/login',
            payload: {
                username: 'Alex Rivera',
                email: 'player.review@ballchart.com',
                password: 'BallChart2026!',
                academyName: 'BallChart Elite Academy'
            }
        }
    ];

    for (const u of users) {
        console.log(`\n---------------------------------------`);
        console.log(`Checking / Creating ${u.role.toUpperCase()} (${u.payload.email})...`);

        // First attempt login in case already exists
        const loginCheck = await post(u.loginUrl, {
            email: u.payload.email,
            password: u.payload.password
        });

        if (loginCheck.statusCode === 200) {
            console.log(`✅ ${u.role.toUpperCase()} already exists and login verified!`);
        } else {
            // Attempt signup
            const signupRes = await post(u.signupUrl, u.payload);
            console.log(`Signup Response (${signupRes.statusCode}):`, signupRes.data || signupRes.raw);

            // Verify login after signup
            const verifyLogin = await post(u.loginUrl, {
                email: u.payload.email,
                password: u.payload.password
            });
            if (verifyLogin.statusCode === 200) {
                console.log(`✅ ${u.role.toUpperCase()} registered & login verified successfully!`);
            } else {
                console.error(`❌ ${u.role.toUpperCase()} login failed after signup:`, verifyLogin.data || verifyLogin.raw);
            }
        }
    }
}

createAndVerify();
