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
            "-Wall",
            "-Wextra",
            "-Werror",
            "-Wno-error=empty-translation-unit",
            "-pedantic",
            "-fno-strict-overflow",
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
    mod.addCMacro("_GNU_SOURCE", "");
    mod.addCMacro("_unused", "");

    const dead_def: ?enum { @"__attribute__((__noreturn__))" } = if (target.result.os.tag == .macos)
        null
    else
        .@"__attribute__((__noreturn__))";

    const config_h = b.addConfigHeader(.{
        .include_path = "config.h",
        .style = .blank,
    }, .{
        .__dead = dead_def,
        .HAVE_PROGNAME = if (target.result.isMinGW()) null else {},
        .HAVE_ASPRINTF = {},
        .HAVE_REALLOCARRAY = if (target.result.os.tag == .windows or target.result.os.tag == .macos) null else {},
        .HAVE_STRLCPY = if (target.result.isGnuLibC() or target.result.isMinGW()) null else {},
    });
    mod.addIncludePath(b.path(""));
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
