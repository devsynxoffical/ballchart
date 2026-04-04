/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                primary: '#DAA520', // Goldenrod
                'primary-hover': '#B8860B',
                background: '#0B0C0E', // Deeper obsidian
                surface: '#15171C', // Soft gray-dark for cards
                text: '#F8FAFC',
                'text-muted': '#94A3B8',
                secondary: '#0EA5E9', // Professional Blue/Cyan
            },
            fontFamily: {
                sans: ['Inter', 'sans-serif'],
                heading: ['Outfit', 'sans-serif'],
            },
            boxShadow: {
                'glow': '0 0 20px rgba(218, 165, 32, 0.3)',
            }
        },
    },
    plugins: [],
}
