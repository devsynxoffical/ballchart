import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Menu, X } from 'lucide-react';

const Navbar = () => {
    const [isScrolled, setIsScrolled] = useState(false);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 20);
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    const navLinks = [
        { name: 'Overview', href: '#overview' },
        { name: 'Features', href: '#features' },
        { name: 'Intelligence', href: '#stats' },
        { name: 'Contact', href: '#footer' },
    ];

    return (
        <nav className={`fixed top-0 w-full z-50 transition-all duration-500 ${isScrolled ? 'bg-background/90 backdrop-blur-xl py-4 border-b border-white/5' : 'bg-transparent py-8'}`}>
            <div className="max-w-7xl mx-auto px-6 flex items-center justify-between">
                <motion.div
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    className="flex items-center gap-3 group cursor-pointer"
                    onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
                >
                    <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center shadow-glow group-hover:scale-110 transition-transform">
                        <span className="text-black font-bold text-xl">B</span>
                    </div>
                    <span className="text-xl font-heading font-extrabold tracking-[0.2em] text-white">BALLCHART</span>
                </motion.div>

                {/* Desktop Links */}
                <div className="hidden md:flex items-center gap-10">
                    {navLinks.map((link, i) => (
                        <motion.a
                            key={link.name}
                            href={link.href}
                            initial={{ opacity: 0, y: -5 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: i * 0.05 }}
                            className="text-[10px] font-bold text-text-muted hover:text-primary transition-colors uppercase tracking-[0.3em]"
                        >
                            {link.name}
                        </motion.a>
                    ))}
                    <motion.button
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="px-8 py-3 bg-primary text-black font-bold rounded-xl hover:bg-primary-hover transition-all text-[10px] uppercase tracking-[0.2em]"
                    >
                        Access Portal
                    </motion.button>
                </div>

                {/* Mobile Toggle */}
                <button
                    className="md:hidden text-white p-2"
                    onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                >
                    {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
                </button>
            </div>

            {/* Mobile Menu */}
            <AnimatePresence>
                {isMobileMenuOpen && (
                    <motion.div
                        initial={{ opacity: 0, y: -20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -20 }}
                        className="md:hidden bg-background/95 backdrop-blur-2xl border-b border-white/5 absolute top-full left-0 w-full overflow-hidden"
                    >
                        <div className="flex flex-col p-8 gap-8">
                            {navLinks.map((link) => (
                                <a
                                    key={link.name}
                                    href={link.href}
                                    className="text-2xl font-heading font-bold text-white uppercase tracking-widest"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                >
                                    {link.name}
                                </a>
                            ))}
                            <button className="w-full py-5 bg-primary text-black font-bold rounded-2xl uppercase tracking-[0.2em] text-xs">
                                Access Portal
                            </button>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </nav>
    );
};

export default Navbar;
