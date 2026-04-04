import React from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export const Input = ({ label, className, error, ...props }) => {
    return (
        <div className="w-full space-y-2">
            {label && <label className="text-sm font-medium text-text-muted uppercase tracking-wider">{label}</label>}
            <input
                className={twMerge(
                    "w-full px-4 py-3 bg-surface/50 border border-white/10 rounded-xl focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all text-white placeholder-white/20",
                    error && "border-danger focus:border-danger focus:ring-danger",
                    className
                )}
                {...props}
            />
            {error && <p className="text-xs text-danger">{error}</p>}
        </div>
    );
};
