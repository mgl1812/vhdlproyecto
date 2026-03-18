library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity timer_inicial is
    port(
        clk_fpga : in  std_logic; --- reloj de la FPGA
        clk_1hz  : in  std_logic; --- reloj ya dividido (1 hz)
        rst      : in  std_logic; ---- reset activo en alto 
        btn      : in  std_logic; ---- botón 1 toque entra persona segundo toque sale persona
        unidades : out std_logic_vector(3 downto 0); ---- digito bcd de las unidades
        decenas  : out std_logic_vector(3 downto 0); ---- digito bcd de las centenas 
        alarma   : out std_logic; --- '1' cuando se superan los 35 seg
        feliz    : out std_logic; ---- '1' cuando la persona sale antes de los 35 seg 
        activo   : out std_logic; ---- '1' mientras el temporizador está corriendo
        ocupado  : out std_logic ----- '1' mientras hay una persona en el espacio
    );
end entity timer_inicial;
 
architecture lan of timer_inicial is
 
    ---estados del temporizador
    type t_estado is (ESPERAR, CONTANDO, ALERTA, CELEBRAR);
    signal estado_actual : t_estado := ESPERAR;
 
    ---contadores bcd
    signal cnt_uni : integer range 0 to 9 := 0;---contador para las unidades
    signal cnt_dec : integer range 0 to 3 := 0;---contador para las decenas
 
    ---señales para detector de flanco del botón (a 50 MHz)
    signal btn_reg1    : std_logic := '0'; -- muestra actual
    signal btn_reg2    : std_logic := '0'; -- muestra anterior
 
    ---contador de bloqueo: ignora el botón unos ciclos tras soltar reset
    signal bloqueo     : integer range 0 to 15 := 0;
 
    ---estado lógico de presencia (toggle)
    signal hay_persona : std_logic := '0';
 
begin
 
    ---process de detector de flanco (para comparar estado actual con el estado anterior del botón)
    p_flanco: process(clk_fpga)
    begin
        if rising_edge(clk_fpga) then
            if rst = '1' then
                btn_reg1    <= '0';---- si btn reg1 '1'
                btn_reg2    <= '0';---- si btn reg2 '0' 
                hay_persona <= '0';
                bloqueo     <= 15; -- activa bloqueo al entrar en reset ( para no tener que mantener presionado el botón)
            else
                btn_reg1 <= btn;
                btn_reg2 <= btn_reg1;
 
                -- cuenta regresiva del bloqueo post-reset
                if bloqueo > 0 then
                    bloqueo <= bloqueo - 1;
                end if;
 
                -- solo detecta flanco cuando el bloqueo ya acabó
                if btn_reg1 = '1' and btn_reg2 = '0' and bloqueo = 0 then
                    hay_persona <= not hay_persona;
                end if;
            end if;
        end if;
    end process p_flanco;
 
    ---proceso para maquina de estados ajustada a 1 hz
    p_control: process(clk_1hz)
    begin
        if rising_edge(clk_1hz) then
            if rst = '1' then
                estado_actual <= ESPERAR;
                cnt_uni       <= 0;
                cnt_dec       <= 0;
                alarma        <= '0';
                feliz         <= '0';
                activo        <= '0';
 
            else
                case estado_actual is
 
                    ---esperando que llegue una persona 
                    when ESPERAR =>
                        alarma  <= '0';
                        feliz   <= '0';
                        activo  <= '0';
                        cnt_uni <= 0;
                        cnt_dec <= 0;
                        if hay_persona = '1' then
                            estado_actual <= CONTANDO;
                            activo        <= '1';
                        end if;
 
                    ---contando los primeros 35 segundos 
                    when CONTANDO =>
                        activo <= '1';
                        alarma <= '0';
                        feliz  <= '0';
 
                        ---persona salió antes de 35s
                        if hay_persona = '0' then
                            estado_actual <= CELEBRAR;
 
                        ---llegó a 35 segundos con persona adentro
                        elsif cnt_dec = 3 and cnt_uni = 5 then
                            estado_actual <= ALERTA;
 
                        --- incremento de bcd
                        else
                            if cnt_uni = 9 then
                                cnt_uni <= 0;
                                cnt_dec <= cnt_dec + 1;
                            else
                                cnt_uni <= cnt_uni + 1;
                            end if;
                        end if;
 
                    ---- alarma: superó los 35 segundos 
                    when ALERTA =>
                        alarma <= '1';
                        feliz  <= '0';
                        activo <= '0';
                        ---espera a que la persona salga 
                        if hay_persona = '0' then
                            estado_actual <= ESPERAR;
                        end if;
 
                    ---felicitación: salió a tiempo 
                    when CELEBRAR =>
                        alarma <= '0';
                        feliz  <= '1';
                        activo <= '0';
                        estado_actual <= ESPERAR;
 
                    when others =>
                        estado_actual <= ESPERAR;
 
                end case;
            end if;
        end if;
    end process p_control;
 
    ---salidas
    unidades <= std_logic_vector(to_unsigned(cnt_uni, 4));
    decenas  <= std_logic_vector(to_unsigned(cnt_dec, 4));
    ocupado  <= hay_persona;
 
end architecture lan;
 