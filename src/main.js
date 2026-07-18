import QRCodeStyling from "qr-code-styling";
import jsQR from "jsqr";

const $ = (id) => document.getElementById(id);

const BOX_TAG = `LORA MESH EQUIPMENT - PLEASE READ
This box is part of a community LoRa mesh radio network (MeshCore).
It relays short low-power radio messages. Nothing hazardous or valuable inside.
Site: [site / mast name]
Node: [node name & ID]
Contact: [your name or email]
If this equipment is damaged or needs to be moved, please get in touch.`;

const FACTORY = {
  data: BOX_TAG,
  ecc: "Q",
  shape: "square",
  size: 800,
  margin: 16,
  borderRadius: 14,
  dotStyle: "rounded",
  dotColor: "#0d1b2a",
  dotGradient: false,
  dotColor2: "#35b5e5",
  gradientType: "linear",
  gradientRot: 45,
  cornerSquareStyle: "extra-rounded",
  cornerDotStyle: "dot",
  cornerSquareColor: "#0d1b2a",
  cornerDotColor: "#35b5e5",
  bgColor: "#ffffff",
  bgTransparent: false,
  logo: null,
  logoSize: 0.35,
  logoMargin: 6,
  hideDots: true,
  caption: "",
  captionColor: "#0d1b2a",
  captionSize: 20,
  borderEnabled: true,
  borderColor: "#0d1b2a",
  borderWidth: 4,
  cardPadding: 24,
};

const PRESET_DATA = {
  boxtag: BOX_TAG,
  channel: "[paste the contact/channel share link from the MeshCore app here]",
  node: "MESHCORE NODE\nName: Repeater-West\nID: a1b2c3d4\nFreq: 915 MHz\nRole: Repeater",
  wifi: "WIFI:T:WPA;S:MeshGateway;P:changeme123;;",
  text: "Hello from the mesh",
};

const STORE_KEY = "mesh-qr-settings-v1";

function readUI() {
  return {
    data: $("data").value,
    ecc: $("ecc").value,
    shape: $("shape").value,
    size: clampInt($("size").value, 200, 2000, 600),
    margin: +$("margin").value,
    borderRadius: +$("border-radius").value,
    dotStyle: $("dot-style").value,
    dotColor: $("dot-color").value,
    dotGradient: $("dot-gradient").checked,
    dotColor2: $("dot-color2").value,
    gradientType: $("gradient-type").value,
    gradientRot: +$("gradient-rot").value,
    cornerSquareStyle: $("corner-square-style").value,
    cornerDotStyle: $("corner-dot-style").value,
    cornerSquareColor: $("corner-square-color").value,
    cornerDotColor: $("corner-dot-color").value,
    bgColor: $("bg-color").value,
    bgTransparent: $("bg-transparent").checked,
    logo: state.logo,
    logoSize: +$("logo-size").value,
    logoMargin: +$("logo-margin").value,
    hideDots: $("hide-dots").checked,
    caption: $("caption").value,
    captionColor: $("caption-color").value,
    captionSize: +$("caption-size").value,
    borderEnabled: $("border-enabled").checked,
    borderColor: $("border-color").value,
    borderWidth: +$("border-width").value,
    cardPadding: +$("card-padding").value,
  };
}

function applyToUI(s) {
  $("data").value = s.data;
  $("ecc").value = s.ecc;
  $("shape").value = s.shape;
  $("size").value = s.size;
  $("margin").value = s.margin;
  $("border-radius").value = s.borderRadius;
  $("dot-style").value = s.dotStyle;
  $("dot-color").value = s.dotColor;
  $("dot-color-hex").value = s.dotColor;
  $("dot-gradient").checked = s.dotGradient;
  $("dot-color2").value = s.dotColor2;
  $("gradient-type").value = s.gradientType;
  $("gradient-rot").value = s.gradientRot;
  $("corner-square-style").value = s.cornerSquareStyle;
  $("corner-dot-style").value = s.cornerDotStyle;
  $("corner-square-color").value = s.cornerSquareColor;
  $("corner-dot-color").value = s.cornerDotColor;
  $("bg-color").value = s.bgColor;
  $("bg-color-hex").value = s.bgColor;
  $("bg-transparent").checked = s.bgTransparent;
  $("logo-size").value = s.logoSize;
  $("logo-margin").value = s.logoMargin;
  $("hide-dots").checked = s.hideDots;
  $("caption").value = s.caption || "";
  $("caption-color").value = s.captionColor;
  $("caption-size").value = s.captionSize;
  $("border-enabled").checked = s.borderEnabled;
  $("border-color").value = s.borderColor;
  $("border-width").value = s.borderWidth;
  $("card-padding").value = s.cardPadding;
  state.logo = s.logo || null;
  refreshLogoUI();
  refreshDynamicLabels();
}

function clampInt(v, min, max, fallback) {
  const n = parseInt(v, 10);
  if (Number.isNaN(n)) return fallback;
  return Math.min(max, Math.max(min, n));
}

const state = { logo: null };

function buildOptions(s, forExport) {
  const opts = {
    width: s.size,
    height: s.size,
    type: "canvas",
    shape: s.shape,
    data: s.data || " ",
    margin: s.margin,
    qrOptions: { errorCorrectionLevel: s.ecc },
    dotsOptions: { type: s.dotStyle },
    cornersSquareOptions: {
      type: s.cornerSquareStyle || undefined,
      color: s.cornerSquareColor,
    },
    cornersDotOptions: {
      type: s.cornerDotStyle || undefined,
      color: s.cornerDotColor,
    },
    backgroundOptions: {
      color: s.bgTransparent ? "rgba(0,0,0,0)" : s.bgColor,
    },
  };

  if (s.dotGradient) {
    opts.dotsOptions.gradient = {
      type: s.gradientType,
      rotation: (s.gradientRot * Math.PI) / 180,
      colorStops: [
        { offset: 0, color: s.dotColor },
        { offset: 1, color: s.dotColor2 },
      ],
    };
  } else {
    opts.dotsOptions.color = s.dotColor;
  }

  if (s.logo) {
    opts.image = s.logo;
    opts.imageOptions = {
      imageSize: s.logoSize,
      margin: s.logoMargin,
      hideBackgroundDots: s.hideDots,
      crossOrigin: "anonymous",
    };
  }
  return opts;
}

const previewEl = $("qr-preview");
const cardEl = $("qr-card");
const captionEl = $("qr-caption");
let qr = new QRCodeStyling(buildOptions(FACTORY));
qr.append(previewEl);

let renderTimer = null;
function render() {
  clearTimeout(renderTimer);
  renderTimer = setTimeout(() => {
    const s = readUI();
    qr.update(buildOptions(s));

    const bw = s.borderEnabled ? s.borderWidth : 0;
    cardEl.style.borderRadius = s.borderRadius + "px";
    cardEl.style.border = bw > 0 ? `${bw}px solid ${s.borderColor}` : "none";
    cardEl.style.padding = s.cardPadding + "px";
    cardEl.style.background = s.bgTransparent
      ? "repeating-conic-gradient(#ccc 0% 25%, #fff 0% 50%) 0 0 / 20px 20px"
      : s.bgColor;

    const captionText = (s.caption || "").trim();
    captionEl.textContent = captionText;
    captionEl.style.display = captionText ? "block" : "none";
    captionEl.style.color = s.captionColor;
    captionEl.style.fontSize = s.captionSize + "px";
    captionEl.style.marginTop = captionText ? "14px" : "0";

    $("scan-result").textContent = "";
    refreshDynamicLabels();
  }, 60);
}

function refreshDynamicLabels() {
  $("margin-val").textContent = $("margin").value;
  $("radius-val").textContent = $("border-radius").value;
  $("rot-val").textContent = $("gradient-rot").value + "°";
  $("logo-size-val").textContent = $("logo-size").value;
  $("logo-margin-val").textContent = $("logo-margin").value;
  $("caption-size-val").textContent = $("caption-size").value;
  $("border-width-val").textContent = $("border-width").value;
  $("card-padding-val").textContent = $("card-padding").value;
  $("gradient-opts").style.display = $("dot-gradient").checked ? "" : "none";
  $("border-opts").style.display = $("border-enabled").checked ? "" : "none";
}

// ---- wire up all inputs ----
document.querySelectorAll(".controls input, .controls select, .controls textarea").forEach((el) => {
  el.addEventListener("input", render);
  el.addEventListener("change", render);
});

// hex text <-> color picker sync
function bindHex(colorId, hexId) {
  $(colorId).addEventListener("input", () => { $(hexId).value = $(colorId).value; });
  $(hexId).addEventListener("input", () => {
    const v = $(hexId).value.trim();
    if (/^#[0-9a-fA-F]{6}$/.test(v)) { $(colorId).value = v; render(); }
  });
}
bindHex("dot-color", "dot-color-hex");
bindHex("bg-color", "bg-color-hex");

// content presets
document.querySelectorAll(".chip[data-preset]").forEach((chip) => {
  chip.addEventListener("click", () => {
    $("data").value = PRESET_DATA[chip.dataset.preset];
    render();
  });
});

// ---- logo handling (all local via FileReader) ----
const drop = $("logo-drop");
const fileInput = $("logo-file");

drop.addEventListener("click", () => fileInput.click());
drop.addEventListener("dragover", (e) => { e.preventDefault(); drop.classList.add("over"); });
drop.addEventListener("dragleave", () => drop.classList.remove("over"));
drop.addEventListener("drop", (e) => {
  e.preventDefault();
  drop.classList.remove("over");
  const f = e.dataTransfer.files[0];
  if (f) loadLogo(f);
});
fileInput.addEventListener("change", () => {
  if (fileInput.files[0]) loadLogo(fileInput.files[0]);
});

function loadLogo(file) {
  const reader = new FileReader();
  reader.onload = () => {
    state.logo = reader.result;
    refreshLogoUI();
    render();
  };
  reader.readAsDataURL(file);
}

function refreshLogoUI() {
  const has = !!state.logo;
  $("logo-thumb").style.display = has ? "" : "none";
  if (has) $("logo-thumb").src = state.logo;
  $("logo-drop-text").innerHTML = has
    ? "Logo loaded — click to replace"
    : "Click or drop an image here (PNG/SVG/JPG)<br>stays on this device — never uploaded";
  $("logo-opts").style.display = has ? "" : "none";
}

$("logo-remove").addEventListener("click", () => {
  state.logo = null;
  fileInput.value = "";
  refreshLogoUI();
  render();
});

// ---- card composition (border + caption baked into every export) ----
function blobToImage(blob) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(blob);
    const img = new Image();
    img.onload = () => { URL.revokeObjectURL(url); resolve(img); };
    img.onerror = reject;
    img.src = url;
  });
}

function wrapCaptionLines(ctx, text, maxWidth) {
  const paragraphs = text.split("\n");
  const lines = [];
  for (const para of paragraphs) {
    if (!para) { lines.push(""); continue; }
    const words = para.split(" ");
    let cur = "";
    for (const word of words) {
      const test = cur ? cur + " " + word : word;
      if (cur && ctx.measureText(test).width > maxWidth) {
        lines.push(cur);
        cur = word;
      } else {
        cur = test;
      }
    }
    if (cur) lines.push(cur);
  }
  return lines;
}

function roundRectPath(ctx, x, y, w, h, r) {
  const rr = Math.max(0, Math.min(r, w / 2, h / 2));
  ctx.beginPath();
  ctx.moveTo(x + rr, y);
  ctx.arcTo(x + w, y, x + w, y + h, rr);
  ctx.arcTo(x + w, y + h, x, y + h, rr);
  ctx.arcTo(x, y + h, x, y, rr);
  ctx.arcTo(x, y, x + w, y, rr);
  ctx.closePath();
}

const CAPTION_FONT = (size) => `600 ${size}px "Segoe UI", system-ui, sans-serif`;

// Returns geometry shared by the canvas and SVG composers so downloads match the preview.
function cardLayout(s) {
  const bw = s.borderEnabled ? s.borderWidth : 0;
  const pad = s.cardPadding;
  const captionText = (s.caption || "").trim();
  const measureCtx = document.createElement("canvas").getContext("2d");
  measureCtx.font = CAPTION_FONT(s.captionSize);
  const lines = captionText ? wrapCaptionLines(measureCtx, captionText, s.size) : [];
  const lineHeight = s.captionSize * 1.3;
  const captionBlockHeight = lines.length ? 14 + lines.length * lineHeight : 0;
  const innerW = s.size;
  const innerH = s.size + captionBlockHeight;
  const totalW = innerW + pad * 2 + bw * 2;
  const totalH = innerH + pad * 2 + bw * 2;
  return { bw, pad, lines, lineHeight, innerW, innerH, totalW, totalH };
}

async function composeCanvas(s, opaque) {
  const layout = cardLayout(s);
  const { bw, pad, lines, lineHeight, innerW, totalW, totalH } = layout;

  const exportQr = new QRCodeStyling(buildOptions(s));
  const rawBlob = await exportQr.getRawData("png");
  const qrImg = await blobToImage(rawBlob);

  const canvas = document.createElement("canvas");
  canvas.width = totalW;
  canvas.height = totalH;
  const ctx = canvas.getContext("2d");

  if (opaque) {
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(0, 0, totalW, totalH);
  }

  roundRectPath(ctx, bw / 2, bw / 2, totalW - bw, totalH - bw, s.borderRadius);
  if (!s.bgTransparent) {
    ctx.fillStyle = s.bgColor;
    ctx.fill();
  }
  if (bw > 0) {
    ctx.lineWidth = bw;
    ctx.strokeStyle = s.borderColor;
    ctx.stroke();
  }

  ctx.drawImage(qrImg, bw + pad, bw + pad, innerW, innerW);

  if (lines.length) {
    ctx.fillStyle = s.captionColor;
    ctx.font = CAPTION_FONT(s.captionSize);
    ctx.textAlign = "center";
    ctx.textBaseline = "top";
    let y = bw + pad + innerW + 14;
    for (const line of lines) {
      ctx.fillText(line, totalW / 2, y);
      y += lineHeight;
    }
  }

  return canvas;
}

function escapeXml(str) {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

async function composeSvg(s) {
  const layout = cardLayout(s);
  const { bw, pad, lines, lineHeight, innerW, totalW, totalH } = layout;

  const exportQr = new QRCodeStyling(buildOptions(s));
  const blob = await exportQr.getRawData("svg");
  const svgText = await blob.text();

  const bgFill = s.bgTransparent ? "none" : s.bgColor;
  const strokeAttr = bw > 0 ? `stroke="${s.borderColor}" stroke-width="${bw}"` : `stroke="none"`;

  let textEls = "";
  if (lines.length) {
    let y = bw + pad + innerW + 14 + s.captionSize;
    for (const line of lines) {
      textEls += `<text x="${totalW / 2}" y="${y}" text-anchor="middle" font-family="'Segoe UI', system-ui, sans-serif" font-weight="600" font-size="${s.captionSize}" fill="${s.captionColor}">${escapeXml(line)}</text>`;
      y += lineHeight;
    }
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${totalW}" height="${totalH}" viewBox="0 0 ${totalW} ${totalH}">` +
    `<rect x="${bw / 2}" y="${bw / 2}" width="${totalW - bw}" height="${totalH - bw}" rx="${s.borderRadius}" ry="${s.borderRadius}" fill="${bgFill}" ${strokeAttr}/>` +
    `<g transform="translate(${bw + pad}, ${bw + pad})">${svgText}</g>` +
    textEls +
    `</svg>`;
}

function triggerDownloadBlob(blob, name) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function canvasToBlob(canvas, mime, quality) {
  return new Promise((resolve) => canvas.toBlob(resolve, mime, quality));
}

// ---- downloads ----
function filename() {
  const d = new Date();
  const stamp = d.toISOString().slice(0, 10);
  return "mesh-qr-" + stamp;
}
async function download(ext) {
  const s = readUI();
  if (ext === "svg") {
    const svgStr = await composeSvg(s);
    triggerDownloadBlob(new Blob([svgStr], { type: "image/svg+xml" }), filename() + ".svg");
    return;
  }
  const canvas = await composeCanvas(s, ext === "jpeg");
  const mime = ext === "jpeg" ? "image/jpeg" : "image/png";
  const blob = await canvasToBlob(canvas, mime, ext === "jpeg" ? 0.95 : undefined);
  triggerDownloadBlob(blob, filename() + "." + ext);
}
$("dl-png").addEventListener("click", () => download("png"));
$("dl-svg").addEventListener("click", () => download("svg"));
$("dl-jpeg").addEventListener("click", () => download("jpeg"));

$("copy-png").addEventListener("click", async () => {
  try {
    const s = readUI();
    const canvas = await composeCanvas(s, false);
    const blob = await canvasToBlob(canvas, "image/png");
    await navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
    flash($("copy-png"), "Copied!");
  } catch (e) {
    flash($("copy-png"), "Copy failed");
  }
});

function flash(btn, text) {
  const orig = btn.textContent;
  btn.textContent = text;
  setTimeout(() => { btn.textContent = orig; }, 1400);
}

// ---- scan self-test (jsQR, offline) ----
$("test-scan").addEventListener("click", () => {
  const out = $("scan-result");
  const canvas = previewEl.querySelector("canvas");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  const img = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const decoded = jsQR(img.data, img.width, img.height);
  const expected = $("data").value || " ";
  if (decoded && decoded.data === expected) {
    out.textContent = "✓ Decodes correctly — safe to print";
    out.style.color = "#4ade80";
  } else if (decoded) {
    out.textContent = "⚠ Decodes, but data mismatch — check payload";
    out.style.color = "#fbbf24";
  } else {
    out.textContent =
      "✗ Test decoder failed — real phones may still scan it, but margin is thin. Try a different dot style, higher error correction, or more contrast.";
    out.style.color = "#f87171";
  }
});

// ---- presets (localStorage, offline) ----
$("save-preset").addEventListener("click", () => {
  try {
    localStorage.setItem(STORE_KEY, JSON.stringify(readUI()));
    flash($("save-preset"), "Saved ✓");
  } catch (e) {
    flash($("save-preset"), "Save failed (logo too big?)");
  }
});
$("reset-preset").addEventListener("click", () => {
  localStorage.removeItem(STORE_KEY);
  applyToUI(FACTORY);
  render();
  flash($("reset-preset"), "Reset ✓");
});

// ---- boot ----
(function boot() {
  let saved = null;
  try { saved = JSON.parse(localStorage.getItem(STORE_KEY)); } catch (e) { /* corrupt store */ }
  if (saved) applyToUI({ ...FACTORY, ...saved });
  else refreshDynamicLabels();
  render();
})();
