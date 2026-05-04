library ieee;
use ieee.std_logic_1164.all;
 
library work;
use work.mem_pkg.all;
 
entity bcd_7seg is
    port (
        data_in : in  t_data;                        -- dato 8 bits (nibble bajo)
        seg     : out std_logic_vector(6 downto 0)   -- segmentos a-g (activo bajo)
    );
end entity bcd_7seg;
 
architecture rtl of bcd_7seg is
begin
 
    -- Decodificación combinacional BCD → 7seg activo en bajo
    process(data_in)
    begin
        case data_in(3 downto 0) is
            --               abcdefg  (activo en bajo: 0=encendido)
            when x"0" => seg <= "1000000";  -- 0
            when x"1" => seg <= "1111001";  -- 1
            when x"2" => seg <= "0100100";  -- 2
            when x"3" => seg <= "0110000";  -- 3
            when x"4" => seg <= "0011001";  -- 4
            when x"5" => seg <= "0010010";  -- 5
            when x"6" => seg <= "0000010";  -- 6
            when x"7" => seg <= "1111000";  -- 7
            when x"8" => seg <= "0000000";  -- 8
            when x"9" => seg <= "0010000";  -- 9
            when x"A" => seg <= "0001000";  -- A
            when x"B" => seg <= "0000011";  -- b
            when x"C" => seg <= "1000110";  -- C
            when x"D" => seg <= "0100001";  -- d
            when x"E" => seg <= "0000110";  -- E
            when x"F" => seg <= "0001110";  -- F
            when others => seg <= "1111111"; -- todo apagado
        end case;
    end process;
 
end architecture rtl;