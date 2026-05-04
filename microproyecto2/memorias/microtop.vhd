library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.mem_pkg.all;
 
entity microtop is
    port (
        entrada_clk : in  std_logic;                     -- CLOCK_50 → PIN_G21
        btn_rst     : in  std_logic;                     -- Botón de reset activo en bajo
        HEX0        : out std_logic_vector(6 downto 0);  -- display activo
        HEX1        : out std_logic_vector(6 downto 0);  -- apagado
        HEX2        : out std_logic_vector(6 downto 0);  -- apagado
        HEX3        : out std_logic_vector(6 downto 0)   -- apagado
    );
end entity microtop;
 
architecture memorias of microtop is
 
    -- rst interno: activo alto (BUTTON es activo bajo → se invierte)
    signal rst_i      : std_logic;
 
    -- Reloj dividido
    signal clk_div    : std_logic;
 
    -- Señales internas de interconexión
    signal addr_bus   : t_addr;
    signal data_out_s : t_data;
    signal we_s       : std_logic;
    signal re_s       : std_logic;
    signal rom_out_s  : t_data;
    signal ram_out_s  : t_data;
    signal reg_dato_s : t_data;
 
    -- modo_freq fijo a "00" = 1 Hz (visible en el display físico)
    constant MODO_FREQ_FIJO : std_logic_vector(1 downto 0) := "00";
 
    
    -- Declaración de componentes
    
    component gen_reloj is
        port (
            entrada_clk : in  std_logic;
            modo_freq   : in  std_logic_vector(1 downto 0);
            salida_clk  : out std_logic
        );
    end component gen_reloj;
 
    component rom is
        port (
            clk      : in  std_logic;
            re       : in  std_logic;
            addr     : in  t_addr;
            data_out : out t_data
        );
    end component rom;
 
    component ram is
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            we       : in  std_logic;
            re       : in  std_logic;
            addr     : in  t_addr;
            data_in  : in  t_data;
            data_out : out t_data
        );
    end component ram;
 
    component controlador is
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            addr     : out t_addr;
            we       : out std_logic;
            re       : out std_logic;
            reg_dato : out t_data;
            ram_out  : in  t_data;
            data_out : out t_data;
            rom_out  : in  t_data
        );
    end component controlador;
 
    component bcd_7seg is
        port (
            data_in : in  t_data;
            seg     : out std_logic_vector(6 downto 0)
        );
    end component bcd_7seg;
 
begin
 
    -- Inversión del botón: BUTTON[0] es activo bajo en DE0
    rst_i <= not btn_rst;
 
    
    -- Instancia divisor de reloj
    
    u_genreloj : gen_reloj
        port map (
            entrada_clk => entrada_clk,
            modo_freq   => MODO_FREQ_FIJO,
            salida_clk  => clk_div
        );
 
    
    -- Instancia ROM (asíncrona)
    
    u_rom : rom
        port map (
            clk      => clk_div,
            re       => re_s,
            addr     => addr_bus,
            data_out => rom_out_s
        );
 
    
    -- Instancia RAM
    
    u_ram : ram
        port map (
            clk      => clk_div,
            rst      => rst_i,
            we       => we_s,
            re       => re_s,
            addr     => addr_bus,
            data_in  => reg_dato_s,
            data_out => ram_out_s
        );
 
   
    -- Instancia Controlador (FSM)
   
    u_ctrl : controlador
        port map (
            clk      => clk_div,
            rst      => rst_i,
            addr     => addr_bus,
            we       => we_s,
            re       => re_s,
            reg_dato => reg_dato_s,
            ram_out  => ram_out_s,
            data_out => data_out_s,
            rom_out  => rom_out_s
        );
 
   
    -- Instancia decodificador BCD a HEX0
   
    u_7seg : bcd_7seg
        port map (
            data_in => data_out_s,
            seg     => HEX0
        );
 
    -- HEX1, HEX2, HEX3 apagados (activo bajo → todos en '1')
    HEX1 <= "1111111";
    HEX2 <= "1111111";
    HEX3 <= "1111111";
 
end architecture memorias;