const std = @import("std");
const Config = @import("Config.zig");
const Request = @import("Request.zig");
const Router = @import("Router.zig");

const Allocator = std.mem.Allocator;
const Server = @This();
const Address = std.net.Address;
const ArrayList = std.ArrayList;
const Connection = std.net.Server.Connection;
const Thread = std.Thread;
const http = std.http;

allocator: Allocator,
server: std.net.Server,
workers: []Worker,
_router: Router,

const Worker = struct {
    thread: Thread,
    id: usize,
};

pub fn init(allocator: Allocator, config: Config) !Server {
    var adress = try Address.parseIp4(config.address, config.port);
    const server = try adress.listen(.{
        .reuse_address = true,
    });

    return .{
        .allocator = allocator,
        .server = server,
        .workers = try allocator.alloc(Worker, config.threadCount),
        ._router = .init(allocator),
    };
}

pub fn deinit(self: *Server) void {
    self.server.deinit();
}

pub fn start(self: *Server) !void {
    std.debug.print("starting server\n", .{});

    // spawn workers
    for (1..self.workers.len) |workerId| {
        if (createWorker(self, workerId)) |worker| {
            std.debug.print("successful spawn of thread: {d}\n", .{workerId});
            self.workers[workerId] = worker;
        } else {
            std.debug.print("failed to spawn thread: {d}\n", .{workerId});
        }
    }

    // main thread worker
    std.debug.print("spawning main thread: with id 0\n", .{});
    try self.listen(0);
}

pub fn stop(self: *Server) void {
    self.allocator.free(self.workers);
}

pub fn router(self: *Server) *Router {
    return &self._router;
}

fn createWorker(self: *Server, id: usize) ?Worker {
    const thread = Thread.spawn(.{}, listen, .{ self, id }) catch {
        return null;
    };

    return .{
        .thread = thread,
        .id = id,
    };
}

fn listen(self: *Server, workerId: usize) !void {
    while (true) {
        errdefer {
            std.debug.print("Worker with id: {d} failed.\n", .{workerId});

            std.debug.print("Trying to respawn worker with id: {d}.\n", .{workerId});
            if (createWorker(self, workerId)) |worker| {
                self.workers[workerId] = worker;
                std.debug.print("worker was successfully respawn.", .{});
            } else {
                std.debug.print("failed to respawn worker.", .{});
            }
        }

        var server = self.server;
        const connection = try server.accept();
        {
            const BUF_SIZE = 1024;
            defer connection.stream.close();

            var receive_buffer: [BUF_SIZE]u8 = undefined;
            var send_buffer: [BUF_SIZE]u8 = undefined;

            var connection_reader = connection.stream.reader(&receive_buffer);
            var connection_writer = connection.stream.writer(&send_buffer);

            var http_server: http.Server = .init(
                connection_reader.interface(),
                &connection_writer.interface,
            );

            const req = try http_server.receiveHead();

            var request: Request = try .init(req);
            defer request.deinit(self.allocator);

            try request.parseBody(self.allocator);
            try request.parseQueryParams(self.allocator);

            const callback = switch (request.method()) {
                .GET => self._router._get(request.path()) orelse null,
                .POST => self._router._post(request.path()) orelse null,
                else => @panic("not implemented"),
            };

            if (callback) |cb| {
                try cb(&request, self.allocator);
            }
        }
    }
}
