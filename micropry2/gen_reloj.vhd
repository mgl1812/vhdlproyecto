library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.mem_pkg.all;
 
-- Generador de reloj con divisor variable
entity gen_reloj is
    port (
        entrada_clk : in  std_logic;                      -- Reloj base
        modo_freq   : in  std_logic_vector(1 downto 0);   -- Selección de frecuencia
        salida_clk  : out std_logic                       -- Reloj dividido
    );
end entity gen_reloj;
 
architecture divisor of gen_reloj is
 
    -- Contador de ciclos
    signal ciclos      : integer := 0;

    -- Límite según frecuencia seleccionada
    signal limite      : integer := 2083333;

    -- Señal interna del reloj dividido
    signal clk_interno : std_logic := '0';
 
begin
 
    -- Selección del valor límite según modo
    limite <= 2083333 when modo_freq = "00" else
              1041666 when modo_freq = "01" else
              4166666 when modo_freq = "10" else
               100000;
 
    -- Proceso divisor de frecuencia
    p_dividir : process(entrada_clk)
    begin
        if rising_edge(entrada_clk) then
            -- Cuando llega al límite, reinicia y conmuta
            if ciclos >= limite - 1 then
                ciclos      <= 0;
                clk_interno <= not clk_interno;
            else
                -- Incrementa contador
                ciclos <= ciclos + 1;
            end if;
        end if;
    end process p_dividir;
 
    -- Salida del reloj dividido
    salida_clk <= clk_interno;
 
end architecture divisor;