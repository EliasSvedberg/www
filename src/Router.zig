const std = @import("std");

const Allocator = std.mem.Allocator;
const Request = std.http.Server.Request;

const Map = std.StringHashMapUnmanaged;
const Router = @This();

allocator: Allocator,
postMap: Map(*const fn (request: *Request) anyerror!void),
getMap: Map(*const fn (request: *Request) anyerror!void),

pub fn init(allocator: Allocator) Router {
    return .{
        .allocator = allocator,
        .getMap = .empty,
        .postMap = .empty,
    };
}

pub fn get(self: *Router, path: []const u8, callback: *const fn (request: *Request) anyerror!void) !void {
    try self.getMap.put(self.allocator, path, callback);
}

pub fn post(self: *Router, path: []const u8, callback: *const fn (request: *Request) anyerror!void) !void {
    try self.postMap.put(self.allocator, path, callback);
}

pub fn _get(self: *Router, path: []const u8) ?*const fn (request: *Request) anyerror!void {
    return self.getMap.get(path);
}

pub fn _post(self: *Router, path: []const u8) ?*const fn (request: *Request) anyerror!void {
    return self.postMap.get(path);
}
