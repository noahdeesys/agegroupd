# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-group

DESCRIPTION="Group for the agegroupd daemon"
ACCT_GROUP_ID=-1 # Lets Gentoo pick the next available GID automatically
