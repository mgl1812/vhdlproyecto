
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

entity tb_top is
end entity tb_top;

architecture sim of tb_top is

    
    -- Estímulos
    
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';   -- Activo alto (= rst_i interno de microtop)

    
    -- Buses internos — visibles en formas de onda
    
    signal addr_bus   : t_addr;                       -- 4 bits (ADDR_WIDTH=4)
    signal we_s       : std_logic;
    signal re_s       : std_logic;
    signal rom_out_s  : t_data;                       -- salida combinacional ROM
    signal ram_out_s  : t_data;                       -- salida síncrona RAM
    signal reg_dato_s : t_data;                       -- dato ROM a RAM (controlador)
    signal data_out_s : t_data;                       -- dato RAM a display
    signal hold_s     : std_logic := '0';             -- siempre '0' en TB (sin pausa)

    
    -- Registros de dígitos y salidas 7 segmentos
    
    signal digito_unidades : t_data := (others => '0');
    signal digito_decenas  : t_data := (others => '0');
    signal digito_centenas : t_data := (others => '0');

    signal HEX0 : std_logic_vector(6 downto 0);      -- unidades
    signal HEX1 : std_logic_vector(6 downto 0);      -- decenas
    signal HEX2 : std_logic_vector(6 downto 0);      -- centenas

    
    -- Reloj ficticio de simulación — 50 MHz (20 ns)
    -- La FSM opera cada ciclo (sin divisor), suficiente para ver todas las
    -- señales en la forma de onda sin esperar millones de ciclos reales.
    
    constant CLK_PERIOD : time := 20 ns;

    
    -- Ciclos necesarios para un recorrido completo:
    --   12 direcciones × 4 estados (S1 a S2 a S3 a S4) = 48 ciclos por vuelta
    
begin

    
    -- 1. ROM
    
    u_rom : entity work.rom
        port map (
            clk      => clk,
            re       => re_s,
            addr     => addr_bus,
            data_out => rom_out_s
        );

    
    -- 2. RAM
    
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

    
    -- 3. Controlador (FSM)
    
    u_ctrl : entity work.controlador
        port map (
            clk          => clk,
            rst          => rst,
            hold         => hold_s,
            addr         => addr_bus,
            we           => we_s,
            re           => re_s,
            reg_dato     => reg_dato_s,
            ram_out      => ram_out_s,
            data_out     => data_out_s,
            rom_out      => rom_out_s,
            addr_captura => open,
            actualizar   => open
        );

   
    -- 4. Captura de dígitos (misma lógica que microtop, usando clk directo)
    
    p_captura : process(clk, rst)
    begin
        if rst = '1' then
            digito_centenas <= (others => '0');
            digito_decenas  <= (others => '0');
            digito_unidades <= (others => '0');
        elsif rising_edge(clk) then
            case to_integer(unsigned(addr_bus)) is
                when 0 | 3 | 6 | 9  => digito_centenas <= data_out_s;
                when 1 | 4 | 7 | 10 => digito_decenas  <= data_out_s;
                when 2 | 5 | 8 | 11 => digito_unidades <= data_out_s;
                when others         => null;
            end case;
        end if;
    end process p_captura;

   
    -- 5. Decodificadores BCD → 7 segmentos
    
    u_hex0 : entity work.bcd_7seg
        port map (
            data_in => digito_unidades,
            seg     => HEX0
        );

    u_hex1 : entity work.bcd_7seg
        port map (
            data_in => digito_decenas,
            seg     => HEX1
        );

    u_hex2 : entity work.bcd_7seg
        port map (
            data_in => digito_centenas,
            seg     => HEX2
        );

   
    -- Generación del reloj ficticio
    
    p_clk : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process p_clk;

    
    -- Proceso de estímulos
    
    p_stim : process
    begin
        
        -- FASE 1: Reset inicial
        -- Mantener rst='1' durante 4 ciclos para inicializar la FSM y la RAM
        
        rst <= '1';
        wait for CLK_PERIOD * 4;

        
        -- FASE 2: Operación normal — 2 vueltas completas       
        
        report "=== FASE 2: FSM en operacion ===" severity note;
        rst <= '0';
        wait for CLK_PERIOD * 100;

        
        -- FASE 3: Reset intermedio
        -- Verifica que addr_cnt vuelve a 0 y la RAM se borra
        
        report "=== FASE 3: Reset intermedio ===" severity note;
        rst <= '1';
        wait for CLK_PERIOD * 4;
        rst <= '0';

        -- 2 vueltas más para confirmar que el sistema reinicia correctamente
        wait for CLK_PERIOD * 100;

        
        -- FASE 4: Reset corto — robustez ante pulsos breves
        
        report "=== FASE 4: Reset corto ===" severity note;
        rst <= '1';
        wait for CLK_PERIOD * 1;      -- pulso de solo 1 ciclo
        rst <= '0';
        wait for CLK_PERIOD * 60;

        
        -- FIN de simulación
        
        report "=== FIN DE SIMULACION ===" severity note;
        wait;   -- VHDL-93: detiene el proceso indefinidamente
    end process p_stim;

end architecture sim;