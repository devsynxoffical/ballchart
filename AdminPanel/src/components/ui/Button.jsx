import React from 'react';
import { motion } from 'framer-motion';
import { Loader2 } from 'lucide-react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export const Button = ({
    children,
    variant = 'primary',
    isLoading,
    className,
    ...props
}) => {
    const baseStyles = "px-6 py-3 rounded-xl font-bold transition-all duration-300 transform active:scale-95 flex items-center justify-center gap-2";

    const variants = {
        primary: "bg-primary text-white shadow-glow hover:bg-primary-hover",
        secondary: "bg-secondary text-black shadow-glow-blue hover:brightness-110",
        outline: "border-2 border-primary text-primary hover:bg-primary/10",
        ghost: "text-text hover:bg-white/5",
    };

    return (
        <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className={twMerge(baseStyles, variants[variant], className)}
            disabled={isLoading}
            {...props}
        >
            {isLoading ? <Loader2 className="animate-spin" /> : children}
        </motion.button>
    );
};
