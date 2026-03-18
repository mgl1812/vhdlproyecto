library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity gen_reloj is
    port(
        entrada_clk : in  std_logic;                    ---reloj principal de la FPGA
        modo_freq   : in  std_logic_vector(1 downto 0); -- selector de velocidad de salida
        salida_clk  : out std_logic                     -- reloj dividido resultante
    );
end entity gen_reloj;
 
architecture divisor of gen_reloj is
    signal ciclos      : integer := 0;        -- acumulador de ciclos del reloj principal
    signal limite      : integer := 25000000; -- ciclos necesarios para medio periodo
    signal clk_interno : std_logic := '0';    -- señal interna que oscila a la frecuencia deseada
begin
    ---selección del divisor según el modo de frecuencia elegido
    limite <= 25000000 when modo_freq = "00" else  ---frecuencia  1hz
              12500000 when modo_freq = "01" else   ---frecuencia 2hz
              6250000 when modo_freq = "10" else   ---frecuencia 4hz
              3125000;                              ---frecuencia máx 8hz
 --- genera el reloj dividido por alternancia de la señal interna
    p_dividir: process(entrada_clk)
    begin
        if rising_edge(entrada_clk) then
            if ciclos >= limite then
                ciclos      <= 0;
                clk_interno <= not clk_interno;
            else
                ciclos <= ciclos + 1;
            end if;
        end if;
    end process p_dividir;
  
    salida_clk <= clk_interno;
end architecture divisor;