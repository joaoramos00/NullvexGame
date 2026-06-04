// tests/bot/run_stage_bot.mjs
// Uso: node run_stage_bot.mjs <stageId>   (ex.: node run_stage_bot.mjs 00)
import { chromium } from "playwright";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const stage = (process.argv[2] ?? "00").padStart(2, "0");
const BASE = "http://localhost:8080";
const URL = `${BASE}/?stage=${stage}&bot=1&noenemies=1`;
const BOOT_TIMEOUT = 30_000;
const RUN_TIMEOUT = 180_000;
// HEADED=1 abre a janela do browser pra acompanhar ao vivo; SLOWMO=ms desacelera as ações.
const HEADED = process.env.HEADED === "1";
const SLOWMO = Number(process.env.SLOWMO ?? 0);

const shotsDir = resolve(__dirname, "shots", stage);
const resultsDir = resolve(__dirname, "results");
await mkdir(shotsDir, { recursive: true });
await mkdir(resultsDir, { recursive: true });

const browser = await chromium.launch({ headless: !HEADED, slowMo: SLOWMO });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
// Em modo headed, segura a janela aberta um instante no fim pra inspeção.
const HOLD_END = HEADED ? 2500 : 0;

const result = { status: "FAIL", stage, segments_completed: 0, shots: [], stuck: null, duration_ms: 0 };
const started = Date.now();

let resolveRun;
const runDone = new Promise((r) => (resolveRun = r));
let bootSeen = false;
let bootTimer = setTimeout(() => { if (!bootSeen) { result.error = "boot timeout"; resolveRun(); } }, BOOT_TIMEOUT);
const runTimer = setTimeout(() => { result.error = "run timeout"; resolveRun(); }, RUN_TIMEOUT);

async function snap(label, suffix = "") {
  const file = resolve(shotsDir, `${label}${suffix}.png`);
  const canvas = page.locator("canvas").first();
  await canvas.screenshot({ path: file });
  result.shots.push(file);
}

page.on("console", async (msg) => {
  const text = msg.text();
  if (text.startsWith("BOT_START")) {
    bootSeen = true; clearTimeout(bootTimer);
  } else if (text.startsWith("BOT_SHOT:")) {
    const label = text.split(":").slice(2).join(":").trim();
    await snap(label);
    result.segments_completed++;
  } else if (text.startsWith("BOT_STUCK:")) {
    const body = text.slice("BOT_STUCK:".length).trim();
    const [label, pos] = body.split("@");
    const [x, y] = (pos ?? "0,0").split(",").map(Number);
    result.stuck = { label, x, y };
    await snap(label, "_STUCK");
    resolveRun();
  } else if (text.startsWith("BOT_DONE")) {
    result.status = "PASS";
    resolveRun();
  }
});

await page.goto(URL, { waitUntil: "load" });
await runDone;

clearTimeout(runTimer);
result.duration_ms = Date.now() - started;
if (HOLD_END > 0) await new Promise((r) => setTimeout(r, HOLD_END));
await browser.close();
await writeFile(resolve(resultsDir, `${stage}.json`), JSON.stringify(result, null, 2));

console.log(`\n[StageBot] stage ${stage}: ${result.status}` +
  (result.stuck ? ` (travou em ${result.stuck.label} @ ${result.stuck.x},${result.stuck.y})` : "") +
  ` — ${result.shots.length} prints, ${result.duration_ms}ms`);
process.exit(result.status === "PASS" ? 0 : 1);
