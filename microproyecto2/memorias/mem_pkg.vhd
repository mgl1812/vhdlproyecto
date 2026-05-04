library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mem_pkg is

    
    -- Parámetros de memoria
   
    constant DATA_WIDTH : integer := 8;  -- bits por dato
    constant ADDR_WIDTH : integer := 2;  -- bits de dirección (2^2 = 4 posiciones)
    constant MEM_DEPTH  : integer := 4;  -- número de posiciones (addr 0 a 3)

    
    -- Tipos base
   
    subtype t_data is std_logic_vector(DATA_WIDTH - 1 downto 0);
    subtype t_addr is std_logic_vector(ADDR_WIDTH - 1 downto 0);

    -- Tipo arreglo para inicializar la ROM
    type t_rom_array is array (0 to MEM_DEPTH - 1) of t_data;

    
    -- Contenido de la ROM — datos predefinidos
    -- Dígitos a mostrar en display 7seg: 1, 2, 3, 4
    -- addr 0 → 0x01 → muestra "1"
    -- addr 1 → 0x02 → muestra "2"
    -- addr 2 → 0x03 → muestra "3"
    -- addr 3 → 0x04 → muestra "4"
   
    constant ROM_DATA : t_rom_array := (
        0 => x"01",
        1 => x"02",
        2 => x"03",
        3 => x"04"
    );

    
    -- Estados de la FSM
    
    type t_state is (S1_READ_ROM,
                     S2_WRITE_RAM,
                     S3_READ_RAM,
                     S4_DISPLAY);

end package mem_pkg;