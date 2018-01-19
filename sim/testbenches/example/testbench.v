`define ICARUS

`ifdef ICARUS
  `timescale 1ns / 1ns
`else
  `timescale 1ns / 100ps
`endif

`define PI 3.14159265359

`ifdef ICARUS
  `define MODELING_STEP 50
`else
  `define MODELING_STEP 1
`endif
  
  
`define FREQEXTCLK 100e6

`define FSR_0  44.1e3 // Frequence sampling
`define FSR_1  44.1e3

`define FOSR_0 256    // Filter oversampling ratio
`define FOSR_1 256

module testbench;

  initial begin
    `ifdef ICARUS
      $dumpfile("out.vcd");
      $dumpvars(0, testbench);
      #500_000 $finish;
    `else
      #2000_000 $finish;
    `endif
  end

  
  //==========================================================
  // Modeling clock and reset
  reg MODELING_RSTn;
  reg MODELING_CLK;
  
  initial begin
    MODELING_RSTn <= 1'b0;
    `ifdef ICARUS
      #10;
    `else
      #200_000;               //FIXME
    `endif
    MODELING_RSTn <= 1'b1;
  end
  
  initial begin
    MODELING_CLK <= 1'b0; #20;
    MODELING_CLK <= 1'b1;
  end
  
  always @ (*)
    #(`MODELING_STEP) MODELING_CLK <= !MODELING_CLK;
  
  
  //==========================================================
  // Modulators clocks
  reg SDCLK_0;
  reg SDCLK_1;
  
  initial begin
    SDCLK_0 <= 1'b0; #40;
    SDCLK_0 <= 1'b1;
  end
  
  initial begin
    SDCLK_1 <= 1'b0; #40;
    SDCLK_1 <= 1'b1;
  end
  
  always @ (*)
    #(0.5e9 / (`FOSR_0 * `FSR_0)) SDCLK_0 <= !SDCLK_0;

  always @ (*)
    #(0.5e9 / (`FOSR_1 * `FSR_1)) SDCLK_1 <= !SDCLK_1;
  
  
  //==========================================================
  // External clock and reset for sdfm
  reg EXTRSTn;
  reg EXTCLK;
  
  initial begin
    EXTRSTn <= 1'b0;
    `ifdef ICARUS
      #20;
    `else
      #300_000;               //FIXME
    `endif
    EXTRSTn <= 1'b1;
  end
  
  initial begin
    EXTCLK <= 1'b0; #50;
    EXTCLK <= 1'b1;
  end
  
  always @ (*)
    #(0.5e9 / `FREQEXTCLK) EXTCLK <= !EXTCLK;
  
  
  //=================================
  // Modulators
  `include "../testbenches/example/tb_sdm/tb_sdm_0.v"
  `include "../testbenches/example/tb_sdm/tb_sdm_1.v"
  `include "../testbenches/example/tb_sdm/tb_math.v"
    

  //=================================
  // Demodulator
  wire [1:0]  DSDIN;
  wire [1:0]  SDCLK;
  wire [31:0] RDATA;
  wire        IRQ;
  reg         RnW;
  reg  [15:0] ADDR;
  reg  [31:0] WDATA;
  wire [31:0] DATA;
  reg         WR;
  reg         RD;

  //assign DSDIN = {SDM_out_1, SDM_out_0};
  //assign SDCLK = {SDCLK_1, SDCLK_0};
  
  // for mode 2 (manchester mode)
  assign DSDIN = {(SDM_out_1 ^ SDCLK_1), (SDM_out_0 ^ SDCLK_0)};
  assign SDCLK = 2'b00;

  
  assign DATA = WR ? WDATA : {32{1'bz}};
  assign RDATA = RD ? DATA : {32{1'b0}};

  SDFM sdfm
  (
    .EXTRSTn(EXTRSTn),
    .EXTCLK(EXTCLK),
    .DSDIN(DSDIN),
    .SDCLK(SDCLK),
    .RD(RD),
    .WR(WR),
    .ADDR(ADDR),
    .DATA(DATA),
    .IRQ(IRQ)
  );

  task init;
    begin
      WR <= 1'b0;
      RD <= 1'b0;
      ADDR <= {16{1'bz}};
    end
  endtask
  
  task write(input [15:0] addr, input [31:0] data);
    begin
      //#50_000;
      WDATA <= data;
      #10;
      ADDR <= addr;
      WR   <= 1'b1; #10;
      WR   <= 1'b0;
      ADDR <= {16{1'bz}};
    end
  endtask
  
  task read(input [16:0] addr);
    begin
      //#50_000;
      ADDR <= addr;
      RD <= 1'b1; #10;
      RD <= 1'b0;
      ADDR <= {16{1'bz}};
    end
  endtask
  
  
  //================================
  // Init
  initial begin
    init();
    //#160_005;
    #50_000;
    write(16'h0708, 32'h0000_0003);
    #10_000;
    read(16'h0708);
    #10_000;
    write(16'h070C, 32'h0511_02FF);
    write(16'h0710, 32'h0323_D0FF);
    #10_000;
    read(16'h070C);
    read(16'h0710);
    
    #50_000;
    write(16'h0724, 32'hABCD_6894);
    write(16'h0728, 32'h1234_53DC);
    #10_000;
    read(16'h0724);
    #500;
    read(16'h0728);
    
    
    //write(8'h04, 32'h0304_503F);
  end

endmodule
 
