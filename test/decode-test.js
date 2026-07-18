import QRCodeStyling from "qr-code-styling";
import jsQR from "jsqr";

const DATA = "https://meshtastic.org/e/#ChMSAQEaB01lc2hOZXQlB0xvbmdGYXN0";

// A red 64x64 PNG dot as a stand-in logo (generated below on a canvas).
function makeLogo() {
  const c = document.createElement("canvas");
  c.width = 64; c.height = 64;
  const ctx = c.getContext("2d");
  ctx.fillStyle = "#e53935";
  ctx.beginPath();
  ctx.arc(32, 32, 30, 0, Math.PI * 2);
  ctx.fill();
  return c.toDataURL("image/png");
}

const CASES = [
  { name: "square/classic", opts: { dotsOptions: { type: "square", color: "#000" } } },
  { name: "rounded+eyes", opts: {
      dotsOptions: { type: "rounded", color: "#0d1b2a" },
      cornersSquareOptions: { type: "extra-rounded", color: "#0d1b2a" },
      cornersDotOptions: { type: "dot", color: "#35b5e5" },
  } },
  { name: "circle+dots", opts: { shape: "circle", dotsOptions: { type: "dots", color: "#0d1b2a" } } },
  { name: "circle+rounded", opts: { shape: "circle", dotsOptions: { type: "rounded", color: "#0d1b2a" } } },
  { name: "square+dots", opts: { shape: "square", dotsOptions: { type: "dots", color: "#0d1b2a" } } },
  { name: "gradient+classy", opts: {
      dotsOptions: { type: "classy-rounded", gradient: {
        type: "linear", rotation: Math.PI / 4,
        colorStops: [{ offset: 0, color: "#0d1b2a" }, { offset: 1, color: "#2a6f97" }],
      } },
  } },
  { name: "logo+hidedots(H)", opts: {
      qrOptions: { errorCorrectionLevel: "H" },
      dotsOptions: { type: "rounded", color: "#0d1b2a" },
      image: makeLogo(),
      imageOptions: { imageSize: 0.35, margin: 6, hideBackgroundDots: true },
  } },
];

const results = [];

async function runCase(c) {
  const qr = new QRCodeStyling({
    width: 600, height: 600, type: "canvas", data: DATA, margin: 16,
    qrOptions: { errorCorrectionLevel: "Q" },
    backgroundOptions: { color: "#ffffff" },
    ...c.opts,
  });
  const holder = document.createElement("div");
  document.body.appendChild(holder);
  qr.append(holder);
  // wait for async render (image loading etc.)
  await new Promise((r) => setTimeout(r, 600));
  const canvas = holder.querySelector("canvas");
  const ctx = canvas.getContext("2d");
  const img = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const decoded = jsQR(img.data, img.width, img.height);
  const ok = decoded && decoded.data === DATA;
  results.push(`${c.name}: ${ok ? "PASS" : "FAIL" + (decoded ? " (wrong data)" : " (no decode)")}`);
}

(async () => {
  for (const c of CASES) await runCase(c);
  const el = document.createElement("pre");
  el.id = "results";
  el.textContent = results.join("\n");
  document.body.prepend(el);
  document.title = results.every((r) => r.includes("PASS")) ? "ALL PASS" : "FAILURES";
})();
