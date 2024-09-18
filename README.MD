# Parse a .m3u8 metadata file then download and merge all the transport video streaming files associated

## BUILD

### command line

zig build-exe ./src/main.zig -O ReleaseSafe -fstrip -fsingle-threaded -output-dir ./dist/