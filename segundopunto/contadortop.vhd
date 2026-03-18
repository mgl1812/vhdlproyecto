library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity contadortop is
    port(
        reloj_base   : in  std_logic;                    ---reloj principal del sistema
        btn_iniciar  : in  std_logic;                    ---botón de inicio del conteo
        btn_pausar   : in  std_logic;                    ---botón para pausar el conteo
        btn_reiniciar: in  std_logic;                    ---botón para reiniciar el sistema
        seg_unidades : out std_logic_vector(6 downto 0); ---display de unidades de segundo
        seg_decenas  : out std_logic_vector(6 downto 0); ---display de decenas de segundo
        seg_minutos  : out std_logic_vector(7 downto 0)  ---display de minutos
    );
end entity contadortop;

architecture rtl of contadortop is

    ---declaracion de modulos internos del sistema

    component gen_reloj is  ---divisor de frecuencia
        port(
            entrada_clk  : in  std_logic;
            modo_freq    : in  std_logic_vector(1 downto 0);
            salida_clk   : out std_logic
        );
    end component;

    component decodificador7seg is  ---conversor BCD a 7 segmentos
        port(
            entrada_bcd  : in  std_logic_vector(3 downto 0);
            salida_seg   : out std_logic_vector(6 downto 0)
        );
    end component;

    component contador_tiempo is  ---contador de segundos y minutos en BCD
        port(
            pulso    : in  std_logic;
            reset    : in  std_logic;
            uni      : out std_logic_vector(3 downto 0);
            dec      : out std_logic_vector(3 downto 0);
            min      : out std_logic_vector(3 downto 0)
        );
    end component;

    ---señales internas del sistema

    signal clk_dividido  : std_logic;                    ---reloj reducido para el contador
    signal habilitado    : std_logic := '0';             ---controla si el contador corre
    signal bcd_u         : std_logic_vector(3 downto 0); ---bcd de unidades
    signal bcd_d         : std_logic_vector(3 downto 0); ---bcd de decenas
    signal bcd_m         : std_logic_vector(3 downto 0); ---bcd de minutos

begin

    -- Instancia del divisor de frecuencia
    u_reloj: gen_reloj
        port map(
            entrada_clk => reloj_base,
            modo_freq   => "00", --- para seleccionar frecuencia
            salida_clk  => clk_dividido
        );

    ---proceso de control: gestiona los botones de inicio, pausa y reinicio
    control: process(reloj_base)
    begin
        if rising_edge(reloj_base) then
            if btn_reiniciar = '0' then
                habilitado <= '0';               ---reinicio apaga el contador
            elsif btn_pausar = '0' then
                habilitado <= '0';               ---pausa detiene el conteo
            elsif btn_iniciar = '0' then
                habilitado <= '1';               ---inicio activa el conteo
            end if;
        end if;
    end process control;

    ---instancia del contador principal (solo activo cuando habilitado = '1')
    u_contador: contador_tiempo
        port map(
            pulso => clk_dividido and habilitado,
            reset => btn_reiniciar,
            uni   => bcd_u,
            dec   => bcd_d,
            min   => bcd_m
        );

    ---decodificadores bcd a 7 segmentos para cada display
    u_disp_u: decodificador7seg port map(entrada_bcd => bcd_u, salida_seg => seg_unidades);
    u_disp_d: decodificador7seg port map(entrada_bcd => bcd_d, salida_seg => seg_decenas);
    u_disp_m: decodificador7seg port map(entrada_bcd => bcd_m, salida_seg => seg_minutos(6 downto 0));

    ---punto decimal del display de minutos siempre apagado
    seg_minutos(7) <= '0';

end architecture rtl;