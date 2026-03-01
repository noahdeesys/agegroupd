#include "agegroup_bus.h"

// Forward-declare the Zig functions so C knows they exist
int method_Bracket(sd_bus_message *m, void *userdata, sd_bus_error *ret_error);
int method_Check(sd_bus_message *m, void *userdata, sd_bus_error *ret_error);

// Build the array using the official, safe macros
const sd_bus_vtable agegroup_vtable[] = {
    SD_BUS_VTABLE_START(0),
    SD_BUS_METHOD("Bracket", "", "s", method_Bracket, SD_BUS_VTABLE_UNPRIVILEGED),
    SD_BUS_METHOD("Check", "y", "b", method_Check, SD_BUS_VTABLE_UNPRIVILEGED),
    SD_BUS_VTABLE_END
};
