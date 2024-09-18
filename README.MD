# PARSE A .m3u8 METADATA FILE AND DOWNLOAD AND MERGE ALL THE TRANSPORT VIDEO STREAMING FILES ASSOCIATED

## BUILD

### command line

zig build-exe ./src/main.zig -O ReleaseSafe -fstrip -fsingle-threaded -output-dir ./dist/