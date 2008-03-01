----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:23:27 09/19/2007 
-- Design Name: 
-- Module Name:    vga_timing_generator - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY vga_timing_generator IS
  GENERIC (H_ACTIVE      : std_logic_vector(10 DOWNTO 0) := "10000000000";  --  1024
           H_FRONT_PORCH : std_logic_vector(10 DOWNTO 0) := "00000011000";  -- 24
           H_SYNC        : std_logic_vector(10 DOWNTO 0) := "00010001000";  -- 136
           H_BACK_PORCH  : std_logic_vector(10 DOWNTO 0) := "00010100000";  -- 160
          
           V_ACTIVE      : std_logic_vector(10 DOWNTO 0) := "01100000000";  -- 768
           V_FRONT_PORCH : std_logic_vector(10 DOWNTO 0) := "00000000011";  -- 3
           V_SYNC        : std_logic_vector(10 DOWNTO 0) := "00000000110";  -- 6
           V_BACK_PORCH  : std_logic_vector(10 DOWNTO 0) := "00000011101"  -- 29
           );
  PORT (PIXEL_CLOCK : IN  std_logic;
        RESET       : IN  std_logic;
        CLKEN       : IN  std_logic;
        H_SYNC_Z    : OUT std_logic;
        V_SYNC_Z    : OUT std_logic;
        DATA_VALID  : OUT std_logic;
        PIXEL_COUNT : OUT std_logic_vector(10 DOWNTO 0);
        LINE_COUNT  : OUT std_logic_vector(10 DOWNTO 0);
        TOTAL_PIXEL_COUNT : OUT std_logic_vector(21 DOWNTO 0));
END vga_timing_generator;

ARCHITECTURE Behavioral OF vga_timing_generator IS
  SIGNAL pixel_count_reg      : std_logic_vector(10 DOWNTO 0) := (OTHERS => '0');
  SIGNAL line_count_reg       : std_logic_vector(10 DOWNTO 0) := (OTHERS => '0');
  SIGNAL vsync_reg, hsync_reg : std_logic                     := '0';  -- NOTE These are active high signals
  SIGNAL total_pixel_count_reg : std_logic_vector(21 DOWNTO 0) := (OTHERS => '0');  -- This is used to keep track of the number of valid pixels that have been output this frame.  Used to allow pixel selection to be made based on 1D memory addresses.
BEGIN
  
  PIXEL_COUNT <= pixel_count_reg;
  LINE_COUNT  <= line_count_reg;
  TOTAL_PIXEL_COUNT <= total_pixel_count_reg;
  H_SYNC_Z    <= NOT hsync_reg;
  V_SYNC_Z    <= NOT vsync_reg;
  
  PROCESS(PIXEL_CLOCK)
  BEGIN
    -- Horizontal Pixel Count
    IF (PIXEL_CLOCK'event AND PIXEL_CLOCK = '1') THEN
      IF (RESET = '1') THEN
        line_count_reg  <= (OTHERS => '0');
        pixel_count_reg <= (OTHERS => '0');
        hsync_reg       <= '0';
        vsync_reg       <= '0';
        total_pixel_count_reg <= (OTHERS => '0');
      ELSE
        -- Data valid signal
        IF (pixel_count_reg < H_ACTIVE AND line_count_reg < V_ACTIVE) THEN
          DATA_VALID <= '1';
          total_pixel_count_reg <= total_pixel_count_reg + 1;
        ELSE
          DATA_VALID <= '0';
        END IF;
        
        IF CLKEN = '1' THEN
          -- Horizontal Line Counter
          IF (pixel_count_reg = (H_ACTIVE+H_FRONT_PORCH+H_SYNC+H_BACK_PORCH-1)) THEN
            pixel_count_reg <= (OTHERS => '0');
          ELSE
            pixel_count_reg <= pixel_count_reg + 1;
          END IF;

          -- Vertical Line Counter
          IF (pixel_count_reg = (H_ACTIVE+H_FRONT_PORCH+H_SYNC+H_BACK_PORCH - 1) AND (line_count_reg = (V_ACTIVE+V_FRONT_PORCH+V_SYNC+V_BACK_PORCH - 1))) THEN
            line_count_reg <= (OTHERS => '0');
            total_pixel_count_reg <= (OTHERS => '0');
          ELSIF (pixel_count_reg = (H_ACTIVE+H_FRONT_PORCH+H_SYNC+H_BACK_PORCH - 1)) THEN
            line_count_reg <= line_count_reg + 1;
          END IF;
        END IF;

        -- Vertical Sync Pulse
        IF (pixel_count_reg = (H_ACTIVE+H_FRONT_PORCH+H_SYNC+H_BACK_PORCH - 1) AND line_count_reg = (V_ACTIVE + V_FRONT_PORCH -1)) THEN
          vsync_reg <= '1';
        ELSIF (pixel_count_reg = (H_ACTIVE+H_FRONT_PORCH+H_SYNC+H_BACK_PORCH - 1) AND line_count_reg = (V_ACTIVE+V_FRONT_PORCH+V_SYNC-1)) THEN
          vsync_reg <= '0';
        END IF;

        -- Horizontal Sync Pulse
        IF (pixel_count_reg = (H_ACTIVE + H_FRONT_PORCH - 1)) THEN
          hsync_reg <= '1';
        ELSIF (pixel_count_reg = (H_ACTIVE+H_FRONT_PORCH+H_SYNC - 1)) THEN
          hsync_reg <= '0';
        END IF;
      END IF;
    END IF;
  END PROCESS;
END Behavioral;
