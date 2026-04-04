import React from 'react';
import { motion } from 'framer-motion';
import { clsx } from 'clsx';

const StatsCard = ({ title, value, icon: Icon, trend, color = 'primary' }) => {
    const colorVariants = {
        primary: 'from-primary/20 to-primary/5 text-primary border-primary/20',
        secondary: 'from-secondary/20 to-secondary/5 text-secondary border-secondary/20',
        success: 'from-success/20 to-success/5 text-success border-success/20',
        warning: 'from-warning/20 to-warning/5 text-warning border-warning/20',
    };

    return (
        <motion.div
            whileHover={{ y: -5 }}
            className={clsx(
                "relative overflow-hidden rounded-2xl p-6 border backdrop-blur-md bg-gradient-to-br",
                colorVariants[color]
            )}
        >
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-sm font-medium text-text-muted uppercase tracking-wider">{title}</p>
                    <h3 className="text-3xl font-bold mt-2 text-white">{value}</h3>
                </div>
                <div className={clsx("p-3 rounded-xl bg-white/5", `text-${color}`)}>
                    <Icon size={24} />
                </div>
            </div>

            {trend && (
                <div className="mt-4 flex items-center text-sm font-medium">
                    <span className={trend > 0 ? "text-success" : "text-danger"}>
                        {trend > 0 ? "+" : ""}{trend}%
                    </span>
                    <span className="text-text-muted ml-2">from last month</span>
                </div>
            )}

            {/* Background decoration */}
            <Icon className="absolute -bottom-4 -right-4 w-32 h-32 opacity-5 rotate-12" />
        </motion.div>
    );
};

export default StatsCard;
