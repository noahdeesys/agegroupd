# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the agegroupd daemon"
ACCT_USER_ID=-1 # Lets Gentoo pick the next available UID automatically
ACCT_USER_GROUPS=( "agegroup" )
ACCT_USER_HOME="/var/empty"

acct-user_add_deps
