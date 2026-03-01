#pragma once

#ifdef USE_SYSTEMD
    #include <systemd/sd-bus.h>
#else
    #include <basu/sd-bus.h>
#endif

