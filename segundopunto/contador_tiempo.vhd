library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity contador_tiempo is
    port(
        pulso  : in  std_logic;                     ---señal de reloj que avanza el conteo
        reset  : in  std_logic;                     ---señal activa en bajo para reiniciar
        uni    : out std_logic_vector(3 downto 0);  ---bcd de unidades de segundo
        dec    : out std_logic_vector(3 downto 0);  ---bcd de decenas de segundo
        min    : out std_logic_vector(3 downto 0)   ---bcd de minutos
    );
end entity contador_tiempo;

architecture behavioral of contador_tiempo is

    ---registros internos del conteo
    signal reg_uni : integer range 0 to 9 := 0; ---unidades de segundo (0 a 9)
    signal reg_dec : integer range 0 to 5 := 0; ---decenas de segundo (0 a 5)
    signal reg_min : integer range 0 to 9 := 0; ---minutos (0 a 9)

begin

    ---proceso de conteo: avanza en cada flanco ascendente o reinicia si reset activo
    p_conteo: process(pulso, reset)
    begin
        if reset = '0' then
            ---reinicio sincrónico de todos los registros
            reg_uni <= 0;
            reg_dec <= 0;
            reg_min <= 0;

        elsif rising_edge(pulso) then
            ---avance de unidades de segundo
            if reg_uni = 9 then
                reg_uni <= 0;

                --avance de decenas de segundo al llegar a 9 unidades
                if reg_dec = 5 then
                    reg_dec <= 0;

                    ---avance de minutos al completar 60 segundos
                    if reg_min = 9 then
                        reg_min <= 0;
                    else
                        reg_min <= reg_min + 1;
                    end if;

                else
                    reg_dec <= reg_dec + 1;
                end if;

            else
                reg_uni <= reg_uni + 1;
            end if;
        end if;
    end process p_conteo;

    ---salidas convertidas a bcd
    uni <= std_logic_vector(to_unsigned(reg_uni, 4));
    dec <= std_logic_vector(to_unsigned(reg_dec, 4));
    min <= std_logic_vector(to_unsigned(reg_min, 4));

end architecture behavioral;
