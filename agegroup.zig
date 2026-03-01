// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Noah Dee <noah@iroha.ca>

const std = @import("std");
const c = @cImport({
    @cInclude("agegroup_bus.h");
});

/// Returns the bracket string ("0-12", "13-15", "16-17", "18+") for the current user.
export fn agegroup_bracket() [*:0]const u8 {
    var bus: ?*c.sd_bus = null;
    var err: c.sd_bus_error = std.mem.zeroes(c.sd_bus_error);
    var msg: ?*c.sd_bus_message = null;
    
    // Default fail-closed fallback
    const default_bracket = "unavail";
    
    // Connect to D-Bus
    if (c.sd_bus_open_system(&bus) < 0) {
        return default_bracket;
    }
    defer _ = c.sd_bus_flush_close_unref(bus);
    
    // Call io.github.noahdeesys.AgeGroup.Bracket()
    if (c.sd_bus_call_method(
        bus,
        "io.github.noahdeesys.AgeGroup",       // Destination service name
        "/io/github/noahdeesys/AgeGroup",      // Object path
        "io.github.noahdeesys.AgeGroup",       // Interface name
        "Bracket",                          // Method name
        &err,
        &msg,
        "",                                 // No arguments sent
    ) < 0) {
        c.sd_bus_error_free(&err);
        return default_bracket;
    }
    defer _ = c.sd_bus_message_unref(msg);
    
    var returned_str: [*c]const u8 = null;
    if (c.sd_bus_message_read(msg, "s", &returned_str) < 0) {
        return "unavail"; // Fail closed
    }
    
    const dbus_slice = std.mem.span(returned_str);

    if (std.mem.eql(u8, dbus_slice, "18+"))   return "18+";
    if (std.mem.eql(u8, dbus_slice, "16-17")) return "16-17";
    if (std.mem.eql(u8, dbus_slice, "13-15")) return "13-15";
    if (std.mem.eql(u8, dbus_slice, "0-12"))  return "0-12";
    
    return "unavail";
}

/// Returns true if the user's bracket is >= the target_age.
/// Fails closed: If the daemon is unreachable, returns false.
export fn agegroup_check(target_age: u8) bool {
    var bus: ?*c.sd_bus = null;
    var err: c.sd_bus_error = std.mem.zeroes(c.sd_bus_error);
    var msg: ?*c.sd_bus_message = null;

    if (c.sd_bus_open_system(&bus) < 0) {
        return false; // Fail closed
    }
    defer _ = c.sd_bus_flush_close_unref(bus);

    // Call io.github.noahdeesys.AgeGroup.Check(target_age)
    if (c.sd_bus_call_method(
        bus,
        "io.github.noahdeesys.AgeGroup", 
        "/io/github/noahdeesys/AgeGroup", 
        "io.github.noahdeesys.AgeGroup", 
        "Check",
        &err,
        &msg,
        "y",          // "y" is the D-Bus signature for a single byte (uint8)
        target_age,
    ) < 0) {
        c.sd_bus_error_free(&err);
        return false; // Fail closed
    }
    defer _ = c.sd_bus_message_unref(msg);

    var result: c_int = 0;
    if (c.sd_bus_message_read(msg, "b", &result) < 0) {
        return false;
    }

    return result != 0;
}
