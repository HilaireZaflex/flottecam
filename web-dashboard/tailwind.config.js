/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#1B4FD8', light: '#3B6EF0', dark: '#1338A0', 50: '#EEF2FF', 100: '#E0E7FF', 500: '#1B4FD8', 600: '#1338A0' },
        accent:  { DEFAULT: '#06B6D4' },
        success: { DEFAULT: '#10B981' },
        warning: { DEFAULT: '#F59E0B' },
        danger:  { DEFAULT: '#EF4444' },
      },
      fontFamily: { sans: ['Inter', 'system-ui', 'sans-serif'] },
      boxShadow: {
        card: '0 4px 20px rgba(27,79,216,0.08), 0 2px 6px rgba(0,0,0,0.04)',
        elevated: '0 8px 30px rgba(27,79,216,0.18)',
      },
    },
  },
  plugins: [],
}
