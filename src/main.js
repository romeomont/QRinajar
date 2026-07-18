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
let qr = new QRCodeStyling(buildOptions(FACTORY));
qr.append(previewEl);

let renderTimer = null;
function render() {
  clearTimeout(renderTimer);
  renderTimer = setTimeout(() => {
    const s = readUI();
    qr.update(buildOptions(s));
    previewEl.style.borderRadius = s.borderRadius + "px";
    previewEl.style.background = s.bgTransparent
      ? "repeating-conic-gradient(#ccc 0% 25%, #fff 0% 50%) 0 0 / 20px 20px"
      : s.bgColor;
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
  $("gradient-opts").style.display = $("dot-gradient").checked ? "" : "none";
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

// ---- downloads ----
function filename() {
  const d = new Date();
  const stamp = d.toISOString().slice(0, 10);
  return "mesh-qr-" + stamp;
}
async function download(ext) {
  const s = readUI();
  const exportQr = new QRCodeStyling(buildOptions(s));
  await exportQr.download({ name: filename(), extension: ext });
}
$("dl-png").addEventListener("click", () => download("png"));
$("dl-svg").addEventListener("click", () => download("svg"));
$("dl-jpeg").addEventListener("click", () => download("jpeg"));

$("copy-png").addEventListener("click", async () => {
  try {
    const s = readUI();
    const exportQr = new QRCodeStyling(buildOptions(s));
    const blob = await exportQr.getRawData("png");
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
