import SwiftUI
import PhotosUI

// Style preset picker (Square / Rounded / Custom) — used at the top of the
// "style" flow step.
struct StylePresetRow: View {
    @Environment(QRDesign.self) private var design
    var onSelect: (StylePreset.Kind) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(StylePreset.Kind.allCases) { kind in
                StylePresetCard(kind: kind, active: design.activeStyle == kind) {
                    switch kind {
                    case .square: design.applyStyle(.square)
                    case .rounded: design.applyStyle(.rounded)
                    case .custom: break
                    }
                    onSelect(kind)
                }
            }
        }
    }
}

// Fine-tune panels (shape, module style, eyes, background, logo, border/caption)
// — used below the preset row in the "style" flow step.
struct StyleCustomPanels: View {
    @Environment(QRDesign.self) private var design

    var body: some View {
        @Bindable var design = design
        VStack(spacing: 20) {
            GroupCard {
                HStack(spacing: 4) {
                    PanelHeader(title: "Shape & layout", systemImage: "square.on.square")
                    InfoTip(title: "Shape & layout", text: "The overall geometry of the code: its outer silhouette, export resolution, the blank margin around it, and how rounded the card corners are.")
                }
                HStack(spacing: 4) {
                    Picker("Overall shape", selection: $design.shape) {
                        Text("Square").tag("square")
                        Text("Circle").tag("circle")
                    }
                    InfoTip(title: "Overall shape", text: "Square is the standard QR silhouette. Circle crops the card to a circle — make sure the modules still have enough quiet zone to scan after cropping.")
                }
                IntSlider(title: "Size (px)", value: $design.size, range: 200...2000,
                          tip: "The pixel dimensions of the exported QR image. Bigger sizes stay crisp when printed large; smaller ones are lighter to share.")
                IntSlider(title: "Quiet-zone margin", value: $design.margin, range: 0...80,
                          tip: "Blank space around the code. Scanners need a clear quiet zone to lock on — too little margin can make the code unreadable, especially when printed close to other content.")
                IntSlider(title: "Card corner rounding", value: $design.borderRadius, range: 0...60,
                          tip: "Rounds the corners of the card behind the QR code. Purely cosmetic — it doesn't affect the code itself or how well it scans.")
            }

            GroupCard {
                HStack(spacing: 4) {
                    PanelHeader(title: "Module style", systemImage: "circle.grid.3x3.fill")
                    InfoTip(title: "Module style", text: "The individual dots that make up the code's data. Softer shapes look friendlier, but very rounded or thin shapes can reduce contrast between dots — test scan after big changes.")
                }
                HStack(spacing: 4) {
                    Picker("Dot style", selection: $design.dotStyle) {
                        Text("Square").tag("square")
                        Text("Dots").tag("dots")
                        Text("Rounded").tag("rounded")
                        Text("Extra rounded").tag("extra-rounded")
                        Text("Classy").tag("classy")
                        Text("Classy rounded").tag("classy-rounded")
                    }
                    InfoTip(title: "Dot style", text: "The shape used for each data module. Square is the most scanner-compatible; rounder styles look softer but shrink the dark area slightly, which can hurt scanning at small sizes.")
                }
                HStack(spacing: 4) {
                    HexColorPicker(title: "Dot color", hex: $design.dotColor)
                    InfoTip(title: "Dot color", text: "The main color of the code. Needs strong contrast against the background to scan reliably — dark colors on a light background work best.")
                }
                HStack(spacing: 4) {
                    Toggle("Use gradient for dots", isOn: $design.dotGradient)
                    InfoTip(title: "Dot gradient", text: "Blends two colors across the code instead of one flat color. Looks great, but lower contrast between the two colors can make the code harder to scan — keep them reasonably distinct.")
                }
                if design.dotGradient {
                    HexColorPicker(title: "Gradient color 2", hex: $design.dotColor2)
                    Picker("Gradient type", selection: $design.gradientType) {
                        Text("Linear").tag("linear")
                        Text("Radial").tag("radial")
                    }
                    .pickerStyle(.segmented)
                    IntSlider(title: "Rotation", value: $design.gradientRot, range: 0...360, suffix: "°")
                }
            }

            GroupCard {
                HStack(spacing: 4) {
                    PanelHeader(title: "Corner eyes", systemImage: "viewfinder")
                    InfoTip(title: "Corner eyes", text: "The three big square markers in the code's corners that scanners use to find and orient it. They can be styled separately from the rest of the dots, but keep them high-contrast — they matter most for reliable scanning.")
                }
                HStack(spacing: 4) {
                    Picker("Outer eye style", selection: $design.cornerSquareStyle) {
                        Text("Match dots").tag("")
                        Text("Square").tag("square")
                        Text("Dot").tag("dot")
                        Text("Rounded").tag("rounded")
                        Text("Extra rounded").tag("extra-rounded")
                        Text("Dots").tag("dots")
                        Text("Classy").tag("classy")
                        Text("Classy rounded").tag("classy-rounded")
                    }
                    InfoTip(title: "Outer eye style", text: "The shape of the eye's outer ring. \"Match dots\" reuses whatever shape you picked for the module style, for a consistent look.")
                }
                HStack(spacing: 4) {
                    Picker("Inner eye style", selection: $design.cornerDotStyle) {
                        Text("Match dots").tag("")
                        Text("Square").tag("square")
                        Text("Dot").tag("dot")
                        Text("Rounded").tag("rounded")
                        Text("Extra rounded").tag("extra-rounded")
                        Text("Dots").tag("dots")
                        Text("Classy").tag("classy")
                        Text("Classy rounded").tag("classy-rounded")
                    }
                    InfoTip(title: "Inner eye style", text: "The shape of the solid pupil in the center of each eye. Keep it visually distinct from the outer ring so scanners can still tell them apart.")
                }
                HStack(spacing: 4) {
                    HexColorPicker(title: "Outer eye color", hex: $design.cornerSquareColor)
                    InfoTip(title: "Outer eye color", text: "Color of the eye's outer ring. Needs good contrast against the background, just like the dot color.")
                }
                HStack(spacing: 4) {
                    HexColorPicker(title: "Inner eye color", hex: $design.cornerDotColor)
                    InfoTip(title: "Inner eye color", text: "Color of the eye's center pupil. Can differ from the outer ring for a two-tone accent, as long as it still stands out from the background.")
                }
            }

            GroupCard {
                HStack(spacing: 4) {
                    PanelHeader(title: "Background", systemImage: "square.fill.on.circle.fill")
                    InfoTip(title: "Background", text: "The area behind the QR modules. Solid colors give the most reliable contrast; transparent backgrounds work best when you know what they'll be placed over.")
                }
                HStack(spacing: 4) {
                    HexColorPicker(title: "Background color", hex: $design.bgColor)
                    InfoTip(title: "Background color", text: "The fill behind the code. Pick something that stays light relative to the dot color — scanners rely on strong contrast, not on specific colors.")
                }
                HStack(spacing: 4) {
                    Toggle("Transparent background", isOn: $design.bgTransparent)
                    InfoTip(title: "Transparent background", text: "Removes the solid background so the QR code sits directly on whatever it's placed over — useful for overlaying on photos or colored materials. Make sure there's still enough contrast against the dots to scan reliably.")
                }
            }

            LogoPanel()

            GroupCard {
                HStack(spacing: 4) {
                    PanelHeader(title: "Border & caption", systemImage: "textformat")
                    InfoTip(title: "Border & caption", text: "Optional framing around the card: a text label below the code, and a border/padding around the whole thing. Neither affects the QR data — purely presentation.")
                }
                LabeledField("Caption text") {
                    TextField("e.g. Repeater-West — Mast 3", text: $design.caption, axis: .vertical)
                        .lineLimit(1...4)
                }
                HStack(spacing: 4) {
                    HexColorPicker(title: "Caption color", hex: $design.captionColor)
                    InfoTip(title: "Caption color", text: "Text color for the caption below the code. Doesn't affect scanning — it sits outside the QR modules entirely.")
                }
                IntSlider(title: "Caption size", value: $design.captionSize, range: 10...48,
                          tip: "Font size of the caption text. Purely cosmetic — has no effect on the QR code itself.")
                HStack(spacing: 4) {
                    Toggle("Show border around card", isOn: $design.borderEnabled)
                    InfoTip(title: "Border", text: "Draws an outlined edge around the whole card. Purely decorative — toggle it off for a cleaner, borderless look.")
                }
                if design.borderEnabled {
                    HexColorPicker(title: "Border color", hex: $design.borderColor)
                    IntSlider(title: "Border width", value: $design.borderWidth, range: 0...20)
                }
                IntSlider(title: "Card padding", value: $design.cardPadding, range: 0...60,
                          tip: "Space between the QR code and the edge of the card. More padding gives the code visual breathing room when printed or shared.")
            }
        }
    }
}

struct StylePresetCard: View {
    let kind: StylePreset.Kind
    let active: Bool
    let action: () -> Void

    private var title: String {
        switch kind { case .square: return "Square"; case .rounded: return "Rounded"; case .custom: return "Custom" }
    }
    private var desc: String {
        switch kind {
        case .square: return "Crisp modules"
        case .rounded: return "Soft modules"
        case .custom: return "Fine-tune"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                swatch
                Text(title).font(.subheadline.weight(.bold))
                Text(desc).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(active ? brandBlue.opacity(0.18) : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(active ? brandBlue : Color.secondary.opacity(0.25), lineWidth: active ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var swatch: some View {
        switch kind {
        case .square:
            grid(corner: 1)
        case .rounded:
            grid(corner: 6)
        case .custom:
            Image(systemName: "slider.horizontal.3").font(.title2).foregroundStyle(brandBlue).frame(width: 40, height: 40)
        }
    }

    private func grid(corner: CGFloat) -> some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: corner).fill(brandBlue).frame(width: 10, height: 10)
                    }
                }
            }
        }.frame(width: 40, height: 40)
    }
}

struct LogoPanel: View {
    @Environment(QRDesign.self) private var design
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        @Bindable var design = design
        GroupCard {
            HStack(spacing: 4) {
                PanelHeader(title: "Center logo", systemImage: "photo")
                InfoTip(title: "Center logo", text: "Places an image over the middle of the code. QR codes have built-in error correction that lets them keep scanning even with the center obscured — use a higher error correction level (Q or H) when adding one.")
            }
            HStack(spacing: 12) {
                if let data = design.logoPNG, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(design.logoPNG == nil ? "Choose image" : "Replace image", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.bordered)
                if design.logoPNG != nil {
                    Button(role: .destructive) { design.logoPNG = nil } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            Text("Stays on this device — never uploaded.")
                .font(.caption2).foregroundStyle(.secondary)

            if design.logoPNG != nil {
                LabeledSlider(title: "Logo size", value: $design.logoSize, range: 0.1...0.5, step: 0.05,
                              format: { String(format: "%.2f", $0) },
                              tip: "How much of the code's width the logo covers. Bigger logos look bolder but hide more data — pair with a higher error correction level (Q or H) so the code still scans.")
                IntSlider(title: "Logo margin", value: $design.logoMargin, range: 0...30)
                HStack(spacing: 4) {
                    Toggle("Clear dots behind logo", isOn: $design.hideDots)
                    InfoTip(title: "Clear dots behind logo", text: "Removes the QR dots directly under the logo instead of drawing them dimmed underneath. Cleaner look, but relies more heavily on error correction to reconstruct that missing data — use Q or H.")
                }
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data), let png = ui.pngData() {
                    design.logoPNG = png
                }
            }
        }
    }
}
