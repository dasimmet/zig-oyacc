const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const yacc_dep = b.dependency("yacc", .{});

    const mod = b.addModule("yacc", .{
        .target = target,
        .optimize = optimize,
    });
    mod.link_libc = true;
    mod.addIncludePath(yacc_dep.path(""));
    mod.addCSourceFiles(.{
        .root = yacc_dep.path(""),
        .flags = &.{
            "-D_GNU_SOURCE",
            "-D__unused=",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-Wno-error=empty-translation-unit",
            "-pedantic",
        },
        .files = &.{
            "closure.c",
            "error.c",
            "lalr.c",
            "lr0.c",
            "main.c",
            "mkpar.c",
            "output.c",
            "reader.c",
            "skeleton.c",
            "symtab.c",
            "verbose.c",
            "warshall.c",
            "portable.c",
        },
    });
    const config_h = b.addConfigHeader(.{
        .include_path = "config.h",
        .style = .blank,
    }, .{
        .__dead = .@"__attribute__((__noreturn__))",
        .HAVE_PROGNAME = {},
        .HAVE_ASPRINTF = {},
        .HAVE_REALLOCARRAY = {},
        .HAVE_STRLCPY = {},
    });
    mod.addIncludePath(config_h.getOutputDir());

    const exe = b.addExecutable(.{
        .name = "yacc",
        .root_module = mod,
    });
    b.installArtifact(exe);
    const run = b.addRunArtifact(exe);
    if (b.args) |args| {
        run.addArgs(args);
    }
    b.step("run", "run yacc").dependOn(&run.step);
}
