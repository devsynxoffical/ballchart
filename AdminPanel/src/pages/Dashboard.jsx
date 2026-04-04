import React from 'react';
import { Users, Swords, Trophy, Activity } from 'lucide-react';
import StatsCard from '../components/dashboard/StatsCard';
import ActivityChart from '../components/dashboard/ActivityChart';
import { motion } from 'framer-motion';

const Dashboard = () => {
    const stats = [
        { title: 'Total Players', value: '1,234', icon: Users, trend: 12, color: 'primary' },
        { title: 'Active Coaches', value: '56', icon: Activity, trend: 5, color: 'secondary' },
        { title: 'Battles Hosted', value: '892', icon: Swords, trend: 24, color: 'warning' },
        { title: 'Tournaments', value: '12', icon: Trophy, trend: -2, color: 'success' },
    ];

    return (
        <div className="space-y-8">
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {stats.map((stat, index) => (
                    <motion.div
                        key={index}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: index * 0.1 }}
                    >
                        <StatsCard {...stat} />
                    </motion.div>
                ))}
            </div>

            {/* Main Content Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Chart Section */}
                <motion.div
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.4 }}
                    className="lg:col-span-2 card"
                >
                    <div className="flex items-center justify-between mb-6">
                        <h3 className="text-xl font-bold text-white">Activity Overview</h3>
                        <select className="bg-white/5 border border-white/10 rounded-lg px-3 py-1 text-sm focus:outline-none">
                            <option>Last 7 Days</option>
                            <option>Last Month</option>
                            <option>Last Year</option>
                        </select>
                    </div>
                    <ActivityChart />
                </motion.div>

                {/* Recent Activity / Feed */}
                <motion.div
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.5 }}
                    className="card"
                >
                    <h3 className="text-xl font-bold text-white mb-6">Recent Battles</h3>
                    <div className="space-y-4">
                        {[1, 2, 3, 4, 5].map((_, i) => (
                            <div key={i} className="flex items-center gap-4 p-3 rounded-xl hover:bg-white/5 transition-colors cursor-pointer border border-transparent hover:border-white/5">
                                <div className="w-10 h-10 rounded-full bg-white/10 flex items-center justify-center">
                                    <Swords size={18} className="text-secondary" />
                                </div>
                                <div>
                                    <h4 className="font-bold text-white">Street Court Kings</h4>
                                    <p className="text-xs text-text-muted">2 mins ago • 5v5 Match</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </motion.div>
            </div>
        </div>
    );
};

export default Dashboard;
