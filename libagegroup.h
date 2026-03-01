// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Noah Dee <noah@iroha.ca>

#ifndef LIBAGEGROUP_H
#define LIBAGEGROUP_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Returns the bracket string ("0-12", "13-15", "16-17", "18+") for the current user.
 * Returns "unavail" if the user is unconfigured or the daemon is unreachable.
 */
const char* agegroup_bracket(void);

/**
 * Returns true if the user's bracket is >= the target_age.
 * Fails closed: If the daemon is unreachable or the user is unconfigured, returns false.
 */
bool agegroup_check(uint8_t target_age);

#ifdef __cplusplus
}
#endif

#endif /* LIBAGEGROUP_H */

