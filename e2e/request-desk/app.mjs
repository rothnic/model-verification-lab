import { readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { once } from 'node:events';
import { createEngine } from './bend-engine.mjs';

const commands = new Set(['submit', 'retry', 'respond']);

export async function startDesk(compiled, variant = 'healthy') {
  if (!['healthy', 'early-ui'].includes(variant)) throw new Error('Unknown app variant');
  const engine = await createEngine(compiled);
  const html = await readFile(new URL('./index.html', import.meta.url), 'utf8');
  let phase = 'idle';
  let showEarly = variant === 'early-ui';
  const server = createServer(async (req, res) => {
    if (req.method === 'GET' && req.url === '/') {
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }).end(html);
    } else if (req.method === 'POST' && req.url?.startsWith('/commands/')) {
      const command = req.url.slice('/commands/'.length);
      if (!commands.has(command)) {
        res.writeHead(400).end();
        return;
      }
      try {
        phase = await engine.step(phase, command);
        // Deliberate rendering defect: this response changes no engine state.
        const misrender = showEarly && command === 'submit';
        if (misrender) showEarly = false;
        res.writeHead(200, { 'content-type': 'application/json' })
          .end(JSON.stringify({ phase, misrender }));
      } catch (error) {
        console.error(error);
        res.writeHead(500).end();
      }
    } else {
      res.writeHead(404).end();
    }
  });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  return { origin: `http://127.0.0.1:${server.address().port}`, close: () => new Promise(resolve => server.close(resolve)) };
}
