# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 systemd

DESCRIPTION="Local privacy-preserving age attestation D-Bus daemon and utilities"
HOMEPAGE="https://github.com/noahdeesys/agegroupd"
EGIT_REPO_URI="https://github.com/noahdeesys/agegroupd.git"

LICENSE="AGPL-3 MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="systemd"

DEPEND="
	systemd? ( sys-apps/systemd )
	!systemd? ( sys-libs/basu )
"
RDEPEND="${DEPEND}
	acct-group/agegroup
	acct-user/agegroupd
"
BDEPEND="dev-lang/zig"


src_compile() {
        export ZIG_GLOBAL_CACHE_DIR="${T}/zig-global"
        export ZIG_LOCAL_CACHE_DIR="${T}/zig-local"

        local bus_lib="-lbasu"
        local bus_flag=""

        if use systemd; then
                bus_lib="-lsystemd"
                bus_flag="-DUSE_SYSTEMD"
        fi

        einfo "Building libagegroup static library..."
        zig build-lib agegroup.zig -O ReleaseSafe -lc ${bus_lib} -I. -fcompiler-rt \
                -cflags ${bus_flag} -- -femit-bin=libagegroup.a || die

        einfo "Building agegroupd..."
        zig build-exe agegroupd.zig dbus_vtable.c -O ReleaseSafe -lc ${bus_lib} -I. \
                -cflags ${bus_flag} -- -femit-bin=agegroupd || die
}

src_install() {
        dolib.a libagegroup.a

        insinto /usr/include
        doins libagegroup.h

        dosbin agegroupd

        insinto /usr/share/dbus-1/system.d
        doins io.github.noahdeesys.AgeGroup.conf

        insinto /etc
        newins - agegroup <<< ""
        fowners root:agegroup /etc/agegroup
        fperms 0640 /etc/agegroup

        dodoc README.md DEV.md

        if use systemd; then
                systemd_dounit agegroupd.service
        else
                doinitd agegroupd.initd
        fi
}
