// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Noah Dee <noah@iroha.ca>

const std = @import("std");
const c = @cImport({
    @cInclude("pwd.h");
});

/// Parses a value string (e.g. "18+", "16=2027-10", "13=2026Q2") 
/// and returns the current age bracket.
pub fn calculateBracket(val_raw: []const u8) [*c]const u8 {
    // Strip inline comments if they exist
    const hash_idx = std.mem.indexOfScalar(u8, val_raw, '#');
    const val = std.mem.trim(u8, if (hash_idx) |i| val_raw[0..i] else val_raw, " \t");
    
    // Static matches
    if (std.mem.eql(u8, val, "18+")) return "18+";
    if (std.mem.eql(u8, val, "16-17")) return "16-17";
    if (std.mem.eql(u8, val, "13-15")) return "13-15";
    if (std.mem.eql(u8, val, "0-12") or std.mem.eql(u8, val, "<13") or val.len == 0) return "0-12";
    
    // Date math parsing
    const eq_idx = std.mem.indexOfScalar(u8, val, '=') orelse return "unavail";
    const target_age_str = val[0..eq_idx];
    const target_age = std.fmt.parseInt(u8, target_age_str, 10) catch return "unavail";
    
    const date_str = val[eq_idx + 1 ..];
    if (date_str.len < 6) return "unavail";
    
    const yyyy = std.fmt.parseInt(i16, date_str[0..4], 10) catch return "unavail";
    var mm: u8 = 1;
    var dd: u8 = 1;
    
    // Handle 2026Q2 vs 2027-10
    if (date_str[4] == 'Q') {
        const q = date_str[5] - '0';
        if (q >= 1 and q <= 4) mm = (q - 1) * 3 + 1 else return "unavail";
    } else if (date_str[4] == '-') {
        mm = std.fmt.parseInt(u8, date_str[5..7], 10) catch return "unavail";
        // Handle exact days (2020-04-03)
        if (date_str.len >= 10 and date_str[7] == '-') {
            dd = std.fmt.parseInt(u8, date_str[8..10], 10) catch return "unavail";
        }
    } else {
        return "unavail";
    }
    
    // Determine the user's base birth year based on the milestone
    const b_year = yyyy - @as(i32, target_age);
    
    // Get current date from the OS securely
    const ts = std.time.timestamp();
    const epoch_secs = std.time.epoch.EpochSeconds{ .secs = @intCast(ts) };
    const epoch_day = epoch_secs.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const c_year = year_day.year;
    const month_day = year_day.calculateMonthDay();
    const c_month = month_day.month.numeric();
    const c_day = month_day.day_index + 1;
    
    if (c_year < b_year) return "0-12";
    
    // Calculate actual age right now
    var age: i32 = c_year - b_year;
    if (c_month < mm or (c_month == mm and c_day < dd)) {
        age -= 1;
    }
    
    // Assign bracket based on calculated age
    if (age >= 18) return "18+";
    if (age >= 16) return "16-17";
    if (age >= 13) return "13-15";
    if (age >= 0)  return "0-12";
    return "unavail";
}

/// Reads /etc/agegroup and finds the bracket for the caller
pub fn getBracketForUid(caller_uid: u32) [*c]const u8 {
    const file = std.fs.openFileAbsolute("/etc/agegroup", .{}) catch return "unavail";
    defer file.close();
    
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined;
    
    while (in_stream.readUntilDelimiterOrEof(&buf, '\n') catch null) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \r\t");
        if (line.len == 0 or line[0] == '#') continue;
        
        var it = std.mem.splitScalar(u8, line, ':');
        const id_part = it.next() orelse continue;
        const val_part = it.next() orelse continue;
        
        var match = false;
        
        // Try numeric UID match (e.g. "1001(su)" or "1011")
        var uid_end: usize = 0;
        while (uid_end < id_part.len and std.ascii.isDigit(id_part[uid_end])) { uid_end += 1; }
        if (uid_end > 0) {
            const parsed_uid = std.fmt.parseInt(u32, id_part[0..uid_end], 10) catch null;
            if (parsed_uid != null and parsed_uid.? == caller_uid) match = true;
        }
        
        // Fallback to username match (e.g. "(maple)")
        if (!match) {
            const p_start = std.mem.indexOfScalar(u8, id_part, '(');
            const p_end = std.mem.indexOfScalar(u8, id_part, ')');
            if (p_start != null and p_end != null and p_end.? > p_start.?) {
                const conf_user = id_part[p_start.? + 1 .. p_end.?];
                
                const pwd = c.getpwuid(caller_uid);
                if (pwd != null) {
                    const sys_user = std.mem.span(pwd.*.pw_name);
                    if (std.mem.eql(u8, conf_user, sys_user)) match = true;
                }
            }
        }

        if (match) return calculateBracket(val_part);
    }
    
    return "unavail";
}
