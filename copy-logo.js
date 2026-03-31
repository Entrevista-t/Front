const fs = require('fs');

const source = 'C:\\Users\\Kire\\Documents\\GitHub\\Front\\assets\\images\\logo_entrevistat.png';
const destinations = [
  'C:\\Users\\Kire\\Documents\\GitHub\\Front\\web\\favicon.png',
  'C:\\Users\\Kire\\Documents\\GitHub\\Front\\web\\icons\\Icon-192.png',
  'C:\\Users\\Kire\\Documents\\GitHub\\Front\\web\\icons\\Icon-512.png',
  'C:\\Users\\Kire\\Documents\\GitHub\\Front\\web\\icons\\Icon-maskable-192.png',
  'C:\\Users\\Kire\\Documents\\GitHub\\Front\\web\\icons\\Icon-maskable-512.png'
];

try {
  destinations.forEach((dest, index) => {
    fs.copyFileSync(source, dest);
    console.log(`✓ Copied to: ${dest}`);
  });
  console.log('\nAll files copied successfully!');
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
