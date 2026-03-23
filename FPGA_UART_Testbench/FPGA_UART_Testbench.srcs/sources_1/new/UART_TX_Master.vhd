library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;

entity UART_TX_Master is
  generic (
    CLOCK_FREQ		:positive;
    MIN_BAUD_RATE		:positive;
    NUMBER_OF_WORD_BITS		:positive range 5 to 8;
    NUMBER_OF_PARITY_BITS       :natural range 0 to 1;
    NUMBER_OF_STOP_BITS            :natural range 0 to 2;
    PARITY_TYPE         :std_logic -- 0 is even, 1 is odd
  );
  
  port (
    CLK	            :in  std_logic;
    RST		        :in  std_logic;
    CYCLES_PER_BIT	:in  natural range 0 to CLOCK_FREQ/MIN_BAUD_RATE;
    WORD	        :in std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    WORD_READY      :in std_logic;
    
    TX		        :out  std_logic;
    BUSY            :out std_logic;
    TX_ERROR	    :out std_logic
  );
end UART_TX_Master;

architecture RTL of UART_TX_Master is

  signal   output_word_buffer: std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
  signal    parity_bit :std_logic;

  type     STATES_TYPE		is (IDLE_WAIT, TRANSMITTING_START, TRANSMITTING_WORD, TRANSMITTING_PARITY, TRANSMITTING_STOP);
  signal   state		:STATES_TYPE;

  constant MAX_CYCLES_FOR_BIT	:positive := CLOCK_FREQ/MIN_BAUD_RATE;
  signal   cycles_in_current_bit  	:natural range 0 to MAX_CYCLES_FOR_BIT-1;
  signal   number_of_bits_transmitted  	:natural range 0 to NUMBER_OF_WORD_BITS-1;

  signal   internal_error	:std_logic;

begin
    assert (CLOCK_FREQ >= 2 * MIN_BAUD_RATE)
    report "TX UART: clock frequency too low"
    severity error;

   process (RST, CLK) is
   begin								

     if (RST='1') then					
       output_word_buffer	<= (others => '0');
       state	<= IDLE_WAIT;					
       cycles_in_current_bit  <= 0;				
       number_of_bits_transmitted  <= 0;		
       
       internal_error 	<= '0';							 
       
       TX <= '1';
       BUSY	<= '0';	
       TX_ERROR	<= '0';							

     elsif (rising_edge(CLK)) then		

       BUSY     <= '0';					
       TX_ERROR       <= '0';			
       TX <= '1';
        
       case state is					

         when IDLE_WAIT =>				
            BUSY <= '0';
            if (WORD_READY = '1') then
                output_word_buffer <= WORD;
                BUSY <= '1';
                state <= TRANSMITTING_START;
                if (PARITY_TYPE = '0') then
                    parity_bit <= XOR_REDUCE(WORD);
                else
                    parity_bit <= not XOR_REDUCE(WORD);
                end if;
            end if;
            
         when TRANSMITTING_START =>							
            BUSY <= '1';
            TX <= '0';
            if (cycles_in_current_bit /= CYCLES_PER_BIT -1) then				
                cycles_in_current_bit <= cycles_in_current_bit + 1;
            else								
                cycles_in_current_bit <= 0;
                state    <= TRANSMITTING_WORD;	
           end if;							

         when TRANSMITTING_WORD =>							
            BUSY <= '1';
            TX <= output_word_buffer(output_word_buffer'right);
            if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then
                cycles_in_current_bit <= cycles_in_current_bit + 1;
                
            else
                cycles_in_current_bit <= 0;
        
                output_word_buffer <= '0' & output_word_buffer(output_word_buffer'left downto 1); -- shift
                
                if (number_of_bits_transmitted /= NUMBER_OF_WORD_BITS-1) then
                    number_of_bits_transmitted <= number_of_bits_transmitted + 1;
                else
                    number_of_bits_transmitted <= 0;
                    if (NUMBER_OF_PARITY_BITS = 1) then
                        state <= TRANSMITTING_PARITY;
                    else
                        state <= TRANSMITTING_STOP;
                    end if;
                end if;
                
            end if;

         when TRANSMITTING_PARITY =>						
            BUSY <= '1';
            TX <= parity_bit;
            if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then
                cycles_in_current_bit <= cycles_in_current_bit + 1;
            else
                cycles_in_current_bit <= 0;
                state <= TRANSMITTING_STOP;
            end if;

         when TRANSMITTING_STOP =>
            BUSY <= '1';
            TX <= '1';
            if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then
                cycles_in_current_bit <= cycles_in_current_bit + 1;
        
            else
                cycles_in_current_bit <= 0;
                if (number_of_bits_transmitted /= NUMBER_OF_STOP_BITS-1) then
                    number_of_bits_transmitted <= number_of_bits_transmitted + 1;
                else
                    number_of_bits_transmitted <= 0;
                    state <= IDLE_WAIT;
                end if;
            end if;

       end case;

     end if;

   end process;

end RTL;
