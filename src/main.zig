const std = @import("std");
const http = std.http;
const Uri = std.Uri;
const eql = std.mem.eql;
const print = std.debug.print;
const expect = std.testing.expect;

const BASE_URL = "https://mayi22140.mayicloud.com/files/aa/";
const FILE = "kYo4hQwhOQOF7UvF8LSDcJb6xP3wVBKfA8k.m3u8";
const HEADER_TYPE = "application/vnd.apple.mpegurl";

pub fn main() !void {
    // create an allocator (will be needed for things we can't know the size)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    const body_m3u8 = try fetchFile(BASE_URL ++ FILE, allocator, HEADER_TYPE);
    defer allocator.free(body_m3u8);
    // print("Content:\n{s}\n", .{body_m3u8});

    const list = try readContentFile(body_m3u8, allocator);
    defer allocator.free(list);

    std.debug.print("{s}", .{list});

    for (list) |file| {
        var buffer_url = try allocator.alloc(u8, BASE_URL.len + file.len);

        // sliced last index is not inclusive
        std.mem.copyForwards(u8, buffer_url[0..BASE_URL.len], BASE_URL);
        std.mem.copyForwards(u8, buffer_url[BASE_URL.len..], file);

        const body_ts = try fetchFile(buffer_url, allocator, null);

        allocator.free(buffer_url);
        allocator.free(body_ts);

        // TODO
        break;
    }
}

fn readContentFile(body: []u8, allocator: std.mem.Allocator) ![][]u8 {
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

fn fetchFile(url: []const u8, allocator: std.mem.Allocator, forced_header: ?[]const u8) ![]u8 {
    // create an HTTP client.
    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    // verify it is a valid URL
    const uri = try Uri.parse(url);

    // URL is valid so we start creating the buffer_url allocation needed for the header (2 MegaBytes here)
    const buff = try allocator.alloc(u8, 1024 * 1024 * 4);
    defer allocator.free(buff);

    // open a connection
    var req = try client.open(.GET, uri, .{
        // you have to handle the allocation size of the entire header yourself, so we give the buffer_url created before
        .server_header_buffer = buff,
    });
    defer req.deinit();

    // send request headers
    try req.send();
    // finish the body of the request
    try req.finish();
    // wait response returned
    try req.wait();

    var iter = req.response.iterateHeaders();
    while (iter.next()) |header| {
        // print("Name:{s}, Value:{s}\n", .{ header.name, header.value });

        if (forced_header) |value| {
            // TODO boolean
            if (eql(u8, header.name, "Content-Type") and !eql(u8, header.value, value)) {
                std.log.err("Header Content-Type. It needs to be '{?s}'", .{forced_header});
                // @panic("Wrong header");
            }
        }
    }

    try std.testing.expectEqual(req.response.status, .ok);

    var readerBody = req.reader();
    const body = try readerBody.readAllAlloc(allocator, 1024 * 1024 * 8);

    return body;
}
