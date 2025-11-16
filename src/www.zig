const std = @import("std");
const Server = @import("Server.zig");
const Config = @import("Config.zig");
const Request = @import("Request.zig");

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

    var router = server.router();

    // register get route to / with callback
    try router.get("/", callback);

    // register get route to / with callback
    try router.post("/", callback);

    try server.start();
    defer server.stop();
}

pub fn callback(request: *Request, allocator: Allocator) anyerror!void {
    _ = allocator;

    const body = request.body() orelse "";
    const qp = request.queryParams() orelse "";

    std.debug.print("qp: {s}", .{qp});

    try request.respond(
        body,
        .{ .status = .ok, .keep_alive = false },
    );
}
