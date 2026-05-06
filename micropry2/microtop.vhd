library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

-- Módulo principal que conecta reloj, memorias,
-- controlador y displays
entity microtop is
    port (
        entrada_clk : in  std_logic;
        btn_rst     : in  std_logic;
        HEX0        : out std_logic_vector(6 downto 0);  -- Unidades
        HEX1        : out std_logic_vector(6 downto 0);  -- Decenas
        HEX2        : out std_logic_vector(6 downto 0);  -- Centenas
        HEX3        : out std_logic_vector(6 downto 0)   -- Apagado
    );
end entity microtop;

architecture memorias of microtop is

    -- Reset interno (invertido)
    signal rst_i        : std_logic;

    -- Reloj dividido
    signal clk_div      : std_logic;

    -- Señal para congelar el controlador
    signal hold_s       : std_logic;

    -- Señales de comunicación con memorias
    signal addr_bus     : t_addr;
    signal addr_cap     : t_addr;
    signal we_s         : std_logic;
    signal re_s         : std_logic;
    signal rom_out_s    : t_data;
    signal ram_out_s    : t_data;
    signal reg_dato_s   : t_data;
    signal data_out_s   : t_data;
    signal actualizar_s : std_logic;

    -- Registros temporales para armar números
    signal temp_centenas : t_data;
    signal temp_decenas  : t_data;

    -- Datos finales a mostrar
    signal disp_centenas : t_data;
    signal disp_decenas  : t_data;
    signal disp_unidades : t_data;

    -- Indica estado S4 (display)
    signal en_s4 : std_logic;

    -- Control de pausa para mostrar 170
    constant PAUSA_CICLOS : integer := 12;  
    signal   pausa_cnt    : integer range 0 to PAUSA_CICLOS := 0;
    signal   en_pausa     : std_logic := '0';

    -- Bandera para limpiar display (no usada directamente aquí)
    signal limpiar_pending : std_logic := '0';

    -- Frecuencia fija del divisor de reloj
    constant MODO_FREQ_FIJO : std_logic_vector(1 downto 0) := "00";

    -- Componentes del sistema
    component gen_reloj is
        port (
            entrada_clk : in  std_logic;
            modo_freq   : in  std_logic_vector(1 downto 0);
            salida_clk  : out std_logic
        );
    end component;

    component rom is
        port (
            clk      : in  std_logic;
            re       : in  std_logic;
            addr     : in  t_addr;
            data_out : out t_data
        );
    end component;

    component ram is
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            we       : in  std_logic;
            re       : in  std_logic;
            addr     : in  t_addr;
            data_in  : in  t_data;
            data_out : out t_data
        );
    end component;

    component controlador is
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            hold         : in  std_logic;
            addr         : out t_addr;
            we           : out std_logic;
            re           : out std_logic;
            reg_dato     : out t_data;
            ram_out      : in  t_data;
            data_out     : out t_data;
            rom_out      : in  t_data;
            addr_captura : out t_addr;
            actualizar   : out std_logic
        );
    end component;

    component bcd_7seg is
        port (
            data_in : in  t_data;
            seg     : out std_logic_vector(6 downto 0)
        );
    end component;

begin

    -- Inversión del botón de reset
    rst_i <= not btn_rst;

    -- Detecta estado S4 (ni lectura ni escritura)
    en_s4 <= '1' when (re_s = '0' and we_s = '0') else '0';

    -- Hold depende de si está en pausa
    hold_s <= en_pausa;

    -- Instancia del divisor de reloj
    u_genreloj : gen_reloj
        port map (entrada_clk => entrada_clk, modo_freq => MODO_FREQ_FIJO, salida_clk => clk_div);

    -- Memoria ROM
    u_rom : rom
        port map (clk => clk_div, re => re_s, addr => addr_bus, data_out => rom_out_s);

    -- Memoria RAM
    u_ram : ram
        port map (clk => clk_div, rst => rst_i, we => we_s, re => re_s,
                  addr => addr_bus, data_in => reg_dato_s, data_out => ram_out_s);

    -- Controlador principal
    u_ctrl : controlador
        port map (
            clk          => clk_div,
            rst          => rst_i,
            hold         => hold_s,
            addr         => addr_bus,
            we           => we_s,
            re           => re_s,
            reg_dato     => reg_dato_s,
            ram_out      => ram_out_s,
            data_out     => data_out_s,
            rom_out      => rom_out_s,
            addr_captura => addr_cap,
            actualizar   => actualizar_s
        );

    -- Lógica de armado y visualización de números
    process(clk_div, rst_i)
    begin
        if rst_i = '1' then
            -- Reset de registros
            temp_centenas   <= (others => '0');
            temp_decenas    <= (others => '0');
            disp_centenas   <= (others => '0');
            disp_decenas    <= (others => '0');
            disp_unidades   <= (others => '0');
            pausa_cnt       <= 0;
            en_pausa        <= '0';
            limpiar_pending <= '0';

        elsif rising_edge(clk_div) then

            if en_pausa = '1' then
                -- Mantiene el valor durante la pausa
                if pausa_cnt = PAUSA_CICLOS - 1 then
                    -- Termina pausa y limpia display
                    disp_centenas   <= (others => '0');
                    disp_decenas    <= (others => '0');
                    disp_unidades   <= (others => '0');
                    pausa_cnt       <= 0;
                    en_pausa        <= '0';
                else
                    pausa_cnt <= pausa_cnt + 1;
                end if;

            elsif en_s4 = '1' then
                -- Organización de datos según dirección
                case to_integer(unsigned(addr_cap)) is

                    -- Captura centenas
                    when 0 | 3 | 6 | 9 =>
                        temp_centenas <= data_out_s;

                    -- Captura decenas
                    when 1 | 4 | 7 | 10 =>
                        temp_decenas  <= data_out_s;

                    -- Arma número completo
                    when 2 | 5 | 8 =>
                        disp_centenas <= temp_centenas;
                        disp_decenas  <= temp_decenas;
                        disp_unidades <= data_out_s;

                    -- Caso especial: 170
                    when 11 =>
                        disp_centenas <= temp_centenas;
                        disp_decenas  <= temp_decenas;
                        disp_unidades <= data_out_s;
                        en_pausa      <= '1';
                        pausa_cnt     <= 0;

                    when others => null;

                end case;
            end if;
        end if;
    end process;

    -- Conversión a 7 segmentos
    u_hex0 : bcd_7seg port map (data_in => disp_unidades,  seg => HEX0);
    u_hex1 : bcd_7seg port map (data_in => disp_decenas,   seg => HEX1);
    u_hex2 : bcd_7seg port map (data_in => disp_centenas,  seg => HEX2);

    -- Display apagado
    HEX3 <= "1111111";

end architecture memorias;