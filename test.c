// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Noah Dee <noah@iroha.ca>

#include <stdio.h>
#include <stdbool.h>
#include "libagegroup.h"

int main() {

    printf("My bracket is: %s\n", agegroup_bracket());
    
    if (agegroup_check(18)) {
        printf("I am allowed in the 18+ club.\n");
    } else {
        printf("Access denied.\n");
    }
    return 0;
}
