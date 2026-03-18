library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gen_reloj is
    port(
        entrada_clk : in  std_logic;                    ---reloj principal de la FPGA
        modo_freq   : in  std_logic_vector(1 downto 0); ---selector de velocidad de salida
        salida_clk  : out std_logic                     ---reloj dividido resultante
    );
end entity gen_reloj;

architecture divisor of gen_reloj is

    signal ciclos      : integer := 0;        ---acumulador de ciclos del reloj principal
    signal limite      : integer :=25000000; ---ciclos necesarios para medio periodo
    signal clk_interno : std_logic := '0';    ---señal interna que oscila a la frecuencia deseada

begin

    ---selección del divisor según el modo de frecuencia elegido
    limite <= 25000000 when modo_freq = "00" else  ---frecuencia mínima 1 Hz
              12500000 when modo_freq = "01" else  ---frecuencia doble 2 Hz
               6250000 when modo_freq = "10" else  ---frecuencia cuádruple 4 Hz
              3125000;                             ---frecuencia 8 hz

    ---proceso del divisor: genera el reloj dividido por alternancia de la señal interna
    p_dividir: process(entrada_clk)
    begin
        if rising_edge(entrada_clk) then
            if ciclos >= limite then
                ciclos      <= 0;                    ---reinicia el acumulador
                clk_interno <= not clk_interno;      ---alterna la señal de salida
            else
                ciclos <= ciclos + 1;                ---sigue acumulando ciclos
            end if;
        end if;
    end process p_dividir;

    ---asignación del reloj dividido a la salida del módulo
    salida_clk <= clk_interno;

end architecture divisor;