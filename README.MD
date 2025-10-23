# Parse a .m3u8 metadata file then download and merge all the transport video streaming files associated

## ZIG

### commands

**zig build-exe ./src/main.zig -O ReleaseSafe -fstrip -fsingle-threaded -output-dir ./dist/**

## FFMPEG

### commands

**ffmpeg -i "https://stream.mux.com/1HAyws81NkKNnQmkdlZOrIXBXgnPbn4Xsdkev7s9t5E.m3u8?max_resolution=2160p&min_resolution=540p&redundant_streams=true&CMCD=cid%3D%22lesson-hcaw9%22%2Csid%3D%22a02e0066-154e-4185-b880-76070fe9654e%22" -c copy -bsf:a aac_adtstoasc 10_streaming_objects.mp4**

**ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -f concat -safe 0 -i file.txt -c copy output.mp4**

- -protocol_whitelist: list of protocols allowed
- -f concat: This specifies that you are using the concat demuxer.
- -safe 0: This allows the use of unsafe file paths, which is useful if your file paths contain special characters or are absolute paths. If your paths are safe, you can omit this option.
- -i file.txt: This indicates the input file, which is your list of video files.
- -c copy: This means to copy the codecs. It avoids re-encoding the video, which preserves the original quality and speeds up the processing.
- output.mp4: This is the name of the output file that will contain the concatenated videos.


De retour de Chine. Voici tout ce que j'ai appris en développement mobile pendant mon séjour :

Rien. J'ai juste pris des vacances.

Et 2 kilos.

#DevLife #WorkLifeBalance
