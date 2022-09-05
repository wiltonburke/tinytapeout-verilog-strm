`default_nettype none

//  Top level io for this module should stay the same to fit into the scan_wrapper.
//  The pin connections within the user_module are up to you,
//  although (if one is present) it is recommended to place a clock on io_in[0].
//  This allows use of the internal clock divider if you wish.
module user_module_341922299323089492(
  input [7:0] io_in, 
  output [7:0] io_out
);

localparam
STCONFIG = 1'b0,
STRUN    = 1'b1;

localparam
ACTIVEMODECONFIG = 2'b00,
ACTIVEMODESERIAL = 2'b01,
ACTIVEMODEPARALLEL = 2'b10,
ACTIVEMODECYCLE = 2'b11;

// Compile time options
localparam
isTWOWRITES = 1'b0, // When in parallel (True )2 writes 4b data or 6b sign extend
isEIGHTCYCLEREAD = 1'b0; // When in sipo is it 1 cycle or 8 cycles for a read

parameter DEPTH = 16; // size of the memory
parameter WIDTH = $clog2(DEPTH);

logic d0;
logic d1;
logic d2;
logic d3;
logic d4;
logic d5;
logic d6;
logic d7;
logic dout0;

logic myclock;
logic superclock;
logic resetn;
logic [1:0] mode;
reg [1:0] regmode;
reg [7:0] serialdata;
logic state;

logic [WIDTH-1:0] readpointer;
logic [WIDTH-1:0] writepointer;
reg [7:0] mem [DEPTH:0];

logic [7:0] memwdata;
logic [7:0] memrdata;

logic isEmpty;
logic pop;
logic push;
logic hold;
logic write;
logic readempty;
reg reademptytoggle;
logic writefull;

logic myconfig;
reg [2:0] configdetect;


assign myconfig = io_in[7];
assign mode[0] = io_in[2];
assign mode[1] = io_in[3];
assign hold = io_in[6];
assign write = io_in[7];

assign resetn = (regmode[1] | regmode[0]) & (state != STCONFIG);

assign myclock = (regmode != ACTIVEMODEPARALLEL)? io_in[0] : io_in[6];

assign superclock = io_in[0] ^ io_in[1] ^ io_in[2] ^ io_in[3] ^ io_in[4] ^ io_in[5] ^ io_in[6];

//debug just shift data in and out
//assign dout[0] = serialdata[7];
//assign d0 = io_in[0];
//assign d1 = io_in[1];
//assign d2 = io_in[2];
//assign d3 = io_in[3];
//assign d4 = io_in[4];
//assign d5 = io_in[5];
//assign d6 = io_in[6];
//assign d7 = io_in[7];
//assign dout0 = dout[0];


assign io_out[7:0] = (regmode == ACTIVEMODECONFIG)? 8'hdb:
(readempty)? ((reademptytoggle)?8'haa : 8'h55):
(writefull)? 8'hff:
(regmode == ACTIVEMODESERIAL)? {6'b0,isEmpty,serialdata[7]}:
mem[readpointer][7:0];

assign isEmpty = readpointer == writepointer;

assign readempty = pop & isEmpty;
assign writefull = push & ((writepointer + 1) == readpointer);

assign memwdata = (regmode == ACTIVEMODESERIAL)? serialdata: {io_in[5],io_in[5],io_in[5:0]};

always @(posedge myclock, negedge resetn)
begin
if (resetn == 1'b0)
  begin
    readpointer <= 0;
    writepointer <= 0;
    reademptytoggle <= 0;
  end
else
  begin
    // handle read and write
    if (regmode == ACTIVEMODESERIAL)
      begin
        if (pop)
          serialdata <= memrdata;
        else
          serialdata <= {serialdata[6:0], io_in[1]};
      end
    if (regmode == ACTIVEMODESERIAL)
      begin
        if (!hold & !write)
          begin
            pop <= 1'b1;
            push <= 1'b0;
          end
        else if (!hold & write)
          begin
            pop <= 1'b0;
            push <= 1'b1;
          end
        else
          begin
            pop <=1'b0;
            push <= 1'b0;
          end
      end
    if (regmode == ACTIVEMODEPARALLEL)
      begin
        if (!write & !pop & !push)
          begin
            pop <= 1'b1;
            push <= 1'b0;
          end
        else if (write & !pop & !push)
          begin
            pop <= 1'b0;
            push <= 1'b1;
          end
        else 
          begin
            pop <= 1'b0;
            push <= 1'b0;
          end
      end
  end

if (push)
  begin  
  mem[writepointer] <= memwdata;
    if ((writepointer + 1) != readpointer)
      writepointer <= writepointer+1;
  end

if (pop | regmode == ACTIVEMODECYCLE)
  begin
  memrdata <= mem[readpointer];
    if (regmode == ACTIVEMODECYCLE)
      readpointer <= readpointer + 1;
    else if ((readpointer + 1) != (writepointer + 1))
      readpointer <= readpointer + 1;
  end
// handle error conditions
if (readempty)
  reademptytoggle <= !reademptytoggle;
end
  
always @(posedge superclock)
begin
configdetect <= {configdetect[1], configdetect[0], myconfig};
if (configdetect == 3'b111 & myconfig)
begin
  state <= STCONFIG;
  regmode <= mode[1:0];
end
else
  state <= STRUN;
end

endmodule