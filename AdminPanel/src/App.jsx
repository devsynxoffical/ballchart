import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import DashboardLayout from './components/layout/DashboardLayout';
import Dashboard from './pages/Dashboard';
import UsersPage from './pages/UsersPage';
import { Loader2 } from 'lucide-react';
import { Toaster } from 'react-hot-toast';

const ProtectedRoute = ({ children }) => {
    const { user, loading } = useAuth();

    if (loading) {
        return (
            <div className="h-screen w-full flex items-center justify-center bg-background text-primary">
                <Loader2 className="animate-spin w-10 h-10" />
            </div>
        );
    }

    if (!user) {
        return <Navigate to="/login" />;
    }

    return children;
};

function App() {
    return (
        <Router>
            <AuthProvider>
                <Toaster position="top-right" toastOptions={{
                    style: {
                        background: '#1A1C20',
                        color: '#fff',
                        border: '1px solid rgba(255,255,255,0.1)',
                    }
                }} />
                <Routes>
                    <Route path="/login" element={<Login />} />

                    <Route path="/" element={
                        <ProtectedRoute>
                            <DashboardLayout />
                        </ProtectedRoute>
                    }>
                        <Route index element={<Navigate to="/dashboard" />} />
                        <Route path="dashboard" element={<Dashboard />} />
                        <Route path="coaches" element={<UsersPage type="coach" />} />
                        <Route path="players" element={<UsersPage type="player" />} />
                        <Route path="battles" element={<div className="p-8 text-center text-text-muted">Battles Management Coming Soon</div>} />
                        <Route path="tournaments" element={<div className="p-8 text-center text-text-muted">Tournaments Management Coming Soon</div>} />
                        <Route path="settings" element={<div className="p-8 text-center text-text-muted">Settings Coming Soon</div>} />
                    </Route>
                </Routes>
            </AuthProvider>
        </Router>
    );
}

export default App;
