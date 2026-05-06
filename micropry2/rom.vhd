library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

-- Memoria ROM: entrega datos según dirección
entity rom is
    port (
        clk      : in  std_logic;
        re       : in  std_logic;        -- Habilita lectura                     
        addr     : in  t_addr;           -- Dirección de memoria               
        data_out : out t_data            -- Dato leído                           
    );
end entity rom;
 
architecture mnr of rom is
    -- Contenido de la ROM (definido en mem_pkg)
    constant MEM : t_rom_array := ROM_DATA;
begin

    -- Lectura asíncrona (sin esperar reloj)
    process(re, addr)
    begin
        if re = '1' then
            -- Devuelve el dato de la dirección indicada
            data_out <= MEM(to_integer(unsigned(addr)));
        else
            -- Salida en cero si no hay lectura
            data_out <= (others => '0');
        end if;
    end process;

end architecture mnr;