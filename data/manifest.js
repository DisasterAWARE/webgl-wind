const fs = require('fs');
const path = require('path')

let manifest = []

filenames = process.argv.slice(3)
let dir = process.argv[2]

filenames.forEach(f => {
    console.log(f)
    let data = JSON.parse(fs.readFileSync(f))
    data["id"] = f.slice(0, -5)
    manifest.push(data)
});
let outfile = path.join(dir, "data.json")
fs.writeFileSync(outfile, JSON.stringify(manifest))
