import React from 'react';
import { motion } from 'framer-motion';
import { Twitter, Instagram, Github, Mail, ArrowUpRight } from 'lucide-react';

const Footer = () => {
    return (
        <footer id="footer" className="pt-32 pb-10 border-t border-white/5 bg-surface/20">
            <div className="max-w-7xl mx-auto px-6">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-20">
                    <div className="col-span-2 space-y-10">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
                                <span className="text-black font-extrabold text-xl">B</span>
                            </div>
                            <span className="text-xl font-heading font-extrabold tracking-[0.3em] text-white uppercase">BALLCHART</span>
                        </div>
                        <p className="text-sm text-text-muted max-w-xs leading-relaxed font-medium">
                            A high-fidelity intelligence platform for the professional basketball ecosystem. Redefining athlete performance through data.
                        </p>
                        <div className="flex items-center gap-4">
                            {[Twitter, Instagram, Github, Mail].map((Icon, i) => (
                                <a key={i} href="#" className="w-10 h-10 flex items-center justify-center rounded-lg border border-white/5 text-text-muted hover:text-primary hover:border-primary/40 transition-all bg-white/[0.02]">
                                    <Icon size={18} />
                                </a>
                            ))}
                        </div>
                    </div>

                    <div className="space-y-10">
                        <h4 className="text-xs font-bold text-white uppercase tracking-[0.4em]">Core Node</h4>
                        <ul className="space-y-5 text-[10px] text-text-muted uppercase tracking-[0.2em] font-bold">
                            <li><a href="#stats" className="hover:text-primary transition-colors">Intelligence</a></li>
                            <li><a href="#overview" className="hover:text-primary transition-colors">Operations</a></li>
                            <li><a href="#overview" className="hover:text-primary transition-colors">Tactical</a></li>
                            <li><a href="#features" className="hover:text-primary transition-colors">Verification</a></li>
                        </ul>
                    </div>

                    <div className="space-y-10">
                        <h4 className="text-xs font-bold text-white uppercase tracking-[0.4em]">System</h4>
                        <ul className="space-y-5 text-[10px] text-text-muted uppercase tracking-[0.2em] font-bold">
                            <li><a href="#hero" className="hover:text-primary transition-colors">Protocol</a></li>
                            <li><a href="#hero" className="hover:text-primary transition-colors">Network</a></li>
                            <li><a href="#" className="hover:text-primary transition-colors">Terms</a></li>
                            <li><a href="#footer" className="hover:text-primary transition-colors">Support</a></li>
                        </ul>
                    </div>
                </div>

                <div className="pt-12 border-t border-white/5 flex flex-col md:flex-row items-center justify-between gap-10">
                    <p className="text-[9px] text-text-muted/40 uppercase tracking-[0.5em] font-bold">
                        © 2026 BALLCHART CORE INTEL. ALL RIGHTS RESERVED.
                    </p>
                    <div
                        onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
                        className="flex items-center gap-4 text-[10px] text-primary/60 font-bold uppercase tracking-[0.3em] cursor-pointer hover:text-primary transition-colors"
                    >
                        Terminal Return <ArrowUpRight size={14} />
                    </div>
                </div>
            </div>
        </footer>
    );
};

export default Footer;
