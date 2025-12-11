module UART_RX #(parameter CLKS_PER_BIT)(
  input i_rx_data,
  input i_clock,
  output o_rx_dv,
  output [7:0] o_rx_byte);
  
  parameter S_IDLE      = 3'b000;
  parameter S_START_BIT = 3'b001;
  parameter S_DATA_BITS = 3'b010;
  parameter S_STOP_BIT  = 3'b011;
  parameter S_CLEANUP   = 3'b100;
  
  reg r_data;
  reg r_data_r;
  
  reg [7:0] clk_count;
  reg [2:0] bit_index;
  reg [2:0] state;
  reg [7:0] r_byte;
  reg       r_rx_dv;
  
  always@(posedge i_clock)	//using dual flip-fops to avoid metastability
    begin
      r_data_r <= i_rx_data;
      r_data   <= r_data_r;
    end
  
  always@(posedge i_clock)
    begin
      case(state)
        
        S_IDLE :
          begin
            clk_count <= 0;
            r_rx_dv   <= 1'b0;
            bit_index <= 0;
            
            if(r_data == 1'b0)
              state <= S_START_BIT;
            else
              state <= S_IDLE;
          end
        
        S_START_BIT :
          begin
            if(clk_count == (CLKS_PER_BIT - 1)/2)
              begin
                if(r_data == 1'b0)
                  begin
                    clk_count <= 0;		//resetting the counter
                    state     <= S_DATA_BITS;
                  end
                else
                  begin
                    state <= S_IDLE;
                  end
              end
            else
              begin
                clk_count <= clk_count + 1;
                state     <= S_START_BIT;
              end
          end
        
        S_DATA_BITS :
          begin
            if(clk_count < CLKS_PER_BIT - 1)	//wait 1 UART cycle
              begin
                clk_count <= clk_count + 1;
                state     <= S_DATA_BITS;
              end
            else
              begin
                clk_count <= 0;					//reset count
                r_byte[bit_index] <= r_data;	//load data
                
                if(bit_index < 7)				//check if all bits are loaded
                  begin
                    bit_index <= bit_index + 1;
                    state     <= S_DATA_BITS;
                  end
                else
                  begin
                    bit_index <= 0;
                    state     <= S_STOP_BIT;
                  end
              end
          end
        
        S_STOP_BIT :		//no need to check for the stop bit. just wait one clk cycle and move to next state.
          begin
            if(clk_count < CLKS_PER_BIT - 1)
              begin
                clk_count <= clk_count + 1;
                state     <= S_STOP_BIT;
              end
            else
              begin
                clk_count <= 0;
                state <= S_CLEANUP;
                r_rx_dv <= 1'b1;
              end
          end
        
        S_CLEANUP :
          begin
            r_rx_dv <= 1'b0;
            state   <= S_IDLE;
          end
        
        default :
          state <= S_IDLE;
        
      endcase
    end
  assign o_rx_dv = r_rx_dv;
  assign o_rx_byte = r_byte;
  
endmodule 

module UART_TX #(parameter CLKS_PER_BIT)(
  input i_tx_dv,
  input i_clock,
  input [7:0] i_tx_data,
  output reg o_tx_data,
  output o_tx_active,
  output o_tx_done);
  
  parameter S_IDLE       = 3'b000;
  parameter S_START_BIT  = 3'b001;
  parameter S_DATA_BITS  = 3'b010;
  parameter S_STOP_BIT   = 3'b011;
  parameter S_CLEANUP    = 3'b100;
  
  reg [7:0] clk_count;
  reg [2:0] bit_index;
  reg [7:0] r_data;
  reg [2:0] state;
  reg       r_tx_done;
  reg       r_tx_active;
  
  always@(posedge i_clock)
    begin
      case(state)
        S_IDLE :
          begin
            r_tx_done <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
            o_tx_data <= 1'b1;
            
            if(i_tx_dv == 1'b1)
              begin
                r_data      <= i_tx_data;
                r_tx_active <= 1'b1;
                state       <= S_START_BIT;
              end
            else
              state <= S_IDLE;
          end
        
        S_START_BIT :
          begin
            o_tx_data <= 1'b0;
            
            if(clk_count < CLKS_PER_BIT - 1)
              begin
                clk_count <= clk_count + 1;
                state <= S_START_BIT;
              end
            else
              begin
                clk_count <= 0;
                state <= S_DATA_BITS;
              end
          end
        
        S_DATA_BITS :
          begin
            o_tx_data <= r_data[bit_index]; 
            
            if(clk_count < CLKS_PER_BIT - 1)
              begin
                clk_count <= clk_count + 1;
                state <= S_DATA_BITS;
              end
            else
              begin
                clk_count <= 0;
                
                if(bit_index < 7)
                  begin
                    bit_index <= bit_index + 1;
                    state <= S_DATA_BITS;
                  end
                else
                  begin
                    bit_index <= 0;
                    state     <= S_STOP_BIT;
                  end
              end
          end
        
        S_STOP_BIT :
          begin
            o_tx_data <= 1'b1;
            
            if(clk_count < CLKS_PER_BIT - 1)
              begin
                clk_count <= clk_count + 1;
                state     <= S_STOP_BIT;
              end
            else
              begin
                clk_count   <= 0;
                r_tx_done   <= 1'b1;
                r_tx_active <= 1'b0;
                state       <= S_CLEANUP;
              end
          end
        
        S_CLEANUP :
          begin
            r_tx_done <= 1'b1;
            state     <= S_IDLE;
          end
        
        default :
          state <= S_IDLE;
        
      endcase
    end
  assign o_tx_done   = r_tx_done;
  assign o_tx_active = r_tx_active;
  
endmodule
                  
