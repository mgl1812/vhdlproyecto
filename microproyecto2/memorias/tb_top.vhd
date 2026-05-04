library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

entity tb_top is
    -- Un testbench no tiene puertos
end entity tb_top;

architecture sim of tb_top is

    -- Señales de estímulo
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';

    -- Señales de interconexión (Buses)
    signal addr_bus   : t_addr;
    signal we_s       : std_logic;
    signal re_s       : std_logic;
    signal rom_out_s  : t_data;
    signal ram_out_s  : t_data;
    signal reg_dato_s : t_data;
    signal data_out_s : t_data;

    -- Constante para el periodo del reloj
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz

begin

    -- 1. Instancia de la ROM
    u_rom : entity work.rom
        port map (
            clk      => clk,
            re       => re_s,
            addr     => addr_bus,
            data_out => rom_out_s
        );

    -- 2. Instancia de la RAM
    u_ram : entity work.ram
        port map (
            clk      => clk,
            rst      => rst,
            we       => we_s,
            re       => re_s,
            addr     => addr_bus,
            data_in  => reg_dato_s,
            data_out => ram_out_s
        );

    -- 3. Instancia del Controlador
    u_ctrl : entity work.controlador
        port map (
            clk      => clk,
            rst      => rst,
            addr     => addr_bus,
            we       => we_s,
            re       => re_s,
            reg_dato => reg_dato_s,
            ram_out  => ram_out_s,
            data_out => data_out_s,
            rom_out  => rom_out_s
        );

    -- --------------------------------------------------------
    -- Generación del Reloj
    -- --------------------------------------------------------
    p_clk : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- --------------------------------------------------------
    -- Proceso de Estímulos
    -- --------------------------------------------------------
    p_stim : process
    begin
        -- Estado inicial: Reset activo
        rst <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Liberar reset y dejar que la FSM opere
        rst <= '0';
        
        -- Esperar el tiempo suficiente para recorrer todas las direcciones (0 a 3)
        -- Cada dirección toma 4 estados (4 ciclos de reloj)
        -- 4 direcciones * 4 ciclos = 16 ciclos. Damos un margen de 20 ciclos.
        wait for CLK_PERIOD * 20;

        -- Aplicar reset nuevamente para validar que el contador de direcciones vuelve a 0
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';

        -- Dejar simular un poco más
        wait for CLK_PERIOD * 10;
        
        -- Detener simulación (VHDL-2008 en adelante)
        -- Dejar simular un poco más
        wait for CLK_PERIOD * 10;
        
        -- Detener simulación (Para VHDL-93)
        wait; 
      
        -- Si usas VHDL-93, reemplaza la línea anterior por un `wait;` infinito:
        -- wait;
    end process;

end architecture sim;