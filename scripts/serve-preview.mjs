import http from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(scriptDirectory, '../budget/build/web');
const port = Number(process.argv[2] ?? 5381);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error('Provide a valid local preview port.');
}
await stat(path.join(webRoot, 'index.html'));

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

http.createServer(async (request, response) => {
  if (!['GET', 'HEAD'].includes(request.method)) {
    response.writeHead(405, { Allow: 'GET, HEAD' }).end();
    return;
  }
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://127.0.0.1').pathname);
    const relativePath = pathname.endsWith('/') ? `${pathname}index.html` : pathname;
    const target = path.resolve(webRoot, `.${relativePath}`);
    if (!target.toLowerCase().startsWith(`${webRoot.toLowerCase()}${path.sep}`)) {
      response.writeHead(403).end();
      return;
    }
    const content = await readFile(target);
    response.writeHead(200, {
      'Content-Type': mimeTypes[path.extname(target).toLowerCase()] ?? 'application/octet-stream',
      'Content-Length': content.length,
      'Cache-Control': 'no-store',
    });
    response.end(request.method === 'HEAD' ? undefined : content);
  } catch (error) {
    response.writeHead(error.code === 'ENOENT' ? 404 : 400).end();
  }
}).listen(port, '127.0.0.1', () => {
  process.stdout.write(`Cashew preview: http://127.0.0.1:${port}/\n`);
});
