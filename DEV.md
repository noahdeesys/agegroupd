# Development

### Dependencies
The project requires a D-Bus library. You can compile against either `basu` (for Alpine/Gentoo/non-systemd) or standard `systemd`. 

### Compiling manually

To compile using **basu**:
```sh
zig build-lib agegroup.zig -O Debug -lc -lbasu -I. -fcompiler-rt
zig build-exe agegroupd.zig dbus_vtable.c -O Debug -lc -lbasu -I.
```

To compile using **systemd** (Ubuntu, Fedora, Arch):
```sh
zig build-lib agegroup.zig -O Debug -lc -lsystemd -I. -fcompiler-rt -cflags -DUSE_SYSTEMD --
zig build-exe agegroupd.zig dbus_vtable.c -O Debug -lc -lsystemd -I. -cflags -DUSE_SYSTEMD --
```

*(Note: `libagegroup` is explicitly compiled as a static library (`.a`) to prevent `LD_PRELOAD` bypass attacks by sandboxed applications).*

### Getting up and running (Local Testing)

Set up the system D-Bus policy and the daemon's user/group:
```sh
doas cp io.github.noahdeesys.AgeGroup.conf /etc/dbus-1/system.d/
doas groupadd agegroup
doas useradd -r -g agegroup -s /sbin/nologin agegroupd
doas touch /etc/agegroup
doas chown root:agegroup /etc/agegroup
doas chmod 0640 /etc/agegroup
```

Add yourself to the configuration file so you can test it:
```sh
echo "1000($(whoami)):18+" | doas tee /etc/agegroup
```

Start the daemon in the background:
```sh
doas -u agegroupd ./agegroupd &
```

Compile and run the test program against the static library:
```sh
gcc test.c libagegroup.a -lbasu -o test
./test
```

If all goes well, you should see:
```text
My bracket is: 18+
I am allowed in the 18+ club.
```

