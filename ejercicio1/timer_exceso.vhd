library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity timer_exceso is
    port(
        clk_1hz  : in  std_logic; ---reloj de 1 hz
        rst      : in  std_logic; ---reset síncrono 
        iniciar  : in  std_logic; ---'1' cuando se activa la alarma de 35s
        persona  : in  std_logic; ---'1' mientras la persona sigue en el espacio
        uni_exc  : out std_logic_vector(3 downto 0);---bcd unidades del tiempo de exceso
        dec_exc  : out std_logic_vector(3 downto 0);---bcd decenas  del tiempo de exceso
        cen_exc  : out std_logic_vector(3 downto 0);
        corriendo: out std_logic
    );
end entity timer_exceso;
 
architecture conductual of timer_exceso is
 
    type t_estado is (EN_ESPERA, EN_CERO, EN_MARCHA, DETENIDO);
    signal estado_actual : t_estado := EN_ESPERA;
 
    ---contadores bcd del tiempo adicional
    signal cnt_uni : integer range 0 to 9 := 0;
    signal cnt_dec : integer range 0 to 9 := 0;
    signal cnt_cen : integer range 0 to 9 := 0; ---hasta 999 segundos de exceso
 
begin
 
    p_exceso: process(clk_1hz)
    begin
        if rising_edge(clk_1hz) then
            if rst = '1' then
                estado_actual <= EN_ESPERA;
                cnt_uni       <= 0;
                cnt_dec       <= 0;
                cnt_cen       <= 0;
                corriendo     <= '0';
 
            else
                case estado_actual is
 
                    ---esperando señal de inicio
                    when EN_ESPERA =>
                        corriendo <= '0';
                        cnt_uni   <= 0;
                        cnt_dec   <= 0;
                        cnt_cen   <= 0;
                        if iniciar = '1' and persona = '1' then
                            estado_actual <= EN_CERO;
                        end if;
 
                    ---muestra 000 durante 1 segundo antes de contar 
                    when EN_CERO =>
                        corriendo     <= '1';
                        estado_actual <= EN_MARCHA;
 
                    ---contando tiempo de exceso 
                    when EN_MARCHA =>
                        corriendo <= '1';
 
                        --la persona finalmente abandona el espacio
                        if persona = '0' then
                            estado_actual <= DETENIDO;
 
                        --incremento bcd: unidades -> decenas -> centenas
                        else
                            if cnt_uni = 9 then
                                cnt_uni <= 0;
                                if cnt_dec = 9 then
                                    cnt_dec <= 0;
                                    if cnt_cen < 9 then
                                        cnt_cen <= cnt_cen + 1;
                                    end if;
                                else
                                    cnt_dec <= cnt_dec + 1;
                                end if;
                            else
                                cnt_uni <= cnt_uni + 1;
                            end if;
                        end if;
 
                    ---conteo detenido, resultado listo
                    when DETENIDO =>
                        corriendo <= '0';
                        ---permanece aquí hasta reset
                        if iniciar = '0' then
                            estado_actual <= EN_ESPERA;
                        end if;
 
                    when others =>
                        estado_actual <= EN_ESPERA;
	
                end case;
            end if;
        end if;
    end process p_exceso;
 
    -- salidas bcd
    uni_exc <= std_logic_vector(to_unsigned(cnt_uni, 4));
    dec_exc <= std_logic_vector(to_unsigned(cnt_dec, 4));
    cen_exc <= std_logic_vector(to_unsigned(cnt_cen, 4));
 
end architecture conductual;