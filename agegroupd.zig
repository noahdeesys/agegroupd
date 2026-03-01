// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Noah Dee <noah@iroha.ca>

const std = @import("std");
const c = @cImport({
    @cInclude("agegroup_bus.h");
});

const parser = @import("parser.zig"); 

fn getSenderUid(msg: ?*c.sd_bus_message) !u32 {
    var creds: ?*c.sd_bus_creds = null;
    
    // SD_BUS_CREDS_EUID tells the kernel to give us the Effective User ID
    if (c.sd_bus_query_sender_creds(msg, c.SD_BUS_CREDS_EUID, &creds) < 0) {
        return error.FailedToGetCreds;
    }
    defer _ = c.sd_bus_creds_unref(creds);

    var euid: u32 = 0;
    if (c.sd_bus_creds_get_euid(creds, &euid) < 0) {
        return error.FailedToGetEuid;
    }
    
    return euid;
}

/// Handler for: io.github.noahdeesys.AgeGroup.Bracket() -> string
export fn method_Bracket(msg: ?*c.sd_bus_message, userdata: ?*anyopaque, err: ?*c.sd_bus_error) callconv(.C) c_int {
    _ = userdata;
    _ = err;

    const caller_uid = getSenderUid(msg) catch {
        return c.sd_bus_reply_method_return(msg, "s", "unavail");
    };
    const bracket_str = parser.getBracketForUid(caller_uid);
    return c.sd_bus_reply_method_return(msg, "s", bracket_str);
}

/// Handler for: io.github.noahdeesys.AgeGroup.Check(uint8 target_age) -> bool
export fn method_Check(msg: ?*c.sd_bus_message, userdata: ?*anyopaque, err: ?*c.sd_bus_error) callconv(.C) c_int {
    _ = userdata;
    _ = err;

    var target_age: u8 = 0;
    if (c.sd_bus_message_read(msg, "y", &target_age) < 0) {
        return c.sd_bus_reply_method_return(msg, "b", @as(c_int, 0)); // Return false
    }

    const caller_uid = getSenderUid(msg) catch {
        return c.sd_bus_reply_method_return(msg, "b", @as(c_int, 0)); // Fail closed
    };

    const bracket_str = parser.getBracketForUid(caller_uid);
    const b_str = std.mem.span(bracket_str);
    const is_old_enough: c_int = if (
        (target_age <= 12 and !std.mem.eql(u8, b_str, "unavail")) or 
        (target_age <= 15 and (std.mem.eql(u8, b_str, "13-15") or std.mem.eql(u8, b_str, "16-17") or std.mem.eql(u8, b_str, "18+"))) or
        (target_age <= 17 and (std.mem.eql(u8, b_str, "16-17") or std.mem.eql(u8, b_str, "18+"))) or
        (target_age >= 18 and std.mem.eql(u8, b_str, "18+"))
    ) 1 else 0;

    return c.sd_bus_reply_method_return(msg, "b", is_old_enough);
}

// The D-Bus VTable (dbus_vtable.c)
extern const agegroup_vtable: c.struct_sd_bus_vtable;

pub fn main() !void {
    var bus: ?*c.sd_bus = null;

    // Connect to D-Bus
    if (c.sd_bus_open_system(&bus) < 0) {
        std.debug.print("Fatal: Could not connect to System Bus.\n", .{});
        return error.DBusConnectionFailed;
    }
    defer _ = c.sd_bus_flush_close_unref(bus);

    if (c.sd_bus_add_object_vtable(
        bus,
        null,
        "/io/github/noahdeesys/AgeGroup", 
        "io.github.noahdeesys.AgeGroup",  
        &agegroup_vtable, // CHANGE 3: Pass the pointer to the C vtable here
        null,
    ) < 0) {
        std.debug.print("Fatal: Could not create D-Bus object.\n", .{});
        return error.DBusObjectFailed;
    }

    // Claim the name on the bus (requires XML policy to be installed)
    if (c.sd_bus_request_name(bus, "io.github.noahdeesys.AgeGroup", 0) < 0) {
        std.debug.print("Fatal: Could not claim name. Check /etc/dbus-1/system.d/ XML policy.\n", .{});
        return error.DBusNameFailed;
    }

    std.debug.print("agegroupd is running. Listening for sandboxed apps...\n", .{});

    while (true) {
        if (c.sd_bus_process(bus, null) < 0) break; // Process pending messages
        if (c.sd_bus_wait(bus, std.math.maxInt(u64)) < 0) break; // Sleep until a message arrives
    }
}
