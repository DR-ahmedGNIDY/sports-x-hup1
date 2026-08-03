// Static file server for `flutter build web` output, used to preview the
// app in the Claude Code browser pane for UI verification during phase
// reviews (`flutter run -d web-server` doesn't bind reliably under this
// harness's process launcher). Not part of the shipped app.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, 'build', 'web');
const port = process.env.PORT || 5173;

const mime = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ico': 'image/x-icon',
};

http
  .createServer((req, res) => {
    let filePath = path.join(root, decodeURIComponent(req.url.split('?')[0]));
    if (req.url === '/' || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      filePath = path.join(root, 'index.html');
    }
    const ext = path.extname(filePath);
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': mime[ext] || 'application/octet-stream' });
      res.end(data);
    });
  })
  .listen(port, () => console.log(`Serving build/web on http://localhost:${port}`));
