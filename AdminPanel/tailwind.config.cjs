module.exports = {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                background: '#0F1012', // Deep charcoal/black
                surface: '#1A1C20', // Slightly lighter for cards
                primary: '#DAA520', // Goldenrod
                'primary-hover': '#B8860B', // Dark Goldenrod
                secondary: '#00BCD4', // Cyan/Teal
                text: '#E0E0E0',
                'text-muted': '#A0A0A0',
                success: '#4CAF50',
                danger: '#F44336',
                warning: '#FFD700', // Gold as warning
            },
            fontFamily: {
                sans: ['Inter', 'sans-serif'],
                heading: ['Oswald', 'sans-serif'], // Or similar strong font
            },
            boxShadow: {
                'glow': '0 0 12px rgba(218, 165, 32, 0.4)',
                'glow-blue': '0 0 10px rgba(0, 188, 212, 0.5)',
            }
        },
    },
    plugins: [],
}
