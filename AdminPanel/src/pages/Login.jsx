import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { motion } from 'framer-motion';
import { Lock, Mail } from 'lucide-react';
import bgImage from '../assets/background.png';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        const result = await login(email, password);

        if (result.success) {
            navigate('/dashboard');
        } else {
            setError(result.message);
        }
        setLoading(false);
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-background relative overflow-hidden">
            {/* Background Elements */}
            <div className="absolute inset-0 z-0">
                <div className="absolute inset-0 bg-black/60 z-10" />
                <img src={bgImage} alt="Background" className="w-full h-full object-cover opacity-50" />
            </div>

            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="w-full max-w-md p-8 bg-surface/30 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl relative z-20"
            >
                <div className="text-center mb-10">
                    <motion.div
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        className="w-20 h-20 bg-primary rounded-full mx-auto mb-4 flex items-center justify-center shadow-glow"
                    >
                        <span className="text-3xl font-heading font-bold text-white">B</span>
                    </motion.div>
                    <motion.h1
                        initial={{ scale: 0.9 }}
                        animate={{ scale: 1 }}
                        className="text-4xl font-heading font-bold text-transparent bg-clip-text bg-gradient-to-r from-primary to-yellow-500 mb-2"
                    >
                        BALLCHART
                    </motion.h1>
                    <p className="text-text-muted">Admin Access Portal</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    {error && (
                        <div className="p-3 bg-danger/20 border border-danger/50 text-danger rounded-lg text-sm text-center">
                            {error}
                        </div>
                    )}

                    <div className="relative">
                        <Input
                            type="email"
                            placeholder="admin@ballchart.com"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            className="pl-10 bg-black/40"
                        />
                        <Mail className="absolute left-3 top-3.5 w-5 h-5 text-text-muted" />
                    </div>

                    <div className="relative">
                        <Input
                            type="password"
                            placeholder="••••••••"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            className="pl-10 bg-black/40"
                        />
                        <Lock className="absolute left-3 top-3.5 w-5 h-5 text-text-muted" />
                    </div>

                    <Button type="submit" className="w-full" isLoading={loading}>
                        Sign In to Dashboard
                    </Button>
                </form>
            </motion.div>
        </div>
    );
};

export default Login;
