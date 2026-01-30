import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import {
    LayoutDashboard,
    Users,
    Swords,
    Settings,
    LogOut,
    Menu,
    Trophy
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { clsx } from 'clsx';

const Sidebar = ({ isCollapsed, toggleSidebar }) => {
    const { logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const navItems = [
        { icon: LayoutDashboard, label: 'Dashboard', path: '/dashboard' },
        { icon: Users, label: 'Coaches', path: '/coaches' },
        { icon: Users, label: 'Players', path: '/players' },
        { icon: Swords, label: 'Battles', path: '/battles' },
        { icon: Trophy, label: 'Tournaments', path: '/tournaments' },
        { icon: Settings, label: 'Settings', path: '/settings' },
    ];

    return (
        <motion.div
            initial={false}
            animate={{ width: isCollapsed ? '80px' : '280px' }}
            className="h-screen bg-surface/80 backdrop-blur-xl border-r border-white/5 flex flex-col fixed left-0 top-0 z-50 transition-all duration-300 shadow-2xl"
        >
            <div className="p-6 flex items-center justify-between">
                <AnimatePresence mode='wait'>
                    {!isCollapsed && (
                        <motion.h1
                            initial={{ opacity: 0, width: 0 }}
                            animate={{ opacity: 1, width: 'auto' }}
                            exit={{ opacity: 0, width: 0 }}
                            className="text-2xl font-heading font-bold text-primary tracking-widest whitespace-nowrap overflow-hidden"
                        >
                            BALLCHART
                        </motion.h1>
                    )}
                </AnimatePresence>
                <button
                    onClick={toggleSidebar}
                    className="p-2 hover:bg-white/5 rounded-lg text-text-muted hover:text-white transition-colors"
                >
                    <Menu size={20} />
                </button>
            </div>

            <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto custom-scrollbar">
                {navItems.map((item) => (
                    <NavLink
                        key={item.path}
                        to={item.path}
                        className={({ isActive }) => clsx(
                            "flex items-center gap-4 px-4 py-3 rounded-xl transition-all duration-200 group relative overflow-hidden",
                            isActive
                                ? "bg-primary text-white shadow-glow"
                                : "text-text-muted hover:bg-white/5 hover:text-white"
                        )}
                    >
                        {({ isActive }) => (
                            <>
                                <item.icon size={22} className={clsx("relative z-10 flex-shrink-0", isActive ? "text-white" : "text-text-muted group-hover:text-white")} />
                                <AnimatePresence mode='wait'>
                                    {!isCollapsed && (
                                        <motion.span
                                            initial={{ opacity: 0, x: -10 }}
                                            animate={{ opacity: 1, x: 0 }}
                                            exit={{ opacity: 0, x: -10 }}
                                            className="font-medium relative z-10 whitespace-nowrap"
                                        >
                                            {item.label}
                                        </motion.span>
                                    )}
                                </AnimatePresence>
                            </>
                        )}
                    </NavLink>
                ))}
            </nav>

            <div className="p-4 border-t border-white/5">
                <button
                    onClick={handleLogout}
                    className="w-full flex items-center gap-4 px-4 py-3 text-danger hover:bg-danger/10 rounded-xl transition-all"
                >
                    <LogOut size={22} className="flex-shrink-0" />
                    <AnimatePresence>
                        {!isCollapsed && (
                            <motion.span
                                initial={{ opacity: 0 }}
                                animate={{ opacity: 1 }}
                                exit={{ opacity: 0 }}
                                className="font-medium whitespace-nowrap"
                            >
                                Logout
                            </motion.span>
                        )}
                    </AnimatePresence>
                </button>
            </div>
        </motion.div>
    );
};

export default Sidebar;
