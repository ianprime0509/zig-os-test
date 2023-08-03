const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const kernel = b.addExecutable(.{
        .name = "paradiso",
        .target = .{
            .cpu_arch = .x86,
            .os_tag = .freestanding,
            .ofmt = .elf,
        },
        .optimize = optimize,
        .root_source_file = .{ .path = "src/kernel.zig" },
    });
    kernel.linker_script = .{ .path = "linker.ld" };
    kernel.addAssemblyFile(.{ .path = "src/start.S" });
    b.installArtifact(kernel);

    const run = b.addSystemCommand(&.{
        "qemu-system-i386",
        "-serial",
        "stdio",
        "-no-reboot",
    });
    run.addArg("-kernel");
    run.addArtifactArg(kernel);

    const run_step = b.step("run", "Run the OS");
    run_step.dependOn(&run.step);
}
