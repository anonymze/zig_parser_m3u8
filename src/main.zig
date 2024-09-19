const std = @import("std");
const http = std.http;
const fs = std.fs;
const Uri = std.Uri;
const Allocator = std.mem.Allocator;
const Child = std.process.Child;
const eql = std.mem.eql;
const print = std.debug.print;
const expect = std.testing.expect;

const BASE_URL = "https://mayi22140.mayicloud.com/files/aa/";
const FILE = "kYo4hQwhOQOF7UvF8LSDcJb6xP3wVBKfA8k.m3u8";
const HEADER_TYPE = "application/vnd.apple.mpegurl";
const FFMPEG_COMMAND = [_][]const u8{ "ffmpeg", "-protocol_whitelist", "file,http,https,tcp,tls,crypto", "-f", "concat", "-safe", "0", "-i", "file.txt", "-c", "copy", "output.mp4" };

const FetchFileError = Uri.ParseError || error{ IncorrectHeader, IncorrectResponseStatus, UrlConnectionError };

pub fn main() !void {
    // create an allocator (will be needed for things we can't know the size)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    const body_m3u8 = fetchFile(BASE_URL ++ FILE, allocator, HEADER_TYPE) catch |err| {
        return logError(err);
    };

    defer allocator.free(body_m3u8);
    // print("Content:\n{s}\n", .{body_m3u8});

    const list = try readContentFile(body_m3u8, allocator);
    defer allocator.free(list);

    try createFileAndPopulate(list, allocator);
    try startFfmpegCommand();
}

fn readContentFile(body: []u8, allocator: Allocator) ![][]u8 {
    const page_alloc = std.heap.page_allocator;

    var list = std.ArrayList([]u8).init(allocator);
    errdefer list.deinit();

    // TODO WHY NEED PAGE_ALLOCATOR AND ALLOCATOR PARAM NOT WORKING ???
    var file = std.ArrayList(u8).init(page_alloc);
    defer file.deinit();

    for (body[2..], 2..) |character, idx| {

        // '.' , 't', 's'
        if (body[idx - 2] == 46 and body[idx - 1] == 116 and character == 115) {
            var count: u8 = 0;

            while (body[idx - count] != 10 and idx >= count) {
                try file.insert(0, body[idx - count]);
                count += 1;
            }

            const filename = try file.toOwnedSlice();
            try list.append(filename);
        }
    }

    return try list.toOwnedSlice();
}

fn fetchFile(url: []const u8, allocator: Allocator, forced_header: ?[]const u8) (FetchFileError || Allocator.Error)![]u8 {
    // create an HTTP client.
    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    // verify it is a valid URL
    const uri = try Uri.parse(url);

    // URL is valid so we start creating the buffer_url allocation needed for the header (2 MegaBytes here)
    const buff = try allocator.alloc(u8, 1024 * 1024 * 2);
    defer allocator.free(buff);

    // open a connection
    var req = client.open(.GET, uri, .{
        // you have to handle the allocation size of the entire header yourself, so we give the buffer_url created before
        .server_header_buffer = buff,
    }) catch return FetchFileError.UrlConnectionError;

    defer req.deinit();

    // send request headers
    req.send() catch unreachable;

    // finish the body of the request
    // req.finish() catch unreachable;

    // wait response returned
    req.wait() catch unreachable;

    var iter = req.response.iterateHeaders();
    while (iter.next()) |header| {
        // print("Name:{s}, Value:{s}\n", .{ header.name, header.value });

        if (forced_header) |value| {
            if (eql(u8, header.name, "Content-Type") and !eql(u8, header.value, value)) {
                return FetchFileError.IncorrectHeader;
            }
        }
    }

    if (req.response.status != .ok) return FetchFileError.IncorrectResponseStatus;
    // std.testing.expectEqual(req.response.status, .ok) catch return FetchFileError.IncorrectResponseStatus;

    var readerBody = req.reader();
    const body = readerBody.readAllAlloc(allocator, 1024 * 1024 * 4) catch return Allocator.Error.OutOfMemory;

    return body;
}

fn logError(err: anyerror) !void {
    switch (err) {
        // FETCH
        FetchFileError.IncorrectHeader => {
            std.log.err("Header Content-Type. It needs to be '{s}'", .{HEADER_TYPE});
        },
        FetchFileError.IncorrectResponseStatus => {
            std.log.err("The server response is not 200", .{});
        },
        FetchFileError.UrlConnectionError => {
            std.log.err("The connection to the URL seems to fail", .{});
        },
        FetchFileError.InvalidFormat => {
            std.log.err("The URL is not valid URL", .{});
        },
        FetchFileError.UnexpectedCharacter => {
            std.log.err("Unexpected character in the URL", .{});
        },
        FetchFileError.InvalidPort => {
            std.log.err("The URL port is not valid", .{});
        },
        // ALLOCATOR
        Allocator.Error.OutOfMemory => {
            std.log.err("Out of memory. Request or headers may be too big or computer not enough space", .{});
        },
        // OTHER
        else => {
            std.log.err("Error not handled : {}", .{err});
        },
    }

    return;
}

fn createFileAndPopulate(content: [][]u8, allocator: Allocator) !void {
    const cwd = try fs.cwd().realpathAlloc(allocator, ".");
    std.debug.print("{s}", .{cwd});
    allocator.free(cwd);

    const file_ts = try fs.Dir.createFile(fs.cwd(), "file.txt", .{});
    defer file_ts.close();

    const writer = file_ts.writer();

    for (content) |file| {
        var buffer_url = try allocator.alloc(u8, BASE_URL.len + file.len);

        // sliced last index is not inclusive
        std.mem.copyForwards(u8, buffer_url[0..BASE_URL.len], BASE_URL);
        std.mem.copyForwards(u8, buffer_url[BASE_URL.len..], file);

        try writer.writeAll("file '");
        try writer.writeAll(buffer_url);
        try writer.writeAll("'\n");

        allocator.free(buffer_url);
    }
}

fn startFfmpegCommand() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const argv = FFMPEG_COMMAND;

    // by default, child will inherit stdout & stderr from its parents
    // you can collect them out and show it the way you want. I.E : https://cookbook.ziglang.cc/08-02-external.html
    var child = Child.init(&argv, allocator);

    const term = try child.spawnAndWait();

    try std.testing.expectEqual(term.Exited, 0);
}
