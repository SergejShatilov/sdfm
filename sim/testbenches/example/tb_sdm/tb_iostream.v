//===========================================
//          General
task init;
  begin
    WR <= 1'b0;
    RD <= 1'b0;
    ADDR <= {16{1'bz}};
  end
endtask
  
task write(input [15:0] addr, input [31:0] data);
  begin
    WDATA <= data;      #(1e9 / `FREQEXTCLK);
    ADDR <= addr;
    WR   <= 1'b1;       #(1e9 / `FREQEXTCLK);
    WR   <= 1'b0;
    ADDR <= {16{1'bz}}; #(1e9 / `FREQEXTCLK);
  end
endtask
  
task read(input [16:0] addr);
  begin
    ADDR <= addr;
    RD <= 1'b1;         #(1e9 / `FREQEXTCLK);
    RD <= 1'b0;
    ADDR <= {16{1'bz}}; #(1e9 / `FREQEXTCLK);
  end
endtask



//===========================================
// register CTL
task writeCTL(input RSTEN, input CLKEN, input MIEN);
  begin
    write(16'h0708, {24'h0000_00, 3'b000, MIEN, 2'b00, CLKEN, RSTEN});
  end
endtask



//===========================================
// register INPARM0
task writeINPARM0(input [1:0] MOD, input [3:0] DIV);
  begin
    write(16'h070C, {24'h0000_00, DIV, 2'b00, MOD});
  end
endtask



//===========================================
// register INPARM1
task writeINPARM1(input [1:0] MOD, input [3:0] DIV);
  begin
    write(16'h0710, {24'h0000_00, DIV, 2'b00, MOD});
  end
endtask



//===========================================
// register DFPARM0
task writeDFPARM0(input [7:0] DOSR, input FEN, input AEN, input [1:0] ST, input [4:0] SH);
  begin
    write(16'h0714, {11'h000, SH, 2'b00, ST, 2'b00, AEN, FEN, DOSR});
  end
endtask



//===========================================
// register DFPARM1
task writeDFPARM1(input [7:0] DOSR, input FEN, input AEN, input [1:0] ST, input [4:0] SH);
  begin
    write(16'h0718, {11'h000, SH, 2'b00, ST, 2'b00, AEN, FEN, DOSR});
  end
endtask

