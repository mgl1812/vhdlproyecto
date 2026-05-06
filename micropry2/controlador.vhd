library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_pkg.all;

-- Controlador principal del proceso
entity controlador is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        hold         : in  std_logic;
        addr         : out t_addr;
        we           : out std_logic;
        re           : out std_logic;
        reg_dato     : out t_data;
        ram_out      : in  t_data;
        data_out     : out t_data;
        rom_out      : in  t_data;
        addr_captura : out t_addr;
        actualizar   : out std_logic
    );
end entity controlador;

architecture pol of controlador is
    -- Estado actual de la máquina
    signal estado     : t_state;

    -- Contador de direcciones
    signal addr_cnt   : unsigned(ADDR_WIDTH - 1 downto 0);

    -- Registro interno para guardar dato leído de ROM
    signal reg_dato_i : t_data;
begin

    -- Captura el dato de ROM en el momento indicado
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

    -- Salidas directas del registro y del contador
    reg_dato     <= reg_dato_i;
    addr_captura <= std_logic_vector(addr_cnt);

    -- Secuencia de estados
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
                    -- Avanza solo si no hay espera
                    if hold = '0' then
                        if addr_cnt = to_unsigned(MEM_DEPTH - 1, ADDR_WIDTH) then
                            addr_cnt <= (others => '0');
                        else
                            addr_cnt <= addr_cnt + 1;
                        end if;
                        estado <= S1_READ_ROM;
                    end if;
            end case;
        end if;
    end process;

    -- Lógica combinacional de control
    process(estado, addr_cnt, reg_dato_i, ram_out)
    begin
        we         <= '0';
        re         <= '0';
        addr       <= std_logic_vector(addr_cnt);
        data_out   <= (others => '0');
        actualizar <= '0';

        case estado is
            when S1_READ_ROM =>
                -- Lectura desde ROM
                re <= '1';

            when S2_WRITE_RAM =>
                -- Escritura en RAM
                we <= '1';

            when S3_READ_RAM =>
                -- Lectura desde RAM
                re <= '1';

            when S4_DISPLAY =>
                -- Enviar dato a la salida
                data_out <= ram_out;

                -- Señal para actualizar display
                if to_integer(addr_cnt) mod 3 = 2 then
                    actualizar <= '1';
                end if;
        end case;
    end process;

end architecture pol;