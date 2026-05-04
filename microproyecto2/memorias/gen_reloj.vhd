
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

entity gen_reloj is
    port (
        entrada_clk : in  std_logic;                     -- reloj principal FPGA (50 MHz)
        modo_freq   : in  std_logic_vector(1 downto 0);  -- selector de velocidad
        salida_clk  : out std_logic                      -- reloj dividido resultante
    );
end entity gen_reloj;

architecture divisor of gen_reloj is

    signal ciclos      : integer := 0;
    signal limite      : integer := 25000000;  -- valor por defecto: 1 Hz
    signal clk_interno : std_logic := '0';

begin

    -- Selección del divisor según modo elegido
    limite <= 25000000 when modo_freq = "00" else  -- 1 Hz
              12500000 when modo_freq = "01" else  -- 2 Hz
               6250000 when modo_freq = "10" else  -- 4 Hz
               3125000;                            -- 8 Hz

    -- Genera el reloj dividido por alternancia de la señal interna
    p_dividir : process(entrada_clk)
    begin
        if rising_edge(entrada_clk) then
            if ciclos >= limite - 1 then
                ciclos      <= 0;
                clk_interno <= not clk_interno;
            else
                ciclos <= ciclos + 1;
            end if;
        end if;
    end process p_dividir;

    salida_clk <= clk_interno;

end architecture divisor;