# 🛠️ Build Status

| OS      | Status                                                                                  |
|---------|-----------------------------------------------------------------------------------------|
| Linux   | ![Linux](https://github.com/avac74/zmime/actions/workflows/ci-linux.yaml/badge.svg)     |
| macOS   | ![macOS](https://github.com/avac74/zmime/actions/workflows/ci-mac.yaml/badge.svg)       |
| Windows | ![Windows](https://github.com/avac74/zmime/actions/workflows/ci-windows.yaml/badge.svg) |

# 📦 Zig FileType Detector

A  dependency‑free file type detection library written in Zig.
It identifies files using magic numbers, lightweight heuristics, and content‑based analysis, not just extensions.

This project includes:

- A Zig library for detecting file types
- A comprehensive magic‑number table covering images, audio, video, archives, executables, documents, fonts, and more
- A tiny CLI tool (detect) for testing and debugging
- Fully cross‑platform (Windows, Linux, macOS)

# ✨ Features

- 🔍 Content‑based detection using magic numbers
- 🧠 Text vs binary heuristic for unknown formats
- ⚡ Fast: reads only the first few KB of a file
- 🧱 Zero dependencies
- 🖥️ Cross‑platform (Zig standard library)
- 🧩 Extensible: add new signatures easily
- 🛠️ Includes a CLI tool for quick testing
- 🏢 Commercial‑friendly: no external licensing constraints

# 📁 Supported Categories

The detector recognizes a wide range of formats:
### Images

PNG, JPEG, GIF, WebP, BMP, TIFF, HEIC, ICO, and more.

### Audio

MP3, WAV, FLAC, OGG, AAC.

### Video

MP4, MKV, AVI, MOV, WebM.

### Archives

ZIP, TAR, GZIP, BZIP2, 7Z, RAR.

### Documents

PDF, DOCX/XLSX/PPTX (via ZIP magic), EPUB, SQLite.

### Executables

ELF, PE (Windows), Mach‑O (macOS), Fat binaries.

### Fonts

TTF, OTF, WOFF, WOFF2.

### Misc

WASM, SVG (text‑based), and more.

# 🚀 Getting Started

### Build the CLI tool

```sh
zig build
```

This produces a `zmime` executable in `zig-out/bin`.

### Run it

```sh
./zig-out/bin/zmime path/to/file
```

# 🧩 Library Usage

Import the module in your Zig project:

```zig
const zmime = @import("zmime.zig");

pub fn main() !void {
    const info = try zmime.detectFileInfo("example.pdf");
    std.log.info("File type: {s}, MIME: {s}", .{
        @tagName(info.file_type),
        zmime.mimeToString(info.mime),
    });
}
```

# 🗺️ Roadmap

This project aims to provide a fast, reliable, and extensible file‑type detection system built entirely in Zig.
Below is the current roadmap, including completed features and planned enhancements.

|    |                                         |
|----|-----------------------------------------|
| ✅ | Magic-number detection                  |
| ✅ | Text vs binary heuristic                |
| ❌ | File extension fallback                 |
| ❌ | Secondary lightweight analysis          |
| ✅ | MIME type mapping                       |
| ❌ | Encoding detection (UTF-8, UTF-16, etc) |
| ❌ | Source code detection                   |
| ❌ | Benchmark suite                         |
| ❌ | Fuzz testing                            |
