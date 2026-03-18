library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 

---entidad principal: temporizador con un solo botón
---presión corta  : alterna Start / Stop
---presión > 2 s  : Reset del contador

entity temporizador1btn is 
    port(
        clk_in      : in  std_logic;                    ---reloj principal de la FPGA (50 MHz)
        btn         : in  std_logic;                    ---único botón (activo en bajo)
        disp_uni    : out std_logic_vector(6 downto 0); ---display unidades 
        disp_dec    : out std_logic_vector(6 downto 0); ---display decenas 
        disp_min    : out std_logic_vector(7 downto 0)  ---display minutos
    );
end entity temporizador1btn;
 
architecture rtl of temporizador1btn is
 
    ---componentes internos
    
    component gen_reloj is
        port(
            entrada_clk : in  std_logic;
            modo_freq   : in  std_logic_vector(1 downto 0);
            salida_clk  : out std_logic
        );
    end component;
 
    component decodificador7seg is
        port(
            entrada_bcd : in  std_logic_vector(3 downto 0);
            salida_seg  : out std_logic_vector(6 downto 0)
        );
    end component;
 
    component contador_tiempo is
        port(
            pulso : in  std_logic;
            reset : in  std_logic;
            uni   : out std_logic_vector(3 downto 0);
            dec   : out std_logic_vector(3 downto 0);
            min   : out std_logic_vector(3 downto 0)
        );
    end component;
 
    ---constantes de tiempo (base: clk_in = 50 MHz)
    ---2 segundos = 2 * 50_000_000 ciclos
   
    constant UMBRAL_RESET : integer := 100_000_000; -- 2 s a 50 MHz
 
    
    ---señales internas (cables del sistema)
   
 
    ---reloj dividido para el contador de tiempo
    signal clk_1hz       : std_logic;
 
    ---estado del contador principal
    signal habilitado     : std_logic := '0'; -- '1' = contando, '0' = pausado
    signal reset_cnt      : std_logic := '1'; ---reset activo en bajo
 
    ---salidas BCD del contador
    signal bcd_u : std_logic_vector(3 downto 0);
    signal bcd_d : std_logic_vector(3 downto 0);
    signal bcd_m : std_logic_vector(3 downto 0);
 
    ---sincronización y detección de flancos del botón
    signal btn_sync0      : std_logic := '1'; ---primer registro de sincronización
    signal btn_sync1      : std_logic := '1'; ---segundo registro de sincronización
    signal btn_prev       : std_logic := '1'; ---estado anterior del botón (para detectar flancos)
 
    ---contador de duración de pulsación (mide cuánto tiempo está presionado)
    signal hold_cnt       : integer range 0 to 100_000_001 := 0;
 
    --bandera para evitar acción de soltar si ya se ejecutó el reset
    signal reset_ejecutado : std_logic := '0';
 
begin
 
    
    ---divisor de frecuencia: 50 MHz -> 1 Hz
  
    u_reloj: gen_reloj
        port map(
            entrada_clk => clk_in,
            modo_freq   => "00",
            salida_clk  => clk_1hz
        );
 
    
    ---proceso principal: lógica del botón único
    
    
    ---sincronizar el botón con el reloj 
    ---mientras está presionado: contar ciclos
    ---si supera UMBRAL_RESET -> activar reset
    ---al soltar:
    ---si no se ejecutó reset -> alternar Start/Stop
    ---si se ejecutó reset -> no hacer nada 
  
    p_control: process(clk_in)
    begin
        if rising_edge(clk_in) then
 
            ---sincronización del botón (2 registros)
            btn_sync0 <= btn;
            btn_sync1 <= btn_sync0;
 
            ---reset del contador: señal normalmente inactiva ('1')
            reset_cnt <= '1';
 
            ---botón presionado (activo en bajo)
            if btn_sync1 = '0' then
 
                ---acumular tiempo de pulsación
                if hold_cnt < UMBRAL_RESET then
                    hold_cnt <= hold_cnt + 1;
                end if;
 
                ---si supera 2 segundos: ejecutar reset
                if hold_cnt >= UMBRAL_RESET and reset_ejecutado = '0' then
                    reset_cnt       <= '0'; -- Activa reset del contador
                    habilitado      <= '0'; -- Detiene el conteo
                    reset_ejecutado <= '1'; -- Marca que ya se resetó
                end if;
 
            -- ----botón suelto 
            else
                ---si había pulsación previa y NO se ejecutó reset -> alternar start/stop
                if btn_prev = '0' and reset_ejecutado = '0' then
                    habilitado <= not habilitado;
                end if;
 
                ---limpiar contadores y banderas al soltar
                hold_cnt        <= 0;
                reset_ejecutado <= '0';
            end if;
 
            ---guardar estado actual del botón para el siguiente ciclo
            btn_prev <= btn_sync1;
 
        end if;
    end process p_control;
 
    
    ---contador principal de tiempo
    
    u_contador: contador_tiempo
        port map(
            pulso => clk_1hz and habilitado,
            reset => reset_cnt,
            uni   => bcd_u,
            dec   => bcd_d,
            min   => bcd_m
        );
 
    
    ---decodificadores BCD -> 7 segmentos
    
    u_disp_u: decodificador7seg port map(entrada_bcd => bcd_u, salida_seg => disp_uni);
    u_disp_d: decodificador7seg port map(entrada_bcd => bcd_d, salida_seg => disp_dec);
    u_disp_m: decodificador7seg port map(entrada_bcd => bcd_m, salida_seg => disp_min(6 downto 0));
 
    ---punto decimal del display de minutos apagado
    disp_min(7) <= '0';
 
end architecture rtl;