const std = @import("std");
const PageAllocator = @import("PageAllocator.zig");

pub const page_size = 1 << 12;

pub var page_allocator_state = PageAllocator{};
pub const page_allocator = std.mem.Allocator{
    .ptr = &page_allocator_state,
    .vtable = &PageAllocator.vtable,
};
