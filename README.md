# MinGW "95+" Toolchain

GCC 12.5 / MinGW 13 cross compilation toolchain for Windows 95 target.

## Build

Install compilation dependencies. For a Debian-based distribution it will be something like this:


```bash
sudo apt install build-essential bison flex texinfo libgmp-dev libmpfr-dev libmpc-dev wget git zip
```

Clone the repo:

```
git clone https://github.com/ati9550/mingw-95.git
```

Run the build script:

```
cd mingw-95
./build.sh
```

Remove the file `download_success.log` in case you want to download sources again.

## Usage

If you building it yourself, your toolchain should be placed at the `build` directory, use environment variables to incorporate it in your build system of choice as you usually would for cross compilation.

Note that by default it has no flag overrides, so you should add something like that yourself:

```
"$PREFIX/bin/i586-w64-mingw32-g++" main.cpp -o main.exe -D_UNICODE -DUNICODE -D__MSVCRT_VERSION__=0x400 -D_WIN32_WINNT=0x0400 -DWINVER=0x0400 -static -lunicows
```

And you should also provide `unicows.dll` from Microsoft, if you need UTF-8 in Windows 95 and link against libunicows as shown earlier. Use `vc6redistsetup_enu.exe` to provide `msvcrt.dll`.

## License

The repository uses GPLv3 as it includes patches that backport functionality from older GCC versions using its source code.