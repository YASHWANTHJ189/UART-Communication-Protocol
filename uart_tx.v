module UART_TX #(parameter CLKS_PER_BIT)(
  input i_tx_dv,			// indicates when input is valid and should be transmitted
  input i_clk,				// input clock / system clock
  input [7:0] i_tx_serial,	// data to be transmitted
  output reg o_tx_data,		// serial output line
  output o_tx_active,		// indicates when transmission is ongoing
  output o_tx_done			// pulses when data is transmitted
);
  
  parameter S_IDLE          = 3'b000;
  parameter S_START_BIT  = 3'b001;
  parameter S_DATA_BITS  = 3'b010;
  parameter S_STOP_BIT   = 3'b011;
  parameter S_CLEANUP       = 3'b100;
  
  reg [2:0] r_state;			// this reg is used to indicate states
  reg [7:0] r_clock_count;		// keeps the count of clock cycles for bit transmission. refer notes
  reg [2:0] r_bit_index;		// keeps count of which bit is being transmitted
  reg [7:0] r_tx_data;			// this reg is used to store the incoming data 
  reg       r_tx_done;			// this is used to indicate when the transmission is done
  reg       r_tx_active;		// this is used to indicate when UART is busy
  
  always@(posedge i_clk)
    begin
      
      case(r_state)
        S_IDLE :
          begin
            o_tx_data     <= 1'b1;	//initial values
            r_tx_done     <= 1'b0;
            r_clock_count <= 1'b0;
            r_bit_index   <= 1'b0;
            
            if(i_tx_dv == 1'b1)
              begin
                r_tx_active <= 1'b1;
                r_tx_data   <= i_tx_serial;
                r_state     <= S_START_BIT;
              end
            else
              r_state <= S_IDLE;
          end
        
        S_START_BIT :	// start of transmission
          begin
            o_tx_data <= 1'b0;
            
            if(r_clock_count < CLKS_PER_BIT - 1)		//main purpose of this is to count to one UART cycle so that the start bit can be set to 0.
              begin
                r_clock_count <= r_clock_count + 1;
                r_state <= S_START_BIT;
              end
            else
              begin
                r_clock_count <= 1'b0;
                r_state <= S_DATA_BITS;
              end
          end
        
        S_DATA_BITS :
          begin
            o_tx_data <= r_tx_data[r_bit_index];
            
            if(r_clock_count < CLKS_PER_BIT - 1)
              begin
                r_clock_count <= r_clock_count + 1;
                r_state       <= S_DATA_BITS;
              end
            else
              begin
                r_clock_count <= 0;
                
                if(r_bit_index < 7)
                  begin
                    r_bit_index <= r_bit_index + 1;
                    r_state     <= S_DATA_BITS;
                  end
                else
                  begin
                    r_bit_index <= 0;
                    r_state     <= S_STOP_BIT;
                  end
              end
          end
        
        
        S_STOP_BIT :
          begin
            o_tx_data <= 1'b1;
            
            if(r_clock_count < CLKS_PER_BIT - 1)
              begin
                r_clock_count <= r_clock_count + 1;
                r_state       <= S_STOP_BIT;
              end
            else
              begin
                r_tx_done     <= 1'b1;
                r_clock_count <= 0;
                r_state       <= S_CLEANUP;
                r_tx_active   <= 1'b0;
              end
          end
        
        S_CLEANUP :
          begin
            r_tx_done <= 1'b1;
            r_state   <= S_IDLE;
          end
        
        default :
          r_state <= S_IDLE;
      endcase
    end
  
  assign o_tx_done   = r_tx_done;
  assign o_tx_active = r_tx_active;
  
endmodule
