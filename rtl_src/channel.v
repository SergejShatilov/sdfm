//===============================================
// Channel sigma-delta
//=============================================== 

module CHANNEL
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock
  input  wire        DSDIN,             // direct stream data input
  input  wire        SDCLK,             // sigma-delta clock synchronization

  // DFPARMx
  input  wire [7:0]  reg_filtdec,       // data filter decimation ratio (oversampling ratio)
  input  wire [1:0]  reg_filtmode,      // input mode
  input  wire [3:0]  reg_filtdiv,       // ratio system clock dividing for mode 3
  input  wire        reg_filten,        // data filter enable
  input  wire        reg_filtask,       // data filter asknewledge enable
  input  wire [1:0]  reg_filtst,        // data filter structure
  input  wire [4:0]  reg_filtsh,        // value shift bits for data filter
  
  output wire [31:0] filt_data_out,     // filter data output
  output wire        filt_data_update   // signal filter data update
);


  // Filter data unit
  FILT filt
  (
    .SYSRSTn (SYSRSTn),
    .SYSCLK  (SYSCLK),
    .DSDIN   (DSDIN),
    .SDCLK   (SDCLK),
    .reg_filtdec      (reg_filtdec),
    .reg_filtmode     (reg_filtmode),
    .reg_filtdiv      (reg_filtdiv),
    .reg_filten       (reg_filten),
    .reg_filtst       (reg_filtst),
    .reg_filtsh       (reg_filtsh),
    .filt_data_out    (filt_data_out),
    .filt_data_update (filt_data_update)
  );

endmodule
