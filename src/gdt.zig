const gdt_entries = [_]GdtEntry{
    GdtEntry.null,
    GdtEntry.init(.{ .base = 0, .limit = 0xFFFFF, .access = .{
        .executable = true,
        .type = .code_or_data,
    } }),
    GdtEntry.init(.{ .base = 0, .limit = 0xFFFFF, .access = .{
        .executable = false,
        .type = .code_or_data,
    } }),
};
export const gdt_descriptor = GdtDescriptor.init(&gdt_entries);

pub fn load() void {
    asm volatile ("lgdt gdt_descriptor" ::: "memory");
    asm volatile (
        \\    ljmp $0x08, $n
        \\n:  movw $0x10, %%ax
        \\    movw %%ax, %%ds
        \\    movw %%ax, %%es
        \\    movw %%ax, %%fs
        \\    movw %%ax, %%gs
        \\    movw %%ax, %%ss
        ::: "ax", "ds", "es", "fs", "gs", "ss", "memory");
}

pub const GdtDescriptor = extern struct {
    size: u16,
    offset: [*]const GdtEntry align(2),

    pub fn init(entries: []const GdtEntry) GdtDescriptor {
        return .{
            .size = @intCast(entries.len * @sizeOf(GdtEntry) - 1),
            .offset = entries.ptr,
        };
    }
};

pub const GdtEntry = packed struct(u64) {
    limit_low: u16,
    base_low: u24,
    access: Access,
    limit_high: u4,
    flags: Flags,
    base_high: u8,

    pub const @"null": GdtEntry = init(.{
        .base = 0,
        .limit = 0,
        .access = @bitCast(@as(u8, 0)),
        .flags = @bitCast(@as(u4, 0)),
    });

    pub const Access = packed struct(u8) {
        accessed: bool = false,
        accessible: bool = true,
        direction_conforming: bool = false,
        executable: bool,
        type: enum(u1) { system = 0, code_or_data = 1 },
        privilege_level: u2 = 0,
        present: bool = true,
    };

    pub const Flags = packed struct(u4) {
        _: u1 = 0,
        long: bool = false,
        double: bool = true,
        granularity: enum(u1) { byte = 0, page = 1 } = .page,
    };

    pub const Description = struct {
        base: u32,
        limit: u20,
        access: Access,
        flags: Flags = .{},
    };

    pub fn init(description: Description) GdtEntry {
        return .{
            .limit_low = @intCast(description.limit & 0xFFFF),
            .base_low = @intCast(description.base & 0xFFFFFF),
            .access = description.access,
            .limit_high = @intCast((description.limit >> 16) & 0xF),
            .flags = description.flags,
            .base_high = @intCast((description.base >> 24) & 0xFF),
        };
    }
};
