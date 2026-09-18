import { spawn } from "node:child_process";

const [, , cmdSpec, ...rest] = process.argv;
import { readFileSync } from "node:fs";
const rawSpec = rest.join(" ");
const callSpec = rawSpec ? JSON.parse(rawSpec.startsWith("@") ? readFileSync(rawSpec.slice(1), "utf8") : rawSpec) : null;
const [cmd, ...args] = cmdSpec.split("|");

const child = spawn(cmd, args, { stdio: ["pipe", "pipe", "pipe"] });
let buf = "";
const pending = new Map();
child.stdout.on("data", (d) => {
  buf += d.toString();
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i).trim();
    buf = buf.slice(i + 1);
    if (!line) continue;
    try {
      const msg = JSON.parse(line);
      if (msg.id && pending.has(msg.id)) pending.get(msg.id)(msg);
    } catch {}
  }
});
child.stderr.on("data", (d) => process.stderr.write("[srv] " + d));

let id = 0;
const send = (method, params) =>
  new Promise((resolve, reject) => {
    const myId = ++id;
    pending.set(myId, resolve);
    child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id: myId, method, params }) + "\n");
    setTimeout(() => reject(new Error("timeout on " + method)), 120000);
  });

const init = await send("initialize", {
  protocolVersion: "2024-11-05",
  capabilities: {},
  clientInfo: { name: "diagram-bench", version: "1.0" },
});
child.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n");
console.log("SERVER:", JSON.stringify(init.result?.serverInfo));

const list = await send("tools/list", {});
const tools = list.result?.tools || [];
console.log("TOOLS (" + tools.length + "):");
if (process.env.SCHEMA) {
  const t = tools.find((x) => x.name === process.env.SCHEMA);
  console.log("SCHEMA:", JSON.stringify(t?.inputSchema).slice(0, 4000));
} else for (const t of tools) console.log("  -", t.name, "—", (t.description || "").split("\n")[0].slice(0, 90));

if (callSpec) {
  const res = await send("tools/call", callSpec);
  const out = JSON.stringify(res.result ?? res.error);
  console.log("RESULT:", out.length > 2500 ? out.slice(0, 2500) + "…[truncated]" : out);
}
child.kill();
process.exit(0);
