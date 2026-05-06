
-- Testbench: tb_microtop

-- Este testbench instancia directamente ROM, RAM, controlador
-- y decodificadores bcd_7seg sin usar gen_reloj, utilizando un
-- reloj ficticio de 20 ns (50 MHz equivalente) para que todas
-- las señales internas sean visibles en las formas de onda.
--
-- GUIA PARA LEER LAS FORMAS DE ONDA:
--
-- addr_bus: dirección activa. Avanza de 0000 a 1011 (0 a 11)
--   y vuelve a 0000. Cada grupo de 3 direcciones corresponde
--   a un número: 0-1-2 = 100, 3-4-5 = 30, 6-7-8 = 2, 9-10-11 = 170.
--
-- re_s y we_s: indican el estado de la FSM.
--   re=1, we=0 -> S1 (leyendo ROM) o S3 (leyendo RAM)
--   re=0, we=1 -> S2 (escribiendo en RAM)
--   re=0, we=0 -> S4 (mostrando en display)
--
-- rom_out_s: dato que entrega la ROM según addr_bus.
--   La mayoría de valores son 0x00 porque los números 100, 30,
--   2 y 170 tienen muchos dígitos en cero. Los valores distintos
--   de cero que se verán son:
--     addr 0  -> 00000001 (centena de 100, valor decimal 1)
--     addr 4  -> 00000011 (decena  de 30,  valor decimal 3)
--     addr 8  -> 00000010 (unidad  de 2,   valor decimal 2)
--     addr 9  -> 00000001 (centena de 170, valor decimal 1)
--     addr 10 -> 00000111 (decena  de 170, valor decimal 7)
--   El resto de posiciones contienen 00000000 (dígitos cero).
--
-- reg_dato_s: captura el dato de ROM al final de S1 para
--   escribirlo en RAM en S2. Debe coincidir con rom_out_s
--   del ciclo anterior con un ciclo de retardo.
--
-- ram_out_s: dato leído de RAM en S3. Aparece un ciclo después
--   de que we_s estuvo activo (latencia síncrona de la RAM).
--   Sus valores deben ser idénticos a los de rom_out_s ya que
--   la RAM simplemente almacena lo que leyó la ROM.
--
-- data_out_s: dato válido únicamente en S4 (re=0, we=0).
--   En los otros estados vale 00000000. Coincide con ram_out_s.
--
-- disp_centenas, disp_decenas, disp_unidades: registros BCD
--   que se actualizan al completar cada número (en addr 2,5,8,11).
--   Muestran el valor decimal de cada dígito (0 a 9).
--
-- HEX0 (unidades), HEX1 (decenas), HEX2 (centenas):
--   Patrón de 7 segmentos activo-bajo. Los patrones esperados son:
--     1000000 -> dígito 0    0110000 -> dígito 3
--     1111001 -> dígito 1    0011001 -> dígito 4
--     0100100 -> dígito 2    1111000 -> dígito 7
--   Secuencia visible: 000 -> 100 -> 030 -> 002 -> 170 -> 000 ...
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

entity tb_microtop is
end entity tb_microtop;

architecture sim of tb_microtop is

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';

    signal addr_bus   : t_addr;
    signal we_s       : std_logic;
    signal re_s       : std_logic;
    signal rom_out_s  : t_data;
    signal ram_out_s  : t_data;
    signal reg_dato_s : t_data;
    signal data_out_s : t_data;
    signal addr_cap   : t_addr;

    signal HEX0 : std_logic_vector(6 downto 0);
    signal HEX1 : std_logic_vector(6 downto 0);
    signal HEX2 : std_logic_vector(6 downto 0);

    signal disp_unidades : t_data := (others => '0');
    signal disp_decenas  : t_data := (others => '0');
    signal disp_centenas : t_data := (others => '0');
    signal temp_cent     : t_data := (others => '0');
    signal temp_dec      : t_data := (others => '0');

    signal en_s4 : std_logic;

    constant CLK_PERIOD : time := 20 ns;

begin

    u_rom : entity work.rom
        port map (clk => clk, re => re_s, addr => addr_bus, data_out => rom_out_s);

    u_ram : entity work.ram
        port map (clk => clk, rst => rst, we => we_s, re => re_s,
                  addr => addr_bus, data_in => reg_dato_s, data_out => ram_out_s);

    -- hold='0': sin pausas en simulacion, FSM corre libremente
    u_ctrl : entity work.controlador
        port map (
            clk          => clk,
            rst          => rst,
            hold         => '0',
            addr         => addr_bus,
            we           => we_s,
            re           => re_s,
            reg_dato     => reg_dato_s,
            ram_out      => ram_out_s,
            data_out     => data_out_s,
            rom_out      => rom_out_s,
            addr_captura => addr_cap,
            actualizar   => open
        );

    -- S4 activo cuando re=0 y we=0
    en_s4 <= '1' when (re_s = '0' and we_s = '0') else '0';

    -- Captura digitos en S4 segun addr_cap para actualizar displays
    p_captura : process(clk, rst)
    begin
        if rst = '1' then
            temp_cent     <= (others => '0');
            temp_dec      <= (others => '0');
            disp_centenas <= (others => '0');
            disp_decenas  <= (others => '0');
            disp_unidades <= (others => '0');
        elsif rising_edge(clk) then
            if en_s4 = '1' then
                case to_integer(unsigned(addr_cap)) is
                    when 0 | 3 | 6 | 9  => temp_cent     <= data_out_s;
                    when 1 | 4 | 7 | 10 => temp_dec      <= data_out_s;
                    when 2 | 5 | 8 | 11 =>
                        disp_centenas <= temp_cent;
                        disp_decenas  <= temp_dec;
                        disp_unidades <= data_out_s;
                    when others => null;
                end case;
            end if;
        end if;
    end process p_captura;

    u_hex0 : entity work.bcd_7seg port map (data_in => disp_unidades, seg => HEX0);
    u_hex1 : entity work.bcd_7seg port map (data_in => disp_decenas,  seg => HEX1);
    u_hex2 : entity work.bcd_7seg port map (data_in => disp_centenas, seg => HEX2);

    p_clk : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process p_clk;

    -- Secuencia de estimulos:
    -- Fase 1: reset inicial, luego 4 ciclos completos (192 ciclos)
    -- Fase 2: reset intermedio para verificar reinicio limpio
    p_stim : process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 4;
        rst <= '0';
        wait for CLK_PERIOD * 200;
        rst <= '1';
        wait for CLK_PERIOD * 4;
        rst <= '0';
        wait for CLK_PERIOD * 200;
        wait;
    end process p_stim;

end architecture sim;