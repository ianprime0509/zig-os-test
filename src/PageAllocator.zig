//! A horribly inefficient, but simple, physical page allocator.

/// Used pages. A present value means the page is used.
used_pages: [max_pages]bool = std.mem.zeroes([max_pages]bool),
first_page: usize = undefined,
last_page: usize = undefined,

const std = @import("std");

const PageAllocator = @This();

const page_size = 1 << 12;
const max_pages = 1 << 20;

pub const vtable = std.mem.Allocator.VTable{
    .alloc = alloc,
    .resize = resize,
    .free = free,
};

fn alloc(context: *anyopaque, n: usize, _: u8, _: usize) ?[*]u8 {
    const allocator: *PageAllocator = @ptrCast(@alignCast(context));

    if (n > std.math.maxInt(usize) - (page_size - 1)) return null;
    const pages_needed = (n + page_size - 1) / page_size;

    var start_page = allocator.nextFreePage(allocator.first_page) orelse return null;
    var end_page = start_page + 1;
    while (end_page - start_page < pages_needed) : (end_page += 1) {
        if (end_page > allocator.last_page) return null;
        if (allocator.used_pages[end_page]) {
            start_page = allocator.nextFreePage(end_page) orelse return null;
        }
    }
    @memset(allocator.used_pages[start_page..end_page], true);
    return @ptrFromInt(start_page * page_size);
}

fn resize(context: *anyopaque, buf_unaligned: []u8, _: u8, new_size: usize, _: usize) bool {
    const allocator: *PageAllocator = @ptrCast(@alignCast(context));

    const start_page = @intFromPtr(buf_unaligned.ptr) / page_size;
    const old_end_page = start_page + buf_unaligned.len / page_size + 1;
    const new_end_page = start_page + new_size / page_size + 1;
    switch (std.math.order(new_end_page, old_end_page)) {
        .eq => return true,
        .lt => {
            @memset(allocator.used_pages[new_end_page..old_end_page], false);
            return true;
        },
        .gt => {
            for (old_end_page..new_end_page) |i| {
                if (allocator.used_pages[i]) return false;
            }
            @memset(allocator.used_pages[old_end_page..new_end_page], true);
            return true;
        },
    }
}

fn free(context: *anyopaque, slice: []u8, _: u8, _: usize) void {
    const allocator: *PageAllocator = @ptrCast(@alignCast(context));
    const start_page = @intFromPtr(slice.ptr) / page_size;
    const end_page = start_page + slice.len / page_size + 1;
    @memset(allocator.used_pages[start_page..end_page], false);
}

fn nextFreePage(allocator: *PageAllocator, start_page: usize) ?usize {
    var page = start_page;
    while (page < allocator.last_page) : (page += 1) {
        if (!allocator.used_pages[page]) return page;
    }
    return null;
}
