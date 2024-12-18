library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A VHDL file for the terasIC DE10-Lite Intel Uni FPGA!
-- Specifically setup for the Intel MAX 10 10M50DAF484C7G
-- Written by Preston Parsons 11/17/2024
-- This is designed to take the raw signals from VGA
-- at 640x350 60Hz and convert it to EGA at 640x350 60HZ
-- This is accomplished using the built in
-- analog to digital convertor on the FPGA
-- and the color signals are torn apart and 
-- new signals made for the digital EGA!

entity vga is
    port (
        -- VGA Inputs
        VGA_HSYNC, VGA_VSYNC : in std_logic; -- VGA sync signals
        CLK_25MHZ : in std_logic;            -- VGA pixel clock

        -- EGA Outputs
        EGA_R, EGA_G, EGA_B : out std_logic; -- Digital RGB
        EGA_r1, EGA_g1, EGA_b1 : out std_logic; -- Intensity RGB
        EGA_HSYNC, EGA_VSYNC : out std_logic -- Sync outputs
    );
end vga;

architecture Behavioral of vga is
    -- Component Declaration for adc2
    component adc2 is
        port (
            clock_clk              : in  std_logic;                     -- clock input
            reset_sink_reset_n     : in  std_logic;                     -- reset input
            adc_pll_clock_clk      : in  std_logic;                     -- PLL clock input
            adc_pll_locked_export  : in  std_logic;                     -- PLL lock input
            command_valid          : in  std_logic;                     -- command valid signal
            command_channel        : in  std_logic_vector(4 downto 0);  -- command channel
            command_startofpacket  : in  std_logic;                     -- start of packet signal
            command_endofpacket    : in  std_logic;                     -- end of packet signal
            command_ready          : out std_logic;                     -- command ready signal
            response_valid         : out std_logic;                     -- response valid signal
            response_channel       : out std_logic_vector(4 downto 0);  -- response channel
            response_data          : out std_logic_vector(11 downto 0); -- response data
            response_startofpacket : out std_logic;                     -- response start of packet signal
            response_endofpacket   : out std_logic                      -- response end of packet signal
        );
    end component;

    -- Internal signals for RGB and sync
    signal vga_r_4bit, vga_g_4bit, vga_b_4bit : std_logic_vector(3 downto 0); -- 4-bit processed signals
    signal ega_r_internal, ega_g_internal, ega_b_internal : std_logic;
    signal ega_r_intensity, ega_g_intensity, ega_b_intensity : std_logic;
    signal ega_hsync_internal, ega_vsync_internal : std_logic := '0';
    signal intensity_bit : std_logic;

    -- Internal counters to divide the VGA sync signals for EGA
    signal hsync_counter, vsync_counter : integer := 0;
    constant hsync_total : integer := 1144; -- Total horizontal clock cycles (VGA)
    constant vsync_total : integer := 416750; -- Total vertical clock cycles (VGA)

    constant hsync_divider : integer := 1152; -- Divide factor for EGA horizontal frequency
    constant vsync_divider : integer := 1125; -- Divide factor for EGA vertical frequency

    -- Signals for adc2 component
    signal command_valid : std_logic := '0';
    signal command_channel : std_logic_vector(4 downto 0) := (others => '0');
    signal command_startofpacket : std_logic := '0';
    signal command_endofpacket : std_logic := '0';
    signal command_ready : std_logic;
    signal response_valid : std_logic;
    signal response_channel : std_logic_vector(4 downto 0);
    signal response_data : std_logic_vector(11 downto 0);
    signal response_startofpacket : std_logic;
    signal response_endofpacket : std_logic;

begin
    -- Instantiating the adc2 IP core
    adc2_inst : adc2
        port map (
            clock_clk              => CLK_25MHZ,                -- Use the 25MHz clock for the IP
            reset_sink_reset_n     => '1',                      -- Constant reset signal
            adc_pll_clock_clk      => CLK_25MHZ,                -- Same clock for ADC PLL
            adc_pll_locked_export  => '1',                      -- PLL lock assumed
            command_valid          => command_valid,            -- Command valid signal
            command_channel        => command_channel,          -- Command channel
            command_startofpacket  => command_startofpacket,    -- Start of packet
            command_endofpacket    => command_endofpacket,      -- End of packet
            command_ready          => command_ready,            -- Ready signal
            response_valid         => response_valid,           -- Response valid
            response_channel       => response_channel,         -- Response channel
            response_data          => response_data,            -- 12-bit response data
            response_startofpacket => response_startofpacket,   -- Response start of packet
            response_endofpacket   => response_endofpacket      -- Response end of packet
        );

    -- Convert 12-bit ADC outputs to 4-bit values
    vga_r_4bit <= response_data(11 downto 8);  -- VGA red
    vga_g_4bit <= response_data(7 downto 4);   -- VGA green
    vga_b_4bit <= response_data(3 downto 0);   -- VGA blue

    -- Map VGA RGB to EGA RGB with intensity
    ega_r_internal <= vga_r_4bit(3); 
    ega_g_internal <= vga_g_4bit(3); 
    ega_b_internal <= vga_b_4bit(3); 

    intensity_bit <= vga_r_4bit(2) or vga_g_4bit(2) or vga_b_4bit(2);
    ega_r_intensity <= intensity_bit and vga_r_4bit(3);
    ega_g_intensity <= intensity_bit and vga_g_4bit(3);
    ega_b_intensity <= intensity_bit and vga_b_4bit(3);

    -- Assign internal signals to output ports
    EGA_R <= ega_r_internal;
    EGA_G <= ega_g_internal;
    EGA_B <= ega_b_internal;
    EGA_r1 <= ega_r_intensity;
    EGA_g1 <= ega_g_intensity;
    EGA_b1 <= ega_b_intensity;

    -- Horizontal Sync Process
    process(CLK_25MHZ)
    begin
        if (rising_edge(CLK_25MHZ)) then 
            hsync_counter <= hsync_counter + 1;

            if (hsync_counter < hsync_divider) then
                ega_hsync_internal <= response_startofpacket;
            else
                ega_hsync_internal <= not response_startofpacket;
            end if;

            if (hsync_counter >= hsync_total) then
                hsync_counter <= 0;
            end if;
        end if;
    end process;
    EGA_HSYNC <= ega_hsync_internal;

    -- Vertical Sync Process
    process(CLK_25MHZ)
    begin
        if rising_edge(CLK_25MHZ) then
            vsync_counter <= vsync_counter + 1;

            if (vsync_counter < vsync_divider) then
                ega_vsync_internal <= response_endofpacket;
            else
                ega_vsync_internal <= not response_endofpacket;
            end if;

            if vsync_counter >= vsync_total then
                vsync_counter <= 0;
            end if;
        end if;
    end process;
    EGA_VSYNC <= ega_vsync_internal;

end Behavioral;
