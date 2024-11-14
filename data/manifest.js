const fs = require('fs');

let manifest = []

filenames = process.argv.slice(2)

filenames.forEach(f => {
    console.log(f)
    let data = JSON.parse(fs.readFileSync(f))
    data["id"] = f.slice(0, -5)
    manifest.push(data)
});

fs.writeFileSync("data.json", JSON.stringify(manifest))
