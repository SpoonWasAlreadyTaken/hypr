local G = require('modules.globals')
------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = G.mainMonitor,
    mode     = "preferred",
    position = "0x0",
    scale    = "auto",
})

hl.monitor({
    output   = G.secondaryMonitor,
    mode     = "preferred",
    position = "1920x0",
    scale    = "auto",
})

