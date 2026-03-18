library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decodificador7seg is
    port(
        entrada_bcd : in  std_logic_vector(3 downto 0); ---valor bcd de 4 bits (0-9)
        salida_seg  : out std_logic_vector(6 downto 0)  ---segmentos: g f e d c b a
    );
end entity decodificador7seg;

architecture ansk of decodificador7seg is
begin

    ---decodificación BCD a segmentos (activo en bajo)
    p_decodificar: process(entrada_bcd)
    begin
        case entrada_bcd is
            when "0000" => salida_seg <= "1000000"; ---dígito 0
            when "0001" => salida_seg <= "1111001"; ---dígito 1
            when "0010" => salida_seg <= "0100100"; ---dígito 2
            when "0011" => salida_seg <= "0110000"; ---dígito 3
            when "0100" => salida_seg <= "0011001"; ---dígito 4
            when "0101" => salida_seg <= "0010010"; ---dígito 5
            when "0110" => salida_seg <= "0000010"; ---dígito 6
            when "0111" => salida_seg <= "1111000"; ---dígito 7
            when "1000" => salida_seg <= "0000000"; ---dígito 8
            when "1001" => salida_seg <= "0010000"; ---dígito 9
            when others => salida_seg <= "1111111"; ---display apagado
        end case;
    end process p_decodificar;

end architecture ansk;
