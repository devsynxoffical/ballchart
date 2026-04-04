import React from 'react';
import { motion } from 'framer-motion';
import { Activity, Swords, Users, Trophy, Shield, Zap, Cpu, Globe, Gauge } from 'lucide-react';

const Features = () => {
    const cards = [
        {
            icon: Cpu,
            title: "Neural Core",
            description: "Advanced AI processing that interprets player movement into high-fidelity data points instantly.",
            color: "text-primary"
        },
        {
            icon: Globe,
            title: "Global Node",
            description: "A decentralized networking system connecting courts, players, and professional scouts globally.",
            color: "text-secondary"
        },
        {
            icon: Gauge,
            title: "Peak Performance",
            description: "Comprehensive health and performance tracking metrics to ensure athletes operate at their physical zenith.",
            color: "text-yellow-400"
        }
    ];

    const techFeatures = [
        { title: "Motion Vectoring", desc: "Track velocity and trajectory with sub-millimeter precision." },
        { title: "Tactical Sync", desc: "Instantly distribute strategies across a unified team network." },
        { title: "Scout Verification", desc: "Blockchain-backed stat validation for professional transparency." },
        { title: "Live Telemetry", desc: "Real-time performance broadcasting for coaching and analysis." }
    ];

    return (
        <section id="features" className="py-40 relative overflow-hidden bg-background">
            <div className="max-w-7xl mx-auto px-6">
                <div className="text-center space-y-6 mb-32">
                    <motion.div
                        initial={{ opacity: 0 }}
                        whileInView={{ opacity: 1 }}
                        className="text-[10px] font-bold text-primary tracking-[0.5em] uppercase"
                    >
                        Technical Capabilities
                    </motion.div>
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-5xl md:text-7xl font-heading font-extrabold text-white uppercase italic tracking-tighter"
                    >
                        THE CORE <span className="gradient-text">ENGINE.</span>
                    </motion.h2>
                    <p className="text-lg text-text-muted max-w-2xl mx-auto font-medium leading-relaxed">
                        Eliminating guesswork through uncompromising data precision. BallChart provides a professional infrastructure for the modern basketball ecosystem.
                    </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-40">
                    {cards.map((card, i) => (
                        <motion.div
                            key={i}
                            initial={{ opacity: 0, y: 30 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: i * 0.1 }}
                            className="group p-10 rounded-[2.5rem] bg-surface border border-white/5 hover:border-primary/20 transition-all duration-500 relative overflow-hidden"
                        >
                            <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 blur-[50px] rounded-full translate-x-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                            <div className={`w-14 h-14 rounded-2xl bg-background border border-white/5 flex items-center justify-center mb-10 group-hover:text-primary transition-colors duration-300`}>
                                <card.icon size={28} />
                            </div>
                            <h3 className="text-2xl font-heading font-bold text-white mb-6 uppercase tracking-widest">{card.title}</h3>
                            <p className="text-sm text-text-muted leading-relaxed font-medium">
                                {card.description}
                            </p>
                        </motion.div>
                    ))}
                </div>

                {/* Tech Grid Section */}
                <div className="glass-card !p-16 border-white/5 relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-full h-full opacity-5 pointer-events-none" style={{ backgroundImage: 'radial-gradient(#ffffff 1px, transparent 1px)', backgroundSize: '30px 30px' }} />

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-16 relative z-10">
                        {techFeatures.map((tech, i) => (
                            <motion.div
                                key={i}
                                initial={{ opacity: 0, x: i % 2 === 0 ? -20 : 20 }}
                                whileInView={{ opacity: 1, x: 0 }}
                                viewport={{ once: true }}
                                transition={{ delay: i * 0.1 }}
                                className="space-y-4"
                            >
                                <div className="h-0.5 w-12 bg-primary/40 mb-8" />
                                <h4 className="text-2xl font-heading font-bold text-white uppercase tracking-tight">{tech.title}</h4>
                                <p className="text-text-muted leading-relaxed font-medium">
                                    {tech.desc}
                                </p>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
};

export default Features;
