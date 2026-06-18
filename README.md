# MinGW "95+" Toolchain

GCC 12.5 / MinGW 14 toolchain for Windows 95 target.

## Releases

You can grab a Linux (amd64) and a Windows 95 (i586) build in [Releases](https://github.com/ati9550/mingw-95/releases).

*Note that currently Link Time Optimization does not work on Windows 95, use `-fno-lto` to disable it.*

## Build

First you build a cross compiler, optionally you can build a compiler to run it on Windows.

Install compilation dependencies. For a Debian-based distribution it will be something like this:


```bash
sudo apt install build-essential bison flex texinfo wget git zip
```

Clone the repo:

```bash
git clone https://github.com/ati9550/mingw-95.git
cd mingw-95

```

### Linux

Run the build script to build a cross compiler:

```bash
./build.sh
```

### Windows

Run this build script to build a Windows native version:

```bash
./build-windows.sh
```

By default cross compiler from the previous step will be used here to build compiler compatible with Windows 95. Override `CROSS_COMPILE` environment variable to build it with your own if you want to skip the Linux part. By overriding it with default MinGW (`CROSS_COMPILE=/usr/bin/x86_64-w64-mingw32- ./build-windows.sh`) you can build a new-Windows-to-old-Windows cross compiler.

### Download error

Remove the file `download_success.log` in case you want to download sources again.

## Usage

If you building it yourself, your toolchain should be placed at the `build` directory, use environment variables to incorporate it in your build system of choice as you usually would for cross compilation.

Note that it has no flag overrides, so you might need to add some if your project checks for `WINVER` and such:

```bash
"$PREFIX/bin/i586-w64-mingw32-g++" main.cpp -o main.exe -static-libstdc++ -D_WIN32_WINNT=0x0400 -DWINVER=0x0400 -D_UNICODE -DUNICODE -lunicows
```

```cmd
C:\path\to\the\toolchain\bin\g++.exe main.cpp -o main.exe -static-libstdc++ -D_WIN32_WINNT=0x0400 -DWINVER=0x0400 -D_UNICODE -DUNICODE -lunicows
```

You should also provide [unicows.dll](https://web.archive.org/web/20160408155534/http://www.microsoft.com/en-us/download/confirmation.aspx?id=4237), if you need Unicode in Windows 95 and link against libunicows as shown earlier. Also make sure not to use `_wfopen` and functions alike, MSVCRT does not support Unicode on 95 and these will silently fail. Use [Microsoft Visual C Runtime 6](https://web.archive.org/web/20120610063726if_/http://download.microsoft.com/download/vc60pro/update/1/w9xnt4/en-us/vc6redistsetup_enu.exe
) to provide `msvcrt.dll`.

## Special thanks

Special thanks to [Julia](https://github.com/I-asked) and [the Fusion Engine Team](https://github.com/TheFusionEngine/FusionEngine) for inspiration and support.

## License

The repository uses GPLv3 as it includes patches that backport functionality from older GCC versions using its source code.