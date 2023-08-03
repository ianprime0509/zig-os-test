pub const MultibootHeader = extern struct {
    magic: u32 align(1) = magic,
    flags: Flags align(1),
    checksum: u32 align(1),

    pub const magic: u32 = 0x1BADB002;

    pub const Flags = packed struct(u32) {
        page_align_modules: bool,
        include_memory_info: bool,
        include_video_info: bool,
        _: u29 = 0,
    };

    pub fn init(flags: Flags) MultibootHeader {
        const checksum: u32 = -%(magic + @as(u32, @bitCast(flags)));
        return .{
            .flags = flags,
            .checksum = checksum,
        };
    }
};

export const multiboot_header: MultibootHeader align(4) linksection(".multiboot") = MultibootHeader.init(.{
    .page_align_modules = true,
    .include_memory_info = true,
    .include_video_info = false, // QEMU doesn't seem to support this
});

extern const multiboot_magic: u32;
extern const multiboot_info: *const MultibootInfo;

pub const MultibootInfo = extern struct {
    // TODO: refine these types
    flags: Flags align(1),
    mem_lower: u32 align(1),
    mem_upper: u32 align(1),
    boot_device: u32 align(1),
    cmdline: u32 align(1),
    mods_count: u32 align(1),
    mods_addr: u32 align(1),
    syms: u32 align(1),
    mmap_length: u32 align(1),
    mmap_addr: u32 align(1),
    drives_length: u32 align(1),
    drives_addr: u32 align(1),
    config_table: u32 align(1),
    boot_loader_name: u32 align(1),
    apm_table: u32 align(1),
    vbe_control_info: u32 align(1),
    vbe_mode_info: u32 align(1),
    vbe_mode: u16 align(1),
    vbe_interface_seg: u16 align(1),
    vbe_interface_off: u16 align(1),
    vbe_interface_len: u16 align(1),
    framebuffer_addr: u64 align(1),
    framebuffer_pitch: u32 align(1),
    framebuffer_width: u32 align(1),
    framebuffer_height: u32 align(1),
    framebuffer_bpp: u8 align(1),
    framebuffer_type: u8 align(1),
    color_info: [5]u8 align(1),

    pub const Flags = packed struct(u32) {
        mem_info_available: bool,
        boot_device_available: bool,
        cmdline_available: bool,
        mods_available: bool,
        aout_symbols_available: bool,
        elf_symbols_available: bool,
        mmap_info_available: bool,
        drive_info_available: bool,
        config_table_available: bool,
        boot_loader_name_available: bool,
        apm_table_available: bool,
        vbe_info_available: bool,
        framebuffer_info_available: bool,
        _: u19,
    };

    const expected_magic: u32 = 0x2BADB002;

    pub fn get() ?*const MultibootInfo {
        return if (multiboot_magic == expected_magic) multiboot_info else null;
    }
};
