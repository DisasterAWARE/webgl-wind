const PNG = require('pngjs').PNG;
const fs = require('fs');

const data = JSON.parse(fs.readFileSync('snow-depth/tmp.json'));
const name = process.argv[2];
const s = data['s']['messages'][0];

function getVariableValue(items, key) {
    return items.filter(function (item) {
        return item.key === key;
    })[0].value;
}

const width = getVariableValue(s, 'Ni');
const height = getVariableValue(s, 'Nj') - 1;
const sMinimum = getVariableValue(s, 'minimum');
const sMaximum = getVariableValue(s, 'maximum');

console.log('S Min: ' + sMinimum);
console.log('S Max: ' + sMaximum);

const sValues = getVariableValue(s, 'values');
const dataDate = getVariableValue(s, 'dataDate');
const dataTime = getVariableValue(s, 'dataTime');

// console.log(width, height);

const png = new PNG({
    colorType: 2,
    filterType: 4,
    width: width,
    height: height
});

for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {

        const i = (y * width + x) * 4;
        const k = y * width + (x + width / 2) % width;
        const snowDepth = sValues[k] || 0;
        // png.data[i] = Math.floor(255 * (uValues[k] - uMinimum) / (uMaximum - uMinimum));
        // png.data[i + 1] = Math.floor(255 * (vValues[k] - vMinimum) / (vMaximum - vMinimum));
        png.data[i] = 0;
        png.data[i + 1] = 0;
        png.data[i + 2] = 255 * snowDepth / 5;
        png.data[i + 3] = 255;

    }
}

png.pack().pipe(fs.createWriteStream('snow-depth/' + name + '.png'));

fs.writeFileSync('snow-depth/' + name + '.json', JSON.stringify({
    source: 'http://nomads.ncep.noaa.gov',
    date: formatDate(dataDate + '', dataTime),
    isBlueChannelEnabled: true,
    width: width,
    height: height,
    uMin: 0,
    uMax: 0,
    vMin: 0,
    vMax: 0,
    kMin: sMinimum,
    kMax: sMaximum
}, null, 2) + '\n');

function formatDate(date, time) {
    // Change to export in bash-compatible date
    const year = date.substr(0, 4);
    const month = date.substr(4, 2);
    const day = date.substr(6, 2);
    time = time.toString().padStart(4, "0");
    const hour = time.substr(0,2);
    const minutes = time.substr(2,2);
    return year + '-' + month + '-' + day + 'T' + hour + ':' + minutes + '+00:00';
}