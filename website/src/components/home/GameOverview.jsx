import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Users, Clipboard, Target, LineChart, Shield, Swords, Zap, Layout, Search, BarChart3 } from 'lucide-react';

import strategyImg from '../../assets/strategy_v2.png';
import analyticsImg from '../../assets/battle_v3.png';

const StrategyMockup = () => (
    <div className="w-full h-full rounded-2xl border border-white/10 relative overflow-hidden group">
        <img src={strategyImg} alt="Coaching Strategy" className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-transparent opacity-60" />
        <div className="absolute bottom-6 left-6 right-6">
            <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-black">
                    <Clipboard size={20} />
                </div>
                <div>
                    <p className="text-white font-bold text-sm tracking-widest uppercase">Tactical Node</p>
                    <p className="text-text-muted text-[10px] uppercase font-bold">Strategic Distribution</p>
                </div>
            </div>
        </div>
    </div>
);

const AnalyticsMockup = () => (
    <div className="w-full h-full rounded-2xl border border-white/10 relative overflow-hidden group">
        <img src={analyticsImg} alt="Performance Analytics" className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-transparent opacity-60" />
        <div className="absolute bottom-6 left-6 right-6">
            <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-secondary flex items-center justify-center text-white">
                    <BarChart3 size={20} />
                </div>
                <div>
                    <p className="text-white font-bold text-sm tracking-widest uppercase">Intelligence Core</p>
                    <p className="text-text-muted text-[10px] uppercase font-bold">Real-time Telemetry</p>
                </div>
            </div>
        </div>
    </div>
);

const GameOverview = () => {
    const [activeTab, setActiveTab] = useState('players');

    const content = {
        players: {
            title: "PRECISE DATA. BETTER PERFORMANCE.",
            description: "BallChart transforms your physical activity into actionable data intelligence. The tools usually reserved for the elite are now in your hands.",
            features: [
                { icon: LineChart, title: "Biometric AI", desc: "Real-time analysis of movement patterns, shooting arc, and fatigue levels." },
                { icon: Swords, title: "Dynamic Battles", desc: "A sophisticated matchmaking engine connecting you with the right competition." },
                { icon: Target, title: "Verified Identity", desc: "Professional scouting profile with cryptographic stat verification." },
            ],
            mockup: <AnalyticsMockup />
        },
        coaches: {
            title: "STRATEGIC CONTROL. TEAM EXCELLENCE.",
            description: "Manage your entire roster with professional-grade tactical tools. Designed for high-performance team directors.",
            features: [
                { icon: Users, title: "Roster Management", desc: "Deep performance tracking for every athlete on your team from one dashboard." },
                { icon: Clipboard, title: "Tactical Board", desc: "Digital play creation with real-time distribution to your entire roster's HUD." },
                { icon: Shield, title: "Advanced Scouting", desc: "Data-driven talent discovery across the global BallChart network." },
            ],
            mockup: <StrategyMockup />
        }
    };

    return (
        <section id="overview" className="py-40 bg-background relative overflow-hidden">
            <div className="max-w-7xl mx-auto px-6">
                <div className="flex flex-col items-center mb-24">
                    <motion.div
                        initial={{ opacity: 0 }}
                        whileInView={{ opacity: 1 }}
                        className="text-xs font-bold text-primary tracking-[0.4em] uppercase mb-4"
                    >
                        System Architecture
                    </motion.div>
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        className="text-5xl md:text-7xl font-heading font-extrabold text-white uppercase text-center mb-12"
                    >
                        HOW THE SYSTEM <span className="gradient-text">OPERATES</span>
                    </motion.h2>

                    {/* Tab Selector */}
                    <div className="flex p-1.5 bg-surface border border-white/5 rounded-2xl">
                        {['players', 'coaches'].map((tab) => (
                            <button
                                key={tab}
                                onClick={() => setActiveTab(tab)}
                                className={`px-12 py-4 rounded-xl font-heading font-bold uppercase tracking-[0.2em] text-xs transition-all duration-500 ${activeTab === tab ? 'bg-primary text-black shadow-glow' : 'text-text-muted hover:text-white'}`}
                            >
                                For {tab}
                            </button>
                        ))}
                    </div>
                </div>

                <AnimatePresence mode="wait">
                    <motion.div
                        key={activeTab}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -20 }}
                        transition={{ duration: 0.5, ease: "circOut" }}
                        className="grid grid-cols-1 lg:grid-cols-2 gap-24 items-center"
                    >
                        <div className="space-y-12">
                            <div className="space-y-6">
                                <h3 className="text-4xl font-heading font-extrabold text-white tracking-tight leading-none uppercase italic underline decoration-primary/40 underline-offset-8">
                                    {content[activeTab].title}
                                </h3>
                                <p className="text-xl text-text-muted leading-relaxed font-medium">
                                    {content[activeTab].description}
                                </p>
                            </div>

                            <div className="grid gap-4">
                                {content[activeTab].features.map((feature, i) => (
                                    <motion.div
                                        key={i}
                                        initial={{ opacity: 0, x: -20 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        transition={{ delay: i * 0.1 }}
                                        className="flex gap-6 p-8 rounded-2xl bg-surface border border-white/5 hover:border-primary/20 transition-all duration-300 group"
                                    >
                                        <div className="w-12 h-12 rounded-xl bg-white/5 flex items-center justify-center text-primary group-hover:scale-110 transition-transform shrink-0">
                                            <feature.icon size={24} />
                                        </div>
                                        <div>
                                            <h4 className="text-lg font-heading font-bold text-white uppercase tracking-widest mb-2">{feature.title}</h4>
                                            <p className="text-sm text-text-muted leading-relaxed font-medium">{feature.desc}</p>
                                        </div>
                                    </motion.div>
                                ))}
                            </div>
                        </div>

                        <div className="relative group">
                            <div className={`absolute inset-0 blur-[150px] opacity-20 transition-colors duration-1000 ${activeTab === 'players' ? 'bg-primary' : 'bg-secondary'}`} />
                            <div className="relative z-10 p-4 bg-white/5 rounded-[3rem] border border-white/10 backdrop-blur-sm group-hover:scale-[1.02] transition-transform duration-700 aspect-[4/3]">
                                {content[activeTab].mockup}
                            </div>
                        </div>
                    </motion.div>
                </AnimatePresence>
            </div>
        </section>
    );
};

export default GameOverview;
