# Parse a .m3u8 metadata file then download and merge all the transport video streaming files associated

## ZIG

### commands

**zig build-exe ./src/main.zig -O ReleaseSafe -fstrip -fsingle-threaded -output-dir ./dist/**

## FFMPEG

### commands

**ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -f concat -safe 0 -i file.txt -c copy output.mp4**

- -protocol_whitelist: list of protocols allowed
- -f concat: This specifies that you are using the concat demuxer.
- -safe 0: This allows the use of unsafe file paths, which is useful if your file paths contain special characters or are absolute paths. If your paths are safe, you can omit this option.
- -i file.txt: This indicates the input file, which is your list of video files.
- -c copy: This means to copy the codecs. It avoids re-encoding the video, which preserves the original quality and speeds up the processing.
- output.mp4: This is the name of the output file that will contain the concatenated videos.

