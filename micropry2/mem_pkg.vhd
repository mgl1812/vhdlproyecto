library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mem_pkg is

    constant DATA_WIDTH : integer := 8;
    constant ADDR_WIDTH : integer := 4;   -- 2^4 = 16 direcciones (suficiente para 12)
    constant MEM_DEPTH  : integer := 12;  -- 4 números x 3 dígitos

    subtype t_data is std_logic_vector(DATA_WIDTH - 1 downto 0);
    subtype t_addr is std_logic_vector(ADDR_WIDTH - 1 downto 0);

    type t_rom_array is array (0 to MEM_DEPTH - 1) of t_data;

    -- Números: 100, 30, 2, 170 (centenas-decenas-unidades)
    constant ROM_DATA : t_rom_array := (
        0  => x"01",  -- 100: centenas
        1  => x"00",  -- 100: decenas
        2  => x"00",  -- 100: unidades
        3  => x"00",  -- 30:  centenas
        4  => x"03",  -- 30:  decenas
        5  => x"00",  -- 30:  unidades
        6  => x"00",  -- 2:   centenas
        7  => x"00",  -- 2:   decenas
        8  => x"02",  -- 2:   unidades
        9  => x"01",  -- 170: centenas
        10 => x"07",  -- 170: decenas
        11 => x"00"   -- 170: unidades
    );

    type t_state is (S1_READ_ROM,
                     S2_WRITE_RAM,
                     S3_READ_RAM,
                     S4_DISPLAY);

end package mem_pkg;