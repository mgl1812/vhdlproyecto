library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.mem_pkg.all;
 
entity controlador is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;                    -- reset asíncrono activo alto
 
        -- Señales hacia ROM y RAM
        addr     : out t_addr;                       -- dirección compartida
        we       : out std_logic;                    -- write enable → RAM
        re       : out std_logic;                    -- read enable  → ROM (S1) o RAM (S3)
 
        -- dato capturado de la ROM para pasarlo a la RAM
        reg_dato : out t_data;                       -- registro interno expuesto al top
 
        -- dato leído de la RAM (viene del top)
        ram_out  : in  t_data;                       -- dato que entrega la RAM en S3
 
        -- dato final hacia el display
        data_out : out t_data;                       -- dato válido en S4
 
        -- dato de la ROM (viene del top)
        rom_out  : in  t_data                        -- dato que entrega la ROM en S1
    );
end entity controlador;
 
architecture pol of controlador is
 
    signal estado      : t_state;
    signal addr_cnt    : unsigned(ADDR_WIDTH - 1 downto 0);
    signal reg_dato_i  : t_data;
 
begin
 
    
    -- Registro interno: captura el dato de la ROM en S1
    
    process(clk, rst)
    begin
        if rst = '1' then
            reg_dato_i <= (others => '0');
        elsif rising_edge(clk) then
            if estado = S1_READ_ROM then
                reg_dato_i <= rom_out;
            end if;
        end if;
    end process;
 
    reg_dato <= reg_dato_i;
 
    -- FSM: transiciones de estado + contador de dirección
   
    process(clk, rst)
    begin
        if rst = '1' then
            estado   <= S1_READ_ROM;
            addr_cnt <= (others => '0');
 
        elsif rising_edge(clk) then
            case estado is
 
                when S1_READ_ROM =>
                    estado <= S2_WRITE_RAM;
 
                when S2_WRITE_RAM =>
                    estado <= S3_READ_RAM;
 
                when S3_READ_RAM =>
                    estado <= S4_DISPLAY;
 
                when S4_DISPLAY =>
                    -- Ciclo infinito: al terminar addr=3 vuelve a 0
                    if addr_cnt = to_unsigned(MEM_DEPTH - 1, ADDR_WIDTH) then
                        addr_cnt <= (others => '0');
                    else
                        addr_cnt <= addr_cnt + 1;
                    end if;
                    estado <= S1_READ_ROM;
 
            end case;
        end if;
    end process;
 
    
    -- Lógica de salida (Moore): señales según estado actual
    
    process(estado, addr_cnt, reg_dato_i, ram_out)
    begin
        -- Valores por defecto (evita latches)
        we       <= '0';
        re       <= '0';
        addr     <= std_logic_vector(addr_cnt);
        data_out <= (others => '0');
 
        case estado is
 
            when S1_READ_ROM =>
                re   <= '1';                          -- habilita lectura ROM
                addr <= std_logic_vector(addr_cnt);
 
            when S2_WRITE_RAM =>
                we   <= '1';                          -- habilita escritura RAM
                addr <= std_logic_vector(addr_cnt);
 
            when S3_READ_RAM =>
                re   <= '1';                          -- habilita lectura RAM
                addr <= std_logic_vector(addr_cnt);
 
            when S4_DISPLAY =>
                data_out <= ram_out;                  -- dato válido hacia 7seg
 
        end case;
    end process;
 
end architecture pol;
 