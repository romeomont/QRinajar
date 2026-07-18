import { build } from "esbuild";
import { readFileSync, writeFileSync, mkdirSync } from "fs";

const result = await build({
  entryPoints: ["src/main.js"],
  bundle: true,
  minify: true,
  format: "iife",
  target: "es2019",
  write: false,
});

const js = result.outputFiles[0].text;
const html = readFileSync("src/index.html", "utf8");

// Inline the bundle; escape any </script> sequences inside the JS.
const safeJs = js.replace(/<\/script/gi, "<\\/script");
const out = html.replace("/*__BUNDLE__*/", () => safeJs);

mkdirSync("dist", { recursive: true });
writeFileSync("dist/qr-code-generator.html", out);
console.log(
  `Built dist/qr-code-generator.html (${(out.length / 1024).toFixed(0)} KB) — fully offline, single file.`
);
