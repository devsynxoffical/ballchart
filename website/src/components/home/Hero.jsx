import React from 'react';
import { motion } from 'framer-motion';
import { ArrowRight, Activity, Users, Shield } from 'lucide-react';
import heroImg from '../../assets/hero_v3.png';
import gamingImg from '../../assets/hero.png';

const Hero = () => {
    return (
        <section id="hero" className="relative h-screen flex items-center overflow-hidden bg-background">
            {/* Premium Background Arena Imagery */}
            <div className="absolute inset-0 z-0 opacity-40">
                <img
                    src={heroImg}
                    alt="BallChart Arena"
                    className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-r from-background via-background/60 to-transparent" />
                <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-background/40" />
            </div>

            {/* Abstract Background Elements */}
            <div className="absolute inset-0 z-0 opacity-15 pointer-events-none">
                <div className="absolute top-0 right-0 w-[800px] h-[800px] bg-primary/20 blur-[180px] rounded-full -translate-y-1/2 translate-x-1/2" />

                {/* Animated Grid lines */}
                <div className="absolute inset-0" style={{ backgroundImage: 'linear-gradient(to right, #ffffff03 1px, transparent 1px), linear-gradient(to bottom, #ffffff03 1px, transparent 1px)', backgroundSize: '50px 50px' }} />
            </div>

            <div className="max-w-7xl mx-auto px-8 relative z-10 w-full grid grid-cols-1 lg:grid-cols-2 gap-16 items-center h-full">
                {/* Left Side: High-Impact Visual */}
                <motion.div
                    initial={{ opacity: 0, x: -50 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 1, ease: "easeOut" }}
                    className="relative hidden lg:block h-[70vh]"
                >
                    <div className="absolute inset-2 bg-primary/10 blur-[100px] rounded-full" />

                    <div className="relative h-full w-full rounded-[2.5rem] overflow-hidden border border-white/10 shadow-3xl group">
                        <img
                            src={gamingImg}
                            alt="Elite Performance"
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-[3000ms]"
                        />
                        <div className="absolute inset-0 bg-gradient-to-t from-background/80 via-transparent to-transparent" />

                        {/* Decorative UI elements for "Professional" feel */}
                        <div className="absolute top-10 left-10 p-4 glass-card border-white/5 backdrop-blur-xl">
                            <div className="flex items-center gap-3">
                                <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                                <span className="text-[10px] font-bold text-white/70 uppercase tracking-widest">Live Engine Active</span>
                            </div>
                        </div>
                    </div>
                </motion.div>

                {/* Right Side: Content */}
                <div className="space-y-8 lg:pl-16">
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="inline-flex items-center gap-3 px-5 py-2 rounded-full bg-primary/5 border border-primary/20 text-primary text-[10px] font-bold uppercase tracking-[0.3em]"
                    >
                        <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
                        Next-Gen Sports Analytics
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, y: 30 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.1 }}
                        className="space-y-4"
                    >
                        <h1 className="text-5xl md:text-7xl font-heading font-bold text-white leading-[1.1] tracking-tight">
                            ELEVATE <br />
                            <span className="gradient-text">YOUR CORE.</span>
                        </h1>
                        <div className="h-1 w-24 bg-primary rounded-full" />
                    </motion.div>

                    <motion.p
                        initial={{ opacity: 0, y: 30 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.2 }}
                        className="text-base md:text-lg text-text-muted max-w-xl leading-relaxed font-medium"
                    >
                        Dominate the competition with the world's most advanced basketball intelligence platform. Designed for elite athletes, scouts, and performance professionals.
                    </motion.p>

                    <motion.div
                        initial={{ opacity: 0, y: 30 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.3 }}
                        className="flex flex-col sm:flex-row items-center gap-5 pt-4"
                    >
                        <a href="#overview" className="btn-primary px-10 py-4 rounded-xl text-xs font-bold tracking-[0.2em] uppercase text-center shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all duration-500">
                            Explore Assets <ArrowRight size={16} />
                        </a>
                        <button className="px-10 py-4 rounded-xl border border-white/10 text-white font-bold hover:bg-white/5 transition-all text-xs tracking-[0.2em] uppercase">
                            Join Network
                        </button>
                    </motion.div>
                </div>
            </div>

            {/* Subtle Scroll Indicator */}
            <div className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-4 text-text-muted opacity-20">
                <span className="text-[10px] font-bold uppercase tracking-[0.4em]">System Core</span>
                <div className="w-[1px] h-12 bg-gradient-to-b from-primary to-transparent" />
            </div>
        </section>
    );
};

export default Hero;
