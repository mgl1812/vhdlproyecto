library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity contador_tiempo is
    port(
        pulso  : in  std_logic;                    ---señal de reloj que avanza el conteo
        reset  : in  std_logic;                    ---señal activa en bajo para reiniciar
        uni    : out std_logic_vector(3 downto 0); ---bcd de unidades de segundo (0 a 9)
        dec    : out std_logic_vector(3 downto 0); ---bcd de decenas de segundo (0 a 5)
        min    : out std_logic_vector(3 downto 0)  ---bcd de minutos (0 a 9)
    );
end entity contador_tiempo;
 
architecture mon of contador_tiempo is
 
    --- registros internos que almacenan el conteo actual
    signal reg_uni : integer range 0 to 9 := 0; ---unidades de segundo (0 a 9)
    signal reg_dec : integer range 0 to 5 := 0; ---decenas de segundo (0 a 5)
    signal reg_min : integer range 0 to 9 := 0; ---minutos (0 a 9)
 
begin
 
    ---proceso de conteo: avanza en cada flanco ascendente o reinicia si reset activo
    p_conteo: process(pulso, reset)
    begin
        if reset = '0' then                ---si reset está en bajo (activo):
            reg_uni <= 0;                  ---reinicia las unidades a 0
            reg_dec <= 0;                  ---reinicia las decenas a 0
            reg_min <= 0;                  ---reinicia los minutos a 0
 
        elsif rising_edge(pulso) then      ---en cada flanco de subida del pulso:
 
            if reg_uni = 9 then            ---si las unidades llegaron a 9:
                reg_uni <= 0;              ---reinicia unidades a 0
 
                if reg_dec = 5 then        --- si las decenas llegaron a 5 (60 segundos):
                    reg_dec <= 0;          ---reinicia decenas a 0
 
                    if reg_min = 9 then    ---si los minutos llegaron a 9:
                        reg_min <= 0;      ---reinicia minutos a 0 (vuelve al inicio)
                    else
                        reg_min <= reg_min + 1; ---suma un minuto
                    end if;
 
                else
                    reg_dec <= reg_dec + 1; ---suma una decena de segundo
                end if;
 
            else
                reg_uni <= reg_uni + 1;    ---suma una unidad de segundo
            end if;
 
        end if;
    end process p_conteo;
 
    --- salidas: convierte los enteros internos a vectores bcd de 4 bits
    uni <= std_logic_vector(to_unsigned(reg_uni, 4)); --- unidades hacia el display
    dec <= std_logic_vector(to_unsigned(reg_dec, 4)); --- decenas hacia el display
    min <= std_logic_vector(to_unsigned(reg_min, 4)); --- minutos hacia el display
 
end architecture mon;