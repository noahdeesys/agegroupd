// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Noah Dee <noah@iroha.ca>

#pragma once

#ifdef USE_SYSTEMD
    #include <systemd/sd-bus.h>
#else
    #include <basu/sd-bus.h>
#endif

