package reconfigurable_mac_pkg;
  // Runtime modes reserved for the proposed architecture.
  typedef enum logic [1:0] { MODE_INT8 = 2'b00, MODE_INT16 = 2'b01, MODE_POWER_SAVE = 2'b10, MODE_PERFORMANCE = 2'b11 } mac_mode_t;
endpackage : reconfigurable_mac_pkg

