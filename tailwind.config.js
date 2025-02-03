module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        customblue: '#174397',
        customred: '#FF5758',
        header: '#65BBE9',
        footer: '#E5E7EB',
        button: '#13253c',
      },
      fontFamily: {
        Bungee: ['Bungee', 'cursive'],
        DelaGothicOne: ['DelaGothicOne', 'cursive'],
      },
      spacing: {
        '72': '18rem',           // カスタムの余白サイズの追加
      },
      borderRadius: {
        'xl': '1.5rem',          // カスタムのボーダー半径
      },
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: false,
  },
};