const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        // b.standardOptimizeOption(.{})
        .optimize = .ReleaseSafe,
    });

    b.installArtifact(exe);
}
