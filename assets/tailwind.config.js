import { calculateTypeScale, calculateSpaceScale } from './tailwind/fluid-type.js';


// EXAMINE HOW SMALLER SIZES ARE BEING COMPUTED
// FIX IT SO THAT SMALLER SIZES DONT GET SMALLER ON DESKTOP
// Spacing calculations seem very wrong and probably need to be rewritten
// Then stuff in app.css probably need to be ported here

  const typeConfig = {
    minWidth: 320,
    maxWidth: 1914,
    minFontSize: 18,
    maxFontSize: 18,
    minTypeScale: 1.2,      
    maxTypeScale: 1.414,  
    positiveSteps: 7,    
    negativeSteps: 2      
  };

  const spaceConfig = {
    minWidth: 320,
    maxWidth: 1440,
    minSize: 18,  // Example: 4px at 320px screen width
    maxSize: 18, // Example: 40px at 1440px screen width
    positiveSteps: [1, 2, 3, 4, 5, 6, 7, 8, 9], // Example positive steps
    negativeSteps: [1, 2], // Example negative steps
    relativeTo: 'viewport'
  };

  // Generate scales within the function
  const typeSizes = calculateTypeScale(typeConfig).map((size, index) => ({
    ...size,
    label: ['7xl', '6xl', '5xl', '4xl', '3xl', '2xl', '1xl', 'md', '1xs', '2xs'][index]
  }));
  console.log(typeSizes)
  const spaceSizes = calculateSpaceScale(spaceConfig);
  console.log(spaceSizes);
 

module.exports = {
  content: [
    '/app/assets/js/**/*.js',
    '/app/assets/css/**/*.css',
    '/app/lib/portfolio_web/**/*.*ex',
  ],
  corePlugins: {},
  plugins: [],
  theme: {
    fontSize: {
      "2xs":  [typeSizes.find(size => size.label === '2xs').clamp, 1.2],
      "1xs":  [typeSizes.find(size => size.label === '1xs').clamp, 1.2],
      "md":   ["var(--fs-base)", 1.5],
      "1xl":  [typeSizes.find(size => size.label === '1xl').clamp, 1.3],
      "2xl":  [typeSizes.find(size => size.label === '2xl').clamp, 1],
      "3xl":  [typeSizes.find(size => size.label === '3xl').clamp, 1],
      "4xl":  [typeSizes.find(size => size.label === '4xl').clamp, 1],
    }
  },
};