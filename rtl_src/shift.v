/*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  @file: shift.v
 *
 *  @brief: shift register data unit
 *
 *  @author: Shatilov Sergej
 *
 *  @date: 13.02.2018
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

module SHIFT
(
  input  wire [4:0]  bits,      // value shift bits for data filter
  input  wire [31:0] data_in,   // data input
  output wire [31:0] data_out   // data output
);

  assign data_out = (bits == 5'h00) ? data_in[31:0] :                           // 0
                    (bits == 5'h01) ? {    data_in[31],   data_in[31:1] } :     // 1
                    (bits == 5'h02) ? {{ 2{data_in[31]}}, data_in[31:2] } :     // 2
                    (bits == 5'h03) ? {{ 3{data_in[31]}}, data_in[31:3] } :     // 3
                    (bits == 5'h04) ? {{ 4{data_in[31]}}, data_in[31:4] } :     // 4
                    (bits == 5'h05) ? {{ 5{data_in[31]}}, data_in[31:5] } :     // 5
                    (bits == 5'h06) ? {{ 6{data_in[31]}}, data_in[31:6] } :     // 6
                    (bits == 5'h07) ? {{ 7{data_in[31]}}, data_in[31:7] } :     // 7
                    (bits == 5'h08) ? {{ 8{data_in[31]}}, data_in[31:8] } :     // 8
                    (bits == 5'h09) ? {{ 9{data_in[31]}}, data_in[31:9] } :     // 9
                    (bits == 5'h0A) ? {{10{data_in[31]}}, data_in[31:10]} :     // 10
                    (bits == 5'h0B) ? {{11{data_in[31]}}, data_in[31:11]} :     // 11
                    (bits == 5'h0C) ? {{12{data_in[31]}}, data_in[31:12]} :     // 12
                    (bits == 5'h0D) ? {{13{data_in[31]}}, data_in[31:13]} :     // 13
                    (bits == 5'h0E) ? {{14{data_in[31]}}, data_in[31:14]} :     // 14
                    (bits == 5'h0F) ? {{15{data_in[31]}}, data_in[31:15]} :     // 15
                    (bits == 5'h10) ? {{16{data_in[31]}}, data_in[31:16]} :     // 16
                    (bits == 5'h11) ? {{17{data_in[31]}}, data_in[31:17]} :     // 17
                    (bits == 5'h12) ? {{18{data_in[31]}}, data_in[31:18]} :     // 18
                    (bits == 5'h13) ? {{19{data_in[31]}}, data_in[31:19]} :     // 19
                    (bits == 5'h14) ? {{20{data_in[31]}}, data_in[31:20]} :     // 20
                    (bits == 5'h15) ? {{21{data_in[31]}}, data_in[31:21]} :     // 21
                    (bits == 5'h16) ? {{22{data_in[31]}}, data_in[31:22]} :     // 22
                    (bits == 5'h17) ? {{23{data_in[31]}}, data_in[31:23]} :     // 23
                                      {{24{data_in[31]}}, data_in[31:24]};      // >= 24

endmodule
