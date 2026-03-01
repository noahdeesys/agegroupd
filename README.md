# agegroupd

### Give Parents Control, and relieve the need for ID harvesting.

[agegroup-kde-ui.png]

## Why??

By having parents set their children's ages the OS can be used to verify age,
instead of every online service requiring an ID document or face scan.


## What?

The API returns one of the following age groups,
based on an exact or shifted birth date privately stored:

```
unavail
0-12
13-15
16-17
18+
```

For convenience the API can also be given an age, and it returns true or false
based on if the user is older than the start of the age's bracket.

(This means asking the API `agegroup(14)` doesn't depend on if the user is 14,
but if the user is (at least) 13, as the bracket including 14 is `13-15`.)


## Configuration file

Use the `viagegroup` command to open the file for editing.

`/etc/agegroup`
```/etc/agegroup
1000(noah):18+
1001(su):0=1993-02-08       # Exact birth date (not recommended)
1011:16=2027-10             # The first month the user is 16
(maple):13=2026Q2           # The first quarter the user is 13
```

The file should have permissions `0640` and be owned by `root:agegroup`.

It's recommended (as the GUI defaults to) using a shifted date for the user's
age, as apps can in theory store the results of the checks over time to see
when the user moves between brackets.


## Examples

agegroup(1) binary not yet implemented.

```console
$ date; whoami
Sun Mar  1 03:12:24 -00 2026
maple
$ agegroup
0-12
$ agegroup 14 && echo allow || deny
deny
```

```console
$ date; id
Sun Mar  1 03:21:24 -00 2026
uid=1011(june) gid=1011(june) groups=1011(june),1010(kids)
$ agegroup
13-15
$ agegroup 15 && echo allow || deny
allow
```

`agegroup_check(n)` and `agegroup_bracket()` are implemented using a D-Bus client.

```c
#include <libagegroup.h>
if (agegroup_check(13)) {
    printf("allow")
} else {
    printf("deny")
}
printf(agegroup_bracket())
```


### What's ready

- D-Bus daemon with `/etc/agegroup` configuration file format parser
- Statically-linked D-Bus client library


### What's being worked on

- `agegroup(1)` SGID binary
- Utilities to edit `/etc/agegroup`
- `viagegroup(8)` command inspired by `visudo(8)`
- GUI for editing `/etc/agegroup`


