const fs = require('fs');
const manifest = [];
const filenames = process.argv.slice(2);

filenames.forEach(f => {
    console.log(f);
    const data = JSON.parse(fs.readFileSync(f));
    data['id'] = f.slice(0, -5);
    manifest.push(data);
});

fs.writeFileSync('cloud/data.json', JSON.stringify(manifest));
