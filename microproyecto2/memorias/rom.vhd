library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

entity rom is
    port (
        clk      : in  std_logic;
        re       : in  std_logic;                        
        addr     : in  t_addr;                
        data_out : out t_data                            
    );
end entity rom;
 
-- En rom
architecture mnr of rom is
    constant MEM : t_rom_array := ROM_DATA;
begin
    -- Lectura combinacional (asíncrona) para eliminar la latencia de un ciclo
    process(re, addr)
    begin
        if re = '1' then
            data_out <= MEM(to_integer(unsigned(addr)));
        else
            data_out <= (others => '0');
        end if;
    end process;
end architecture mnr;