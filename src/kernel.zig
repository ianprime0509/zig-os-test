const std = @import("std");
const gdt = @import("gdt.zig");
const multiboot = @import("multiboot.zig");
const SerialPort = @import("SerialPort.zig");

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = stack_trace;
    _ = ret_addr;
    @setCold(true);
    const out = SerialPort.com1.writer();
    try out.print("KERNEL PANIC: {s}\n", .{msg});
    asm volatile ("cli");
    while (true) {
        asm volatile ("hlt");
    }
}

export fn kstart() noreturn {
    gdt.load();

    SerialPort.com1.configure(.{});

    kmain() catch |e| std.debug.panic("kmain exited with error: {}", .{e});
    std.debug.panic("kmain exited", .{});
}

pub fn kmain() !void {
    const out = SerialPort.com1.writer();
    if (multiboot.MultibootInfo.get()) |mbi| {
        try out.print("Multiboot info: {}\n", .{mbi});
        if (mbi.flags.mmap_info_available) {
            var iter = mbi.mmapIterator();
            while (iter.next()) |entry| {
                try out.print("Memory map entry: addr={X} len={} type={}\n", .{ entry.base_addr, entry.length, entry.type });
            }
        }
    }
    return error.SkillIssue;
}
