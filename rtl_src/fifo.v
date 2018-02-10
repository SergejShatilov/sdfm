//===============================================
// Fifo unit
//===============================================

module FIFO
(
  input  wire        SYSRSTn,           // system reset
  input  wire        SYSCLK,            // system clock

  input  wire        reg_fifoen,        // fifo enable
  input  wire [3:0]  reg_fifoilvl,      // fifo interrupt level
  input  wire        fifo_rd,           // signal read FDATA register

  input  wire [31:0] fifo_data_in,      // from data filter
  input  wire        fifo_data_update,  // signal update from filter data

  output wire [3:0]  fifo_stat,         // status fifo
  output wire        fifo_lvlup,        // signal level up fifo status
  output wire        fifo_full,         // signal full fifo status

  output wire [31:0] fifo_data_out      // data from fifo
);

  integer i;

  reg [3:0]  wr_ptr;
  reg [3:0]  rd_ptr;
  reg [3:0]  cpt;

  reg [31:0] fifo_data [15:0];

  always @ (negedge SYSRSTn or posedge SYSCLK)  //FIXME:
    if(!SYSRSTn)
      begin
        wr_ptr <= 4'b0000;
        rd_ptr <= 4'b0000;
        cpt    <= 4'b0000;
        for(i = 0; i < 16; i = i + 1)
          fifo_data[i] = 32'h0000_0000;
      end
    else
      begin
        if(!reg_fifoen)
          begin
            wr_ptr <= 4'b0000;
            rd_ptr <= 4'b0000;
            cpt    <= 4'b0000;
            if(fifo_data_update)
              fifo_data[0] <= fifo_data_in;
          end
        else if(fifo_rd && (cpt != 4'b0000))
          begin
            rd_ptr <= rd_ptr + 4'b0001;
            if(!fifo_data_update)
              cpt <= cpt + 4'b1111;
            else
              begin
                if(cpt == 4'b1111)
                  cpt <= cpt + 4'b1111;
                else
                  begin
                    fifo_data[wr_ptr] <= fifo_data_in;
                    wr_ptr <= wr_ptr + 4'b0001;
                  end
              end
          end
        else if(fifo_data_update && (cpt != 4'b1111))
          begin
            fifo_data[wr_ptr] <= fifo_data_in;
            wr_ptr <= wr_ptr + 4'b0001;
            cpt    <= cpt + 4'b0001;
          end
      end

  assign fifo_data_out = fifo_data[rd_ptr];
  assign fifo_stat     = cpt;
  assign fifo_lvlup    = (cpt >= reg_fifoilvl);
  assign fifo_full     = (cpt == 4'b1111);

endmodule