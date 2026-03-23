library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;
use     ieee.numeric_std.all;

entity UART_RX_Master is
  generic (
    CLOCK_FREQ		:positive;			
    MIN_BAUD_RATE		:positive;		
    NUMBER_OF_WORD_BITS		:positive range 5 to 8;			
    NUMBER_OF_PARITY_BITS       :natural range 0 to 1;      
    NUMBER_OF_STOP_BITS            :natural range 0 to 2;   
    PARITY_TYPE         :std_logic -- 0 is even, 1 is odd
  );
  
  port (
    CLK	        :in  std_logic;					
    RST		        :in  std_logic;				
    CYCLES_PER_BIT	:in  natural range 0 to CLOCK_FREQ/MIN_BAUD_RATE;
    RX		        :in  std_logic;					
    WORD	        :out std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    READY	        :out std_logic;					
    RX_ERROR	    :out std_logic					
  );
end UART_RX_Master;

architecture RTL of UART_RX_Master is

  signal   input_rx_buffer	:std_logic_vector(0 to 1);			

  type     STATES_TYPE		is (IDLE_WAIT, RECEIVING_START, RECEIVING_WORD, RECEIVING_PARITY, RECEIVING_STOP);	
  signal   state		:STATES_TYPE;						

  constant MAX_CYCLES_FOR_BIT	:positive := CLOCK_FREQ/MIN_BAUD_RATE;		
  signal   cycles_in_current_bit  	:natural range 0 to MAX_CYCLES_FOR_BIT-1;
  signal   number_of_bits_received  	:natural range 0 to NUMBER_OF_WORD_BITS-1;

  signal   final_word_buffer	:std_logic_vector(WORD'range);			
  signal   internal_error	:std_logic;					

begin
    -- badanie poprawnosci ustawien zegarow
    assert (CLOCK_FREQ >= 2 * MIN_BAUD_RATE)
    report "RX UART: clock frequency too low"
    severity error;

   process (RST, CLK) is							
   begin								

     if (RST='1') then							
       input_rx_buffer	<= (others => '0');					
       state	<= IDLE_WAIT;						
       cycles_in_current_bit  <= 0;							
       number_of_bits_received  <= 0;						
       final_word_buffer	<= (others => '0');				
       internal_error 	<= '0';							
       WORD	<= (others => '0');					
       READY	<= '0';							
       RX_ERROR	<= '0';							

     elsif (rising_edge(CLK)) then				
       READY     <= '0';						
       RX_ERROR       <= '0';					
       WORD	<= (others => '0');
       input_rx_buffer(0) <= RX;				
       input_rx_buffer(1) <= input_rx_buffer(0);

       case state is							

         when IDLE_WAIT =>						
           cycles_in_current_bit <= 0;						
           number_of_bits_received <= 0;					
           final_word_buffer   <= (others => '0');			
           internal_error <= '0';						
           if (input_rx_buffer(1)='1' and input_rx_buffer(0)='0' and CYCLES_PER_BIT/=0) then	
             state   <= RECEIVING_START;						
           end if;							

         when RECEIVING_START =>			
           if (cycles_in_current_bit /= CYCLES_PER_BIT/2) then				
             cycles_in_current_bit <= cycles_in_current_bit + 1;			
           else								
             cycles_in_current_bit <= 0;	
             state    <= RECEIVING_WORD;	
             if (input_rx_buffer(1) = '1') then					
	           report "RX UART: start bit incorrect"	
	           severity warning;
               internal_error <= '1';				
             end if;							
           end if;							

         when RECEIVING_WORD =>				
           if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then				
             cycles_in_current_bit <= cycles_in_current_bit + 1;			
           else								
             final_word_buffer(final_word_buffer'left) <= input_rx_buffer(1);				
             final_word_buffer(final_word_buffer'left-1 downto 0) <= final_word_buffer(final_word_buffer'left downto 1);
             cycles_in_current_bit <= 0;

             if (number_of_bits_received /= NUMBER_OF_WORD_BITS-1) then				
               number_of_bits_received <= number_of_bits_received + 1;				
             else							
               number_of_bits_received <= 0;						
               if (NUMBER_OF_PARITY_BITS = 1) then				
                 state <= RECEIVING_PARITY;					
               else							
                 state <= RECEIVING_STOP;	
               end if;						
             end if; 						
           end if;							

         when RECEIVING_PARITY =>			
           if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then					
             cycles_in_current_bit <= cycles_in_current_bit + 1;				
           else								
             cycles_in_current_bit <= 0;	
             state    <= RECEIVING_STOP;	
             if (PARITY_TYPE = '0') and ((input_rx_buffer(1) xor XOR_REDUCE(final_word_buffer)) = '0') then
               null;
             elsif (PARITY_TYPE = '1') and ((input_rx_buffer(1) xor not XOR_REDUCE(final_word_buffer)) = '0') then
                null;
             else
                internal_error <= '1';						
                report "RX UART: parity bit incorrect" 
                severity warning;
             end if; 							
           end if;							

         when RECEIVING_STOP =>							
           if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then					
             cycles_in_current_bit <= cycles_in_current_bit + 1;				
           else								
             cycles_in_current_bit <= 0;	

             if (number_of_bits_received /= NUMBER_OF_STOP_BITS-1) then		
               number_of_bits_received <= number_of_bits_received + 1;		
               if (input_rx_buffer(1) = '0') then				
                   internal_error <= '1';					
	               report "RX UART: stop bit incorrect" 
	               severity warning;   
               end if; 							
             else							
                if (internal_error = '0' and input_rx_buffer(1) = '1') then		
                 WORD <= final_word_buffer;					
                 READY <= '1';						
                else							
                 WORD <= (others => '0');		
                 RX_ERROR <= '1';				
                end if;							
                state <= IDLE_WAIT;					
             end if;							

           end if;							

       end case;							

     end if;								

   end process;								

end RTL;
