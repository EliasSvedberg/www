const std = @import("std");
const Server = @import("Server.zig");
const Config = @import("Config.zig");

const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const config: Config = .{
        .address = "127.0.0.1",
        .port = 8080,
        .threadCount = 10,
    };

    var server: Server = try .init(allocator, config);
    defer server.deinit();

    try server.start();
    defer server.stop();
}
