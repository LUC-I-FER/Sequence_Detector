module seq_detector(
	input logic clk, rst, in,
  	output logic out
);
  
  // The sequnce we are going to detect is 1011 overlapping
  
  typedef enum logic [2:0] {IDLE, S1, S2, S3, S4} state_t; 
  
  state_t cur_state, next_state;
  
  assign out = (cur_state == S4);
  
  always @ (posedge clk) begin
    if (rst) 
      cur_state <= IDLE;
    else
      cur_state <= next_state;
  end
  
  always @ (*) begin
    case (cur_state) 
      
      IDLE: begin
        if (in) next_state = S1;
        else next_state = IDLE;
      end
      
      S1: begin
        if (in) next_state = S1;
        else next_state= S2;
      end
      
      S2: begin
        if (in) next_state = S3;
        else next_state = IDLE;
      end
      
      S3: begin
        if (in) next_state = S4;
        else next_state = S2;
      end
      
      S4: begin
        if (in) next_state = S1;
        else next_state = S2;
      end
      
    endcase
  end
  
endmodule
