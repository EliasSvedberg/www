const std = @import("std");
const Server = @import("Server.zig");
const Config = @import("Config.zig");

const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const Request = std.http.Server.Request;

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

    var router = server.router();

    // register get route to / with callback
    try router.get("/", callback);

    // register get route to / with callback
    try router.post("/", callback2);

    try server.start();
    defer server.stop();
}

pub fn callback(request: *Request) anyerror!void {
    try request.respond(
        "from get callback",
        .{ .status = .ok, .keep_alive = false },
    );
}

pub fn callback2(request: *Request) anyerror!void {
    try request.respond(
        "from post callback",
        .{ .status = .ok, .keep_alive = false },
    );
}
