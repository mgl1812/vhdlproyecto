library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 entity seg_bcd is 
    port(
        digito   : in  std_logic_vector(3 downto 0); ---valor bcd de entrada (0 a 9)
        segmentos: out std_logic_vector(6 downto 0)  ---salida 7 seg
		  );
end entity seg_bcd;
 
architecture combinacional of seg_bcd is
begin
    ---tabla de verdad bcd a 7 segmentos (activo en bajo)
    
    p_decodificar: process(digito)
    begin
        case digito is
            when "0000" => segmentos <= "1000000"; ---0
            when "0001" => segmentos <= "1111001"; ---1
            when "0010" => segmentos <= "0100100"; ---2
            when "0011" => segmentos <= "0110000"; ---3
            when "0100" => segmentos <= "0011001"; ---4
            when "0101" => segmentos <= "0010010"; ---5
            when "0110" => segmentos <= "0000010"; ---6
            when "0111" => segmentos <= "1111000"; ---7
            when "1000" => segmentos <= "0000000"; ---8
            when "1001" => segmentos <= "0010000"; ---9
            when others => segmentos <= "1111111"; ---apagado
        end case;
    end process p_decodificar;
end architecture combinacional;