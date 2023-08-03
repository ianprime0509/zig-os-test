pub inline fn outb(port: u16, b: u8) void {
    asm volatile ("outb %%al, %%dx"
        :
        : [port] "{dx}" (port),
          [b] "{al}" (b),
        : "memory"
    );
}

pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %%dx, %%al"
        : [ret] "={al}" (-> u8),
        : [port] "{dx}" (port),
        : "memory"
    );
}
