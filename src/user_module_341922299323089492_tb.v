`timescale 1ns / 1ps
//`include "user_module_341922299323089492.v"

module user_module_341922299323089492_tb;

wire [7:0] io_in;
wire [7:0] io_out;

reg clk;
reg [1:0] mode;
reg [7:0] mydata;
reg [7:0] mydataout;
reg myconfig;
reg hold;
reg configwrite;
reg write;
reg myshift;
reg myshiftdin;

assign io_in = {pdm_input, write_en, reset, clk};

user_module_341922299323089492 UUT (.io_in(io_in), .io_out(io_out));

initial begin
  $dumpfile("user_module_341922299323089492_tb.vcd");
  $dumpvars(0, user_module_341922299323089492_tb);
end

initial begin
   #100_000_000; // Wait a long time in simulation units (adjust as needed).
   $display("Caught by trap");
   $finish;
 end

parameter CLK_HALF_PERIOD = 5;
parameter TCLK = 2*CLK_HALF_PERIOD;
always begin
    clk = 1'b1;
    #(CLK_HALF_PERIOD);
    clk = 1'b0;
    #(CLK_HALF_PERIOD);
end


  // Task reset strm
task strmReset;
begin
  // Code which implements the task
end
endtask : strmReset

// Task serial write strm
task strmSerialWrite;
  input [7:0] data;
begin
  // Code which implements the task
  myshift = 1;
  mydata = data;
  myshiftdin = 1;
  #20
  myshiftdin = 1;
  #20
  myshiftdin = 0;
  #20
  myshiftdin = 0;
  #20
  myshiftdin = 1;
  #20
  myshiftdin = 1;
  #20
  myshiftdin = 0;
  #20
  myshiftdin = 0;
  write = 1;
  hold = 0;
  #20
  myshift = 0;
  write = 0;
  hold = 1;
  #20
  hold = 1;
end
endtask : strmSerialWrite

// Task serial read strm
task strmSerialRead;
  output [7:0] data;
begin
  // Code which implements the task
  write = 0;
  hold = 0;
  #20
  hold = 1;
  
  myshift = 1;
  myshiftdin = 1;
  data <= {data[6:0],io_out[0]};
  #20
  myshiftdin = 0;
  data <= {data[6:0],io_out[0]};
  #20
  myshiftdin = 0;
  data <= {data[6:0],io_out[0]};
  #20
  myshiftdin = 0;
  data <= {data[6:0],io_out[0]};
  #20
  myshiftdin = 0;
  data <= {data[6:0],io_out[0]};
  #20
  myshiftdin = 0;
  data <= {data[6:0],io_out[0]};
  #20
  myshiftdin = 1;
  data <= {data[6:0],io_out[0]};
  #20
  myshiftdin = 0;
  data <= {data[6:0],io_out[0]};
  #20
  data <= {data[6:0],io_out[0]};
  myshift = 0;
  #20
  data <= {data[6:0],io_out[0]};
end
endtask : strmSerialRead

// Task parallel write strm
task strmParallelWrite;
  input [7:0] data;
begin
  // Code which implements the task
  mydata = data;
  #20
  write = 1;
  hold = 0;
  #20
  hold = 1;
  #20
  write = 0;
  hold = 0;
  #20
  hold = 1;
  #20
  hold = 0;
end
endtask : strmParallelWrite

// Task parallel read strm
task strmParallelRead;
  output [7:0] data;
begin
  // Code which implements the task
  write = 0;
  hold = 0;
  #20
  hold = 1;
  #20
  hold = 0;
  #20
  hold = 1;
  #20
  data <= io_out[7:0];
  #20
  hold = 0;
end
endtask : strmParallelRead

assign io_in[0] =(mode != 2'b10)? clock : mydata[0];
assign io_in[1] = (mode != 2'b10)? mydata[7]: mydata[1];
assign io_in[2] = (myconfig)? mode[0]: mydata[2];
assign io_in[3] = (myconfig)? mode[1]: mydata[3];
assign io_in[4] = mydata[4];
assign io_in[5] = mydata[5];
assign io_in[6] = hold;
assign io_in[7] = configwrite;

assign configwrite = write | myconfig;

initial begin 
  clock = 1'b0;
  forever begin 
    clock = #10 !clock;
  end
end

 
initial begin
  mode = 2'b00;  // reset
  mydata = 0;
  myshift = 0;
  myshiftdin = 0;
  hold = 1;
  //reset the memory 
  myconfig = 1;
  #80;
  myconfig = 0;
  
  write = 0;
  mydata = 0;
  hold = 1;
  #120;
  //set mode to serial
  mode = 2'b01;  // serial
  myconfig = 1;
  #80;
  myconfig = 0;
  #120;
  // start write
  strmSerialWrite(8'hAA);
  // end write
  
  // start read
  strmSerialRead(mydataout);
  //end read
  
  // task write
  strmSerialWrite(8'hDE);
  strmSerialWrite(8'hAD);
  strmSerialWrite(8'hBE);
  strmSerialWrite(8'hEF);
  // task read
  #800
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  
  // test empty read
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  
  // task write
  strmSerialWrite(8'h87);
  strmSerialWrite(8'h65);
  strmSerialWrite(8'h43);
  strmSerialWrite(8'h21);
  // task read
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  strmSerialRead(mydataout);
  
  #120
  //set mode to parallel
  mode = 2'b10;  // parallel
  myconfig = 1;
  // just waiting wont work as the clock is muxed out
  // write parallel data to provide a clock
  mydata = 0;
  #10
  mydata = 1;
  #10 
  mydata = 0;
  #10
  mydata = 1;
  #10 
  mydata = 0;
  #10
  mydata = 1;
  #10
  myconfig = 0;
  #10
  mydata = 1;
  #10
  myconfig = 0;
  #120;
  
  // start write
  strmParallelWrite(8'h05);
  // end write
  
  // start read
  strmParallelRead(mydataout);
  //end read
  
  // task write
  strmParallelWrite(8'h0A);
  strmParallelWrite(8'h0B);
  strmParallelWrite(8'h04);
  strmParallelWrite(8'h08);
  // task read
  #800
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  
  // test empty read
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  
  // task write
  strmParallelWrite(8'h87);
  strmParallelWrite(8'h65);
  strmParallelWrite(8'h43);
  strmParallelWrite(8'h21);
  // task read
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  strmParallelRead(mydataout);
  
  //set mode to cycle
  mode = 2'b11;  // cycle
  myconfig = 1;
  #80;
  myconfig = 0;
  #120;
end
 
always @(posedge clock)
begin
  mydata <= (myshift)?{mydata[6:0],myshiftdin}: mydata;
end


endmodule
