library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity ctrl_espacio is
    port(
        clk_fpga     : in  std_logic; --- reloj de la fpga (estándar)
        rst_btn      : in  std_logic; --- reset para el botón
        sensor       : in  std_logic; ---botón que actua como persona (si se presiona la primera vez, simula entrada,
		                                --- si se presiona por segunda vez, se simula la salida)
 
        hex0         : out std_logic_vector(6 downto 0); -- unidades
        hex1         : out std_logic_vector(6 downto 0); -- decenas
        hex2         : out std_logic_vector(6 downto 0); -- centenas (solo segundo contador)
        hex3         : out std_logic_vector(6 downto 0); -- apagado mientras cuenta hasta 35
 
        led_alarma   : out std_logic; --- led que indica que la persona sigue después de los 35 segundos
        led_feliz    : out std_logic --- led de felicitación que indica que la persona salió antes de los 35 s
    );
end entity ctrl_espacio;
 
architecture mon of ctrl_espacio is
 
 -----declaro componentes (divisor de frecuencias, archivo de bcd y el archivo de ambos contadores)
 --------- archivo de divisor de reloj
    component gen_reloj
        port(
            entrada_clk : in  std_logic;
            modo_freq   : in  std_logic_vector(1 downto 0);
            salida_clk  : out std_logic
        );
    end component;
 ---------archivo de bcd
    component seg_bcd
        port(
            digito   : in  std_logic_vector(3 downto 0);
            segmentos: out std_logic_vector(6 downto 0)
        );
    end component;
 --------- archivo de contador inicial ( hasta 35 seg)
    component timer_inicial
        port(
            clk_fpga : in  std_logic;---reloj de la fpga (sin divisor)
            clk_1hz  : in  std_logic;---reloj ya dividido
            rst      : in  std_logic;---reset activo en alto 
            btn      : in  std_logic;---botón 1 toque entra persona segundo toque sale persona
            unidades : out std_logic_vector(3 downto 0);---digito bcd de las unidades
            decenas  : out std_logic_vector(3 downto 0);---digito bcd de las centenas
            alarma   : out std_logic;---'1' cuando se superan los 35 seg
            feliz    : out std_logic;---'1' cuando la persona sale antes de los 35 seg 
            activo   : out std_logic;---'1' mientras el temporizador está corriendo
            ocupado  : out std_logic---'1' mientras hay una persona en el espacio
        );
    end component;
	 ------ archivo de contador adicional (facturacion)
    component timer_exceso
        port(
            clk_1hz  : in  std_logic;
            rst      : in  std_logic;
            iniciar  : in  std_logic;
            persona  : in  std_logic;
            uni_exc  : out std_logic_vector(3 downto 0);
            dec_exc  : out std_logic_vector(3 downto 0);
            cen_exc  : out std_logic_vector(3 downto 0);
            corriendo: out std_logic
        );
    end component;
 
    ---- señales internas (cables del sistema)
 
    signal clk_1hz       : std_logic;
 
    ---bcd para contador inicial (35 segundos)
    signal bcd_uni1      : std_logic_vector(3 downto 0);-- unidades
    signal bcd_dec1      : std_logic_vector(3 downto 0);---decenas
 
    ---bcd para contador de exceso (adicional)
    signal bcd_uni2      : std_logic_vector(3 downto 0);
    signal bcd_dec2      : std_logic_vector(3 downto 0);
    signal bcd_cen2      : std_logic_vector(3 downto 0);
 
    --estado del sistema 
    signal sig_alarma    : std_logic;---señal para activar el led alarma
    signal sig_feliz     : std_logic;---señal para activar el led feliz 
    signal sig_activo    : std_logic;--- '1' mientras el temporizador está contando
    signal sig_ocupado   : std_logic; -- '1' mientras hay una persona
	 signal sig_corriendo : std_logic; --- para mostrar cual contador para cada fase (fase uno timer_inicial, fase 2 timer_exceso)
 
    -- bcd seleccionado para los displays (mux)
    signal mux_uni       : std_logic_vector(3 downto 0);
    signal mux_dec       : std_logic_vector(3 downto 0);
    signal mux_cen       : std_logic_vector(3 downto 0);
 
    -- todos los segmentos en alto = display apagado
    constant APAGADO : std_logic_vector(6 downto 0) := "1111111";
 
    ---señales internas (botones son activos en bajo)
    signal sensor_int : std_logic; ---sensor  invertido: '1' = presionado
    signal rst_int    : std_logic; ---reset   invertido: '1' = presionado
 
begin
 
    ---inversión de botones (botón activo bajo a activo alto interno)
    sensor_int <= not sensor;
    rst_int    <= not rst_btn;
 
    --- mapeo de puertos del divisor de frecuencia: 50 MHz a 1 Hz 
    U_RELOJ: gen_reloj
        port map(
            entrada_clk => clk_fpga,
            modo_freq   => "00",       ---1 hz fijo, segundos reales 
            salida_clk  => clk_1hz
        );
 
    ---mapeo de puertos del contador de los primeros 35 segundos
    U_TIMER1: timer_inicial
        port map(
            clk_fpga => clk_fpga, 
            clk_1hz  => clk_1hz,
            rst      => rst_int, 
            btn      => sensor_int,
            unidades => bcd_uni1,
            decenas  => bcd_dec1,
            alarma   => sig_alarma,
            feliz    => sig_feliz,
            activo   => sig_activo,
            ocupado  => sig_ocupado
        );
 
    ---mapeo de puertos para el contador de exceso (facturación) 
    U_TIMER2: timer_exceso
        port map(
            clk_1hz  => clk_1hz,
            rst      => rst_int,
            iniciar  => sig_alarma,
            persona  => sig_ocupado,
            uni_exc  => bcd_uni2,
            dec_exc  => bcd_dec2,
            cen_exc  => bcd_cen2,
            corriendo=> sig_corriendo
        );
 
    ---multiplexor de displays
    ---si la señal sig_corriendo='1' significa que estamos en la fase 2 (facturación)  por tanto mostramos timer_exceso
    ---de lo contrario  si estamos en  fase 1 ,mostramos timer_inicial
    mux_uni <= bcd_uni2 when sig_corriendo = '1' else bcd_uni1;
    mux_dec <= bcd_dec2 when sig_corriendo = '1' else bcd_dec1;
    mux_cen <= bcd_cen2 when sig_corriendo = '1' else "0000";
 
    ----decodificadores bcd a 7 seg 
    U_HEX0: seg_bcd port map(digito => mux_uni, segmentos => hex0); ---unidades
    U_HEX1: seg_bcd port map(digito => mux_dec, segmentos => hex1); ---decenas
    U_HEX2: seg_bcd port map(digito => mux_cen, segmentos => hex2); ---centenas
    hex3 <= APAGADO;                                                 ---sin uso
 
    --- leds de estado 
    led_alarma    <= sig_alarma;
    led_feliz     <= sig_feliz;
 
end architecture mon;