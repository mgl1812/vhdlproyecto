library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

entity ram is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;   -- reset asíncrono activo alto
        we       : in  std_logic;   -- write enable (activo en S2)
        re       : in  std_logic;   -- read enable  (activo en S3)
        addr     : in  t_addr;      -- dirección (0 a 3), misma que ROM
        data_in  : in  t_data;      -- dato a escribir (= reg_dato del controlador)
        data_out : out t_data       -- dato leído → hacia S4 → display
    );
end entity ram;

architecture silla of ram is

    -- Arreglo interno: 4 posiciones de 8 bits, inicializado en 0
    type t_ram_array is array (0 to MEM_DEPTH - 1) of t_data;
    signal mem : t_ram_array := (others => (others => '0'));

begin

    
    -- Escritura síncrona con reset asíncrono
    -- Se ejecuta en S2 cuando we=1
    
    p_write : process(clk, rst)
    begin
        if rst = '1' then
            mem <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if we = '1' then
                mem(to_integer(unsigned(addr))) <= data_in;
            end if;
        end if;
    end process p_write;

    
    -- Lectura síncrona
    -- Se ejecuta en S3 cuando re=1
    -- Un ciclo después de la escritura → dato estable garantizado
    
    p_read : process(clk)
    begin
        if rising_edge(clk) then
            if re = '1' then
                data_out <= mem(to_integer(unsigned(addr)));
            end if;
        end if;
    end process p_read;

end architecture silla;
