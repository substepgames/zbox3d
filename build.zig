const std = @import("std");

pub fn build(b: *std.Build) !void {
    // module
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const upstream = b.dependency("box3d", .{});
    const mod = b.addModule("zbox3d", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    // c flags
    var c_flags: std.ArrayList([]const u8) = .empty;
    try c_flags.append(b.allocator, "-std=c17");
    const box3d_double_precision = b.option(bool, "BOX3D_DOUBLE_PRECISION", "") orelse false;
    if (box3d_double_precision) {
        try c_flags.append(b.allocator, "-DBOX3D_DOUBLE_PRECISION");
        mod.addCMacro("BOX3D_DOUBLE_PRECISION", "1");
    }
    const box3d_disable_simd = b.option(bool, "BOX3D_DISABLE_SIMD", "") orelse false;
    if (box3d_disable_simd) {
        try c_flags.append(b.allocator, "-DBOX3D_DISABLE_SIMD");
        mod.addCMacro("BOX3D_DISABLE_SIMD", "1");
    }
    const box3d_validate = b.option(bool, "BOX3D_VALIDATE", "") orelse false;
    if (box3d_validate) {
        try c_flags.append(b.allocator, "-DBOX3D_VALIDATE");
        mod.addCMacro("BOX3D_VALIDATE", "1");
    }
    const box3d_compile_warning_as_error = b.option(bool, "BOX3D_COMPILE_WARNING_AS_ERROR", "") orelse false;
    if (box3d_compile_warning_as_error) {
        // Not sure about this one I think it just sets -Werror if you want that
        // is there not a more standard way to do it?
        return error.CompileWarningAsErrorNotImplemented;
    }
    const box3d_sanitize = b.option(bool, "BOX3D_SANITIZE", "") orelse false;
    if (box3d_sanitize) {
        _ = b.option([]const u8, "BOX3D_SANITIZER_TYPE", "");
        // Requires linking the matching sanitizer runtime.
        return error.Box3dSanitizeNotImplemented;
    }
    if (b.option([]const u8, "BOX3D_USER_CONFIG", "")) |box3d_user_config| {
        const macro_value = b.fmt("\"{s}\"", .{box3d_user_config});
        try c_flags.append(b.allocator, b.fmt("-DBOX3D_USER_CONFIG={s}", .{macro_value}));
        mod.addCMacro("BOX3D_USER_CONFIG", macro_value);
    }
    if (b.option([]const u8, "BOX3D_EXPORT", "")) |box3d_export| {
        try c_flags.append(b.allocator, b.fmt("-DBOX3D_EXPORT={s}", .{box3d_export}));
        mod.addCMacro("BOX3D_EXPORT", box3d_export);
    }
    const b3_enable_assert = b.option(bool, "B3_ENABLE_ASSERT", "") orelse false;
    if (b3_enable_assert) {
        try c_flags.append(b.allocator, "-DB3_ENABLE_ASSERT");
        mod.addCMacro("B3_ENABLE_ASSERT", "1");
    }
    if (b.option(u32, "B3_GYROSCOPIC_ITERATIONS", "")) |b3_gyroscopic_iterations| {
        const macro_value = b.fmt("{}", .{b3_gyroscopic_iterations});
        try c_flags.append(b.allocator, b.fmt("-DB3_GYROSCOPIC_ITERATIONS={s}", .{macro_value}));
        mod.addCMacro("B3_GYROSCOPIC_ITERATIONS", macro_value);
    }
    if (b.option(u32, "B3_RESTITUTION_ITERATIONS", "")) |b3_restitution_iterations| {
        const macro_value = b.fmt("{}", .{b3_restitution_iterations});
        try c_flags.append(b.allocator, b.fmt("-DB3_RESTITUTION_ITERATIONS={s}", .{macro_value}));
        mod.addCMacro("B3_RESTITUTION_ITERATIONS", macro_value);
    }
    const box3d_profile = b.option(bool, "BOX3D_PROFILE", "") orelse false;
    if (box3d_profile) {
        // Requires compiling/linking tracy
        return error.Box3dProfileNotImplemented;
    }

    // source
    mod.addCSourceFiles(.{
        .root = upstream.path("src"),
        .flags = c_flags.items,
        .files = &.{
            "aabb.c",
            "arena_allocator.c",
            "bitset.c",
            "block_allocator.c",
            "body.c",
            "broad_phase.c",
            "capsule.c",
            "compound.c",
            "constraint_graph.c",
            "contact.c",
            "contact_solver.c",
            "convex_manifold.c",
            "core.c",
            "distance.c",
            "distance_joint.c",
            "dynamic_tree.c",
            "height_field.c",
            "hull.c",
            "id_pool.c",
            "island.c",
            "joint.c",
            "manifold.c",
            "math_functions.c",
            "mesh.c",
            "mesh_contact.c",
            "motor_joint.c",
            "mover.c",
            "name_cache.c",
            "parallel_for.c",
            "parallel_joint.c",
            "physics_world.c",
            "prismatic_joint.c",
            "recording.c",
            "recording_replay.c",
            "revolute_joint.c",
            "scheduler.c",
            "sensor.c",
            "shape.c",
            "simd.c",
            "solver.c",
            "solver_set.c",
            "sphere.c",
            "spherical_joint.c",
            "table.c",
            "timer.c",
            "triangle_manifold.c",
            "types.c",
            "weld_joint.c",
            "wheel_joint.c",
            "world_snapshot.c",
        },
    });
    mod.addIncludePath(upstream.path("include"));
}
