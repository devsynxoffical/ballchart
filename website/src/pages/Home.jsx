import React from 'react';
import Navbar from '../components/layout/Navbar';
import Footer from '../components/layout/Footer';
import Hero from '../components/home/Hero';
import Features from '../components/home/Features';
import GameOverview from '../components/home/GameOverview';
import { motion } from 'framer-motion';
import { Apple, Smartphone } from 'lucide-react';

const Home = () => {
    return (
        <div className="bg-background min-h-screen selection:bg-primary selection:text-black scroll-smooth">
            <Navbar />
            <main>
                <Hero />

                <GameOverview />

                {/* Intelligence / Stats Highlight Banner */}
                <section id="stats" className="py-32 border-y border-white/5 bg-surface/10 relative overflow-hidden">
                    <div className="absolute inset-0 opacity-10 pointer-events-none" style={{ backgroundImage: 'radial-gradient(#ffffff 1px, transparent 1px)', backgroundSize: '20px 20px' }} />

                    <div className="max-w-7xl mx-auto px-6 grid grid-cols-2 lg:grid-cols-4 gap-16 text-center relative z-10">
                        {[
                            { label: 'System Nodes', value: '1.2M+' },
                            { label: 'Network Latency', value: '< 2ms' },
                            { label: 'Verified Analysts', value: '8.4k' },
                            { label: 'Success Rate', value: '99.9%' },
                        ].map((stat, i) => (
                            <motion.div
                                key={i}
                                initial={{ opacity: 0, y: 10 }}
                                whileInView={{ opacity: 1, y: 0 }}
                                viewport={{ once: true }}
                                transition={{ delay: i * 0.1 }}
                                className="space-y-3"
                            >
                                <h3 className="text-4xl md:text-5xl font-heading font-extrabold gradient-text tracking-tighter">{stat.value}</h3>
                                <p className="text-[10px] text-primary/60 uppercase tracking-[0.4em] font-bold font-sans">{stat.label}</p>
                            </motion.div>
                        ))}
                    </div>
                </section>

                <Features />

                {/* Professional CTA Section */}
                <section className="py-48 relative overflow-hidden">
                    <div className="max-w-4xl mx-auto px-6 text-center space-y-12 relative z-10">
                        <motion.div
                            initial={{ opacity: 0 }}
                            whileInView={{ opacity: 1 }}
                            className="w-16 h-0.5 bg-primary/40 mx-auto"
                        />
                        <motion.h2
                            initial={{ opacity: 0, scale: 0.98 }}
                            whileInView={{ opacity: 1, scale: 1 }}
                            className="text-5xl md:text-8xl font-heading font-extrabold text-white uppercase leading-[0.95] tracking-tighter italic"
                        >
                            READY TO <br />
                            <span className="text-primary text-glow">EVOLVE?</span>
                        </motion.h2>
                        <p className="text-text-muted text-xl max-w-xl mx-auto leading-relaxed font-medium">
                            Join the elite network of players and coaches redefining the basketball landscape through data intelligence.
                        </p>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 max-w-2xl mx-auto pt-8">
                            <button className="flex items-center justify-center gap-4 bg-primary text-black font-bold py-5 rounded-2xl hover:scale-[1.02] transition-all shadow-lg shadow-primary/20 group">
                                <Apple size={24} className="group-hover:scale-110 transition-transform" />
                                <div className="text-left">
                                    <p className="text-[10px] uppercase font-bold tracking-widest opacity-60">App Store</p>
                                    <p className="text-lg">Download for iOS</p>
                                </div>
                            </button>
                            <button className="flex items-center justify-center gap-4 bg-white/5 border border-white/10 text-white font-bold py-5 rounded-2xl hover:bg-white/10 transition-all group">
                                <Smartphone size={24} className="group-hover:scale-110 transition-transform" />
                                <div className="text-left">
                                    <p className="text-[10px] uppercase font-bold tracking-widest opacity-60">Play Store</p>
                                    <p className="text-lg">Download for Android</p>
                                </div>
                            </button>
                        </div>
                    </div>

                    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-primary/10 blur-[180px] rounded-full pointer-events-none" />
                </section>
            </main>
            <Footer />
        </div>
    );
};

export default Home;
