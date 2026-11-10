#!/usr/bin/env node
// Helix formatter for JS: stdin -> stdout with missing semicolons added (ESLint's `semi` rule), nothing
// else changes. Code that doesn't parse is echoed back untouched. eslint comes from dev.nix: found via PATH.
import { execFileSync } from "node:child_process";
import { realpathSync } from "node:fs";
import { dirname, join } from "node:path";

const bin = realpathSync(execFileSync("sh", ["-c", "command -v eslint"], { encoding: "utf8" }).trim());
const { Linter } = await import(join(dirname(bin), "../lib/node_modules/eslint/lib/api.js"));

let src = "";
for await (const chunk of process.stdin) src += chunk;

const { output, messages } = new Linter().verifyAndFix(src, {
  languageOptions: { ecmaVersion: "latest", sourceType: "module", parserOptions: { ecmaFeatures: { jsx: true } } },
  rules: { semi: ["error", "always"] },
});
process.stdout.write(messages.some((m) => m.fatal) ? src : output);
