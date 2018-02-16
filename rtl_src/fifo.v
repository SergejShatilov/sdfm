/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: fifo.v
 *
 *  @brief: "first in, first out" buffer unit
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 14.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module FIFO
(
  input  wire        SYSRSTn,       // system reset
  input  wire        SYSCLK,        // system clock

  input  wire        enable,        // fifo enable
  input  wire [3:0]  level,         // interrupt level
  input  wire        rd,            // signal read FDATA register

  input  wire [31:0] data_in,       // data input
  input  wire        data_update,   // signal update  data

  output wire [3:0]  stat,          // status level
  output wire        levelup,       // signal level up
  output wire        full,          // signal full

  output wire [31:0] data_out       // data output
);

  integer i;

  reg [3:0]  wr_ptr;
  reg [3:0]  rd_ptr;
  reg [3:0]  cpt;

  reg [31:0] data [15:0];

  always @ (negedge SYSRSTn or posedge SYSCLK)  //FIXME:
    if(!SYSRSTn)
      begin
        wr_ptr <= 4'b0000;
        rd_ptr <= 4'b0000;
        cpt    <= 4'b0000;
        for(i = 0; i < 16; i = i + 1)
          data[i] = 32'h0000_0000;
      end
    else
      begin
        if(!enable)
          begin
            wr_ptr <= 4'b0000;
            rd_ptr <= 4'b0000;
            cpt    <= 4'b0000;
            if(data_update)
              data[0] <= data_in;
          end
        else if(rd && (cpt != 4'b0000))
          begin
            rd_ptr <= rd_ptr + 4'b0001;
            if(!data_update)
              cpt <= cpt + 4'b1111;
            else
              begin
                if(cpt == 4'b1111)
                  cpt <= cpt + 4'b1111;
                else
                  begin
                    data[wr_ptr] <= data_in;
                    wr_ptr <= wr_ptr + 4'b0001;
                  end
              end
          end
        else if(data_update && (cpt != 4'b1111))
          begin
            data[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 4'b0001;
            cpt    <= cpt + 4'b0001;
          end
      end

  assign data_out = data[rd_ptr];
  assign stat     = cpt;
  assign levelup  = (cpt >= level);
  assign full     = (cpt == 4'b1111);

endmodule
