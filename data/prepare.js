const PNG = require('pngjs').PNG;
const fs = require('fs');

const data = JSON.parse(fs.readFileSync('tmp.json'));
const name = process.argv[2];
const u = data["u"]["messages"][0];
const v = data["v"]["messages"][0];

console.log(u);
console.log(v);

function getVariableValue(items, key) {
    return items.filter(function (item) {
        return item.key === key;
    })[0].value;
}

const width = getVariableValue(u, 'Ni');
const height = getVariableValue(u, "Nj") - 1;
const uMinimum = getVariableValue(u, "minimum");
const uMaximum = getVariableValue(u, "maximum");
const vMinimum = getVariableValue(v, "minimum");
const vMaximum = getVariableValue(v, "maximum");

const uValues = getVariableValue(u, 'values');
const vValues = getVariableValue(v, 'values');

const dataDate = getVariableValue(u, 'dataDate');
const dataTime = getVariableValue(u, 'dataTime');

console.log(width, height);

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
        png.data[i + 0] = Math.floor(255 * (uValues[k] - uMinimum) / (uMaximum - uMinimum));
        png.data[i + 1] = Math.floor(255 * (vValues[k] - vMinimum) / (vMaximum - vMinimum));
        png.data[i + 2] = 0;
        png.data[i + 3] = 255;
    }
}

png.pack().pipe(fs.createWriteStream(name + '.png'));

fs.writeFileSync(name + '.json', JSON.stringify({
    source: 'http://nomads.ncep.noaa.gov',
    date: formatDate(dataDate + '', dataTime),
    width: width,
    height: height,
    uMin: uMinimum,
    uMax: uMaximum,
    vMin: vMinimum,
    vMax: vMaximum
}, null, 2) + '\n');

// const MPS_TO_MPH = 2.23694;
// const rgbPNG = PNG.sync.read(fs.readFileSync(name + '.png'));
// const windSpeedPNG = new PNG({
//     colorType: 2,
//     filterType: 4,
//     width: rgbPNG.width,
//     height: rgbPNG.height
// });

// const maxVelocity = Math.sqrt(Math.pow(uMaximum, 2) + Math.pow(vMaximum, 2));
// const maxVelocityMPH = maxVelocity * MPS_TO_MPH;
// const radius = 1; // Adjust this value to change the amount of smoothing
// const uValuesSmooth = movingAverage(uValues, radius);
// const vValuesSmooth = movingAverage(vValues, radius);
// const numPixels = uValuesSmooth.length;
//
// for (let i = 0; i < numPixels; i++) {
//     const idx = i;
//
//     // Decode the u and v values
//     const u = uValuesSmooth[idx];
//     const v = vValuesSmooth[idx];
//
//     // Calculate the absolute velocity
//     const velocity = Math.sqrt(Math.pow(u, 2) + Math.pow(v, 2));
//     const velocityMPH = velocity * MPS_TO_MPH;
//     // Normalize the velocity to the range [0, 255]
//     // Encode the normalized velocity into the red channel
//     windSpeedPNG.data[idx * 4] = Math.floor(255 * velocityMPH / maxVelocityMPH);
//
//     // Set the green and blue channels to 0
//     windSpeedPNG.data[idx * 4 + 1] = 0;
//     windSpeedPNG.data[idx * 4 + 2] = 0;
//
//     // Set the alpha channel to 255 (fully opaque)
//     windSpeedPNG.data[idx * 4 + 3] = 255;
//
// }
//
// fs.writeFileSync(name + '_windSpeed.png', PNG.sync.write(windSpeedPNG));

function movingAverage(array, radius) {
    const result = [];
    for (let i = 0; i < array.length; i++) {
        const start = Math.max(0, i - radius);
        const end = Math.min(array.length - 1, i + radius);
        let sum = 0;
        for (let j = start; j <= end; j++) {
            sum += array[j];
        }
        result[i] = sum / (end - start + 1);
    }
    return result;
}

function formatDate(date, time) {
    // Change to export in bash-compatible date
    let year = date.substr(0, 4)
    let month = date.substr(4, 2)
    let day = date.substr(6, 2)
    time = time.toString().padStart(4, "0")
    let hour = time.substr(0,2)
    let minutes = time.substr(2,2)
    return year + '-' + month + '-' + day + 'T' + hour + ':' + minutes + '+00:00';
}
