# 🛠️ Build Status

| OS      | Status                                                                                  |
| ------- | --------------------------------------------------------------------------------------- |
| Linux   | ![Linux](https://github.com/avac74/zmime/actions/workflows/ci-linux.yaml/badge.svg)     |
| macOS   | ![macOS](https://github.com/avac74/zmime/actions/workflows/ci-mac.yaml/badge.svg)       |
| Windows | ![Windows](https://github.com/avac74/zmime/actions/workflows/ci-windows.yaml/badge.svg) |

## Latest release
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/avac74/zmime)

# ⚠️ Disclaimer

This library is currently alpha‑quality. The API may evolve, internal structures may change, and edge cases are still being explored. The primary purpose of this project is for me to learn Zig by building something real, and to grow it into a reliable, well‑designed file‑type detection library over time.

If you’re interested in extending the magic table, improving the detection logic, refining the API, or helping clean up the codebase, contributions are very welcome. Suggestions, issues, and pull requests that help improve correctness, clarity, or idiomatic Zig usage are especially appreciated.

The goal of this project is to provide a dependency-free library that identifies files using heuristics similar to the `file` command but this is far from being a reality right now (currently, 42 out of 85 tests from the `file` repository fail to produce the same mime results as the ones produce by `file` itself).

# 📦 Zig FileType Detector

A dependency‑free file type detection library written in Zig.
It identifies files using magic numbers, lightweight heuristics, and content‑based analysis, not just extensions.

This project includes:

- A Zig library for detecting file types
- A comprehensive magic‑number table covering images, audio, video, archives, executables, documents, fonts, and more
- A tiny CLI tool for testing and debugging
- Fully cross‑platform (Windows, Linux, macOS)

# ✨ Features

- 🔍 Content‑based detection using magic numbers
- 🧠 Text vs binary heuristic for unknown formats
- ⚡ Fast: reads only the first few KB of a file
- 🧱 Zero dependencies
- 🖥️ Cross‑platform (Zig standard library)
- 🛠️ Includes a CLI tool for quick testing

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

## 📦 Installing with Zig Package Manager

You can add **zmime** to your project using `zig fetch`:

```sh
zig fetch --save git+https://github.com/avac74/zmime
```

## Import the module in build.zig

Inside your `build` function:

```zig
const zmime = b.dependency("zmime", .{}).module("zmime");
exe.addModule("zmime", zmime);
```

You can also check the [example](https://github.com/avac74/zmime/blob/master/src/main.zig) which is a very simple CLI using the library.

## Use it in your code

```zig
const zmime = @import("zmime.zig");

pub fn main() !void {
    const info = try zmime.detectFileInfo("example.pdf");
    std.log.info("File type: {s}, MIME: {s}", .{
        @tagName(info.file_type),
        zmime.mimeToString(info.mime),
    });

    // you can also just check if a file is (likely) text or binary
    const is_test = try zmime.isTextFile(file_name);
    if (is_test) {
        std.log.info("File {s} is a text file", .{file_name});
    } else {
        std.log.info("File {s} is a binary file", .{file_name});
    }
}
```

# 🗺️ Roadmap

This project aims to provide a fast, reliable, and extensible file‑type detection system built entirely in Zig.
Below is the current roadmap, including completed features and planned enhancements.

|     |                                         |
| --- | --------------------------------------- |
| ✅   | Magic-number detection                  |
| ✅   | Text vs binary heuristic                |
| ✅   | File extension fallback                 |
| ❌   | Secondary lightweight analysis          |
| ✅   | MIME type mapping                       |
| ❌   | Encoding detection (UTF-8, UTF-16, etc) |
| ❌   | Source code detection                   |
| ❌   | Benchmark suite (in progress)           |
| ❌   | Fuzz testing                            |
