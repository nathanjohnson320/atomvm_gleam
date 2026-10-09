#!/usr/bin/env node
/**
 * Boot AtomVM Pico UF2 under rp2040js and load tests.avm as main.avm.
 *
 * Production RP2 layout (src/platforms/rp2/src/main.c):
 *   LIB_AVM  @ 0x10100000  (bundled in combined UF2)
 *   MAIN_AVM @ 0x10180000  (our harness packbeam)
 */
import * as fs from "node:fs";
import { Simulator, ConsoleLogger, LogLevel } from "rp2040js";
import { decodeBlock } from "uf2";

const FLASH_START = 0x10000000;
const MAIN_AVM_ADDR = 0x10180000;

function usage() {
  console.error(
    "Usage: run_harness.mjs --uf2 <file> --avm <file> --bootrom <bin> [--timeout-ms N]",
  );
  process.exit(2);
}

function parseArgs(argv) {
  const out = { timeoutMs: 120_000 };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--uf2") out.uf2 = argv[++i];
    else if (a === "--avm") out.avm = argv[++i];
    else if (a === "--bootrom") out.bootrom = argv[++i];
    else if (a === "--timeout-ms") out.timeoutMs = Number(argv[++i]);
    else usage();
  }
  if (!out.uf2 || !out.avm || !out.bootrom) usage();
  return out;
}

function loadBootrom(rp2040, path) {
  const raw = fs.readFileSync(path);
  if (raw.byteLength !== 16 * 1024) {
    throw new Error(
      `bootrom must be 16 KiB, got ${raw.byteLength} bytes (${path})`,
    );
  }
  const words = new Uint32Array(
    raw.buffer,
    raw.byteOffset,
    raw.byteLength / 4,
  );
  rp2040.loadBootrom(words);
}

function loadUF2(rp2040, path) {
  const fd = fs.openSync(path, "r");
  const buf = new Uint8Array(512);
  while (fs.readSync(fd, buf) === buf.length) {
    const { flashAddress, payload } = decodeBlock(buf);
    rp2040.flash.set(payload, flashAddress - FLASH_START);
  }
  fs.closeSync(fd);
}

function loadAvm(rp2040, path, addr = MAIN_AVM_ADDR) {
  const data = fs.readFileSync(path);
  rp2040.flash.set(data, addr - FLASH_START);
  console.error(
    `loaded ${path} (${data.byteLength} bytes) @ 0x${addr.toString(16)}`,
  );
}

const args = parseArgs(process.argv.slice(2));
const simulator = new Simulator();
const mcu = simulator.rp2040;

loadBootrom(mcu, args.bootrom);
loadUF2(mcu, args.uf2);
loadAvm(mcu, args.avm);

mcu.logger = new ConsoleLogger(LogLevel.Error);

let line = "";
let settled = false;

function finish(code) {
  if (settled) return;
  settled = true;
  process.exit(code);
}

mcu.uart[0].onByte = (value) => {
  process.stdout.write(new Uint8Array([value]));
  const ch = String.fromCharCode(value);
  if (ch === "\n") {
    const text = line.replace(/\r$/, "");
    line = "";
    if (text.includes("AVM_GLEAM_TESTS_OK")) finish(0);
    if (
      text.includes("AVM_GLEAM_TESTS_FAIL") ||
      text === "*** PANIC ***"
    ) {
      finish(1);
    }
  } else {
    line += ch;
  }
};

setTimeout(() => {
  console.error(`timeout after ${args.timeoutMs}ms`);
  finish(1);
}, args.timeoutMs);

mcu.core.PC = FLASH_START;
simulator.execute();
