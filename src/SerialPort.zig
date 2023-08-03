port: u16,

const std = @import("std");
const outb = @import("port.zig").outb;
const inb = @import("port.zig").inb;

const SerialPort = @This();

pub const com1: SerialPort = .{ .port = 0x3F8 };

pub const ConfigureOptions = struct {
    // QEMU doesn't require physical cables, so why not go as fast as possible?
    baud: u32 = 115200,
};

pub fn configure(serial: SerialPort, options: ConfigureOptions) void {
    const divisor: u16 = @intCast(@divExact(115200, options.baud));
    outb(serial.port + 1, 0x00);
    outb(serial.port + 3, 0x80);
    outb(serial.port + 0, @intCast(divisor & 0xFF));
    outb(serial.port + 1, @intCast((divisor >> 8) & 0xFF));
    outb(serial.port + 3, 0x03);
    outb(serial.port + 2, 0xC7);
    outb(serial.port + 4, 0x0F);
}

pub fn write(serial: SerialPort, bytes: []const u8) error{}!usize {
    for (bytes) |b| {
        serial.writeByte(b);
    }
    return bytes.len;
}

pub fn writeByte(serial: SerialPort, b: u8) void {
    while (inb(serial.port + 5) & 0x20 == 0) {}

    outb(serial.port, b);
}

pub fn writer(serial: SerialPort) std.io.Writer(SerialPort, error{}, write) {
    return .{ .context = serial };
}
