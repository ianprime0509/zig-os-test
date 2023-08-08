const std = @import("std");
const gdt = @import("gdt.zig");
const multiboot = @import("multiboot.zig");
const SerialPort = @import("SerialPort.zig");
const heap = @import("heap.zig");

extern const kernel_end_sym: u8;

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

    const mbi = multiboot.MultibootInfo.get() orelse std.debug.panic("No Multiboot info available", .{});
    if (!mbi.flags.mmap_info_available) std.debug.panic("No memory map info available", .{});
    const kernel_end = @intFromPtr(&kernel_end_sym);
    heap.page_allocator_state.first_page = kernel_end / heap.page_size + 1;
    var iter = mbi.mmapIterator();
    while (iter.next()) |entry| {
        if (entry.type == .available and entry.base_addr + entry.length > kernel_end) {
            heap.page_allocator_state.last_page = @as(usize, @intCast(entry.base_addr + entry.length)) / heap.page_size;
            break;
        }
    } else std.debug.panic("No usable memory found", .{});

    kmain() catch |e| std.debug.panic("kmain exited with error: {}", .{e});
    std.debug.panic("kmain exited", .{});
}

pub fn kmain() !void {
    const out = SerialPort.com1.writer();
    try out.print("{} pages of memory available\n", .{heap.page_allocator_state.last_page - heap.page_allocator_state.first_page + 1});
    {
        const page = try heap.page_allocator.alloc(u8, 4096);
        try out.print("Wow it's a page: {X}\n", .{@intFromPtr(page.ptr)});
    }
    {
        const page = try heap.page_allocator.alloc(u8, 4096 * 10);
        try out.print("Another one: {X}\n", .{@intFromPtr(page.ptr)});
    }
    {
        const page = try heap.page_allocator.alloc(u8, 4096 * 100);
        try out.print("ANOTHER ONE: {X}\n", .{@intFromPtr(page.ptr)});
    }
    return error.SkillIssue;
}
