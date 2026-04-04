import React, { useState } from 'react';
import Sidebar from './Sidebar';
import { Outlet } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useAuth } from '../../context/AuthContext';

const DashboardLayout = () => {
    const [isCollapsed, setIsCollapsed] = useState(false);
    const { user } = useAuth();

    return (
        <div className="min-h-screen bg-background text-text flex">
            <Sidebar isCollapsed={isCollapsed} toggleSidebar={() => setIsCollapsed(!isCollapsed)} />

            <motion.main
                initial={false}
                animate={{ marginLeft: isCollapsed ? '80px' : '280px' }}
                className="flex-1 p-8 transition-all duration-300 w-full"
            >
                <div className="max-w-7xl mx-auto">
                    {/* Header/Top bar could go here */}
                    <header className="mb-8 flex justify-between items-center">
                        <div>
                            <h2 className="text-2xl font-bold text-white">Welcome Back, {user?.username || 'Admin'}</h2>
                            <p className="text-text-muted">Manage academies, teams, coaches, and players from one panel.</p>
                        </div>
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center font-bold text-white shadow-glow">
                                {(user?.username?.[0] || 'A').toUpperCase()}
                            </div>
                        </div>
                    </header>
                    <Outlet />
                </div>
            </motion.main>
        </div>
    );
};

export default DashboardLayout;
