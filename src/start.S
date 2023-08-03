.section .bss
.align 16
stack_bottom:
.skip 16 << 10
stack_top:

.global multiboot_magic
multiboot_magic:    .skip 4
.global multiboot_info
multiboot_info:     .skip 4

.section .text
.global _start
.type _start, @function
_start:
    // Save Multiboot info before doing anything else
    movl %eax, multiboot_magic
    movl %ebx, multiboot_info

    // Some built-in functions (such as memset) use SSE instructions.
    // We need to enable SSE as soon as possible to prevent faulting when such
    // functions are called.
    movl %cr0, %eax
    andw $0xFFFB, %ax
    orw $0x2, %ax
    movl %eax, %cr0
    movl %cr4, %eax
    orw $0x600, %ax
    movl %eax, %cr4

    // Set up stack
    mov $stack_top, %esp

    // Finally out of assembly code!
    call kstart

    // If kstart returns (it shouldn't), halt the processor
    cli
1:  hlt
    jmp 1b
