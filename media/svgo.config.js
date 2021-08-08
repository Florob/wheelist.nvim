const { extendDefaultPlugins } = require('svgo');
module.exports = {
  plugins: extendDefaultPlugins([
    {
      name: 'minifyStyles',
      active: false
    }
  ])
}
