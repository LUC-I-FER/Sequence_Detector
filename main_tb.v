module seq_detector_tb;
  
  reg clk;
  reg rst;
  reg in;
  
  wire out;
  
  seq_detector dut (.clk(clk), .rst(rst), .in(in), .out(out));
  
  always #5 clk = ~clk;
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, seq_detector_tb);
  end
  
  task send_bit(input bit bit_value);
    begin
      @(negedge clk);
      in = bit_value;
      
      @(posedge clk);
      #1;
      $display("Time=%0t | in = %b | out = %b", $time, in, out);
    end
  endtask
  
  initial begin
    
    clk = 0;
    rst = 1;
    in  = 0;
    
    @(posedge clk);
    @(posedge clk);
    
    rst = 0;
    send_bit(1);
    send_bit(0);
    send_bit(1);
    send_bit(1);
    send_bit(0);
    send_bit(1);
    send_bit(1);
    send_bit(0);
    send_bit(0);
    send_bit(1);
    send_bit(0);
    send_bit(1);
    send_bit(1);
    
    #10
    $finish;
  end
  
endmodule
