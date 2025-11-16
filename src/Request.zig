const std = @import("std");
const Allocator = std.mem.Allocator;

const Map = std.StringHashMapUnmanaged;

const Request = @This();

_request: std.http.Server.Request,
_body: ?[]const u8,
_queryParams: Map([]const u8),
_method: std.http.Method,
_path: []const u8,

pub fn init(request: std.http.Server.Request) !Request {
    return .{
        ._request = request,
        ._body = null,
        ._queryParams = .empty,
        ._method = request.head.method,
        ._path = request.head.target,
    };
}

pub fn deinit(self: *Request, allocator: Allocator) void {
    if (self._body) |b| {
        allocator.free(b);
    }
    //todo free keys
    self._queryParams.deinit(allocator);
}

pub fn parseBody(self: *Request, allocator: Allocator) !void {
    const body_buffer: []u8 = try allocator.alloc(u8, 4096);
    const body_reader = try self._request.readerExpectContinue(body_buffer);
    self._body = try body_reader.readAlloc(
        allocator,
        self.bodyLen(),
    );
}

pub fn parseQueryParams(self: *Request, allocator: Allocator) !void {
    try self._queryParams.put(allocator, "q1", "q1Value");
}

pub fn body(self: *Request) ?[]const u8 {
    return self._body;
}

pub fn queryParams(self: *Request) ?[]const u8 {
    return self._queryParams.get("q1");
}

pub fn method(self: *Request) std.http.Method {
    return self._method;
}

pub fn path(self: *Request) []const u8 {
    return self._path;
}

pub fn respond(self: *Request, response_body: []const u8, respondOptions: std.http.Server.Request.RespondOptions) !void {
    try self._request.respond(response_body, respondOptions);
}

pub fn bodyLen(self: *Request) usize {
    return self._request.head.content_length orelse 0;
}

//if (request.head.content_length) |body_len| {
//    const body_reader = try request.readerExpectContinue(&body_buffer);

//    const body_payload = try body_reader.readAlloc(
//        self.allocator,
//        body_len,
//    );

//    defer self.allocator.free(body_payload);
//    try request.respond(
//        body_payload,
//        .{ .status = .ok, .keep_alive = false },
//    );
//} else {
//    //try request.respond(
//    //    &.{},
//    //    .{ .status = .ok, .keep_alive = false },
//    //);
//    if (self._router._get(request.head.target)) |callback| {
//        try callback(&request);
//    }
//}
