----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:38:04 02/20/2008 
-- Design Name: 
-- Module Name:    vga_timing_decode - Behavioral 
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
USE ieee.numeric_std.ALL;

ENTITY vga_timing_decode IS
  GENERIC (
    HEIGHT      : integer := 480;
    WIDTH       : integer := 640;
    H_BP        : integer := 117;
    V_BP        : integer := 34;
    HEIGHT_BITS : integer := 10;
    WIDTH_BITS  : integer := 10;
    DATA_DELAY  : integer := 0
    );
  PORT (CLK         : IN  std_logic;
        RST         : IN  std_logic;
        VSYNC       : IN  std_logic;
        HSYNC       : IN  std_logic;
        X_COORD     : OUT std_logic_vector (WIDTH_BITS-1 DOWNTO 0);
        Y_COORD     : OUT std_logic_vector(HEIGHT_BITS-1 DOWNTO 0);
        PIXEL_COUNT : OUT std_logic_vector(HEIGHT_BITS+WIDTH_BITS-1 DOWNTO 0);
        DATA_VALID  : OUT std_logic);
END vga_timing_decode;

ARCHITECTURE Behavioral OF vga_timing_decode IS
  SIGNAL hcount_reg      : unsigned(WIDTH_BITS-1 DOWNTO 0)             := (OTHERS => '0');
  SIGNAL vcount_reg      : unsigned(HEIGHT_BITS-1 DOWNTO 0)            := (OTHERS => '0');
  SIGNAL pixel_count_reg : unsigned(HEIGHT_BITS+WIDTH_BITS-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL x_coord_reg     : unsigned(WIDTH_BITS-1 DOWNTO 0)             := (OTHERS => '0');
  SIGNAL y_coord_reg     : unsigned(HEIGHT_BITS-1 DOWNTO 0)            := (OTHERS => '0');
  SIGNAL prev_hsync      : std_logic                                   := '0';
  SIGNAL data_valid_reg  : std_logic                                   := '0';
BEGIN
  X_COORD     <= std_logic_vector(x_coord_reg);
  Y_COORD     <= std_logic_vector(y_coord_reg);
  PIXEL_COUNT <= std_logic_vector(pixel_count_reg);
  DATA_VALID  <= data_valid_reg;

  PROCESS (CLK) IS
  BEGIN  -- PROCESS 
    IF CLK'event AND CLK = '1' THEN
      IF RST = '1' THEN
        hcount_reg      <= (OTHERS => '0');
        vcount_reg      <= (OTHERS => '0');
        pixel_count_reg <= (OTHERS => '0');
        x_coord_reg     <= (OTHERS => '0');
        y_coord_reg     <= (OTHERS => '0');
        prev_hsync      <= '0';
        data_valid_reg  <= '0';
      ELSE
        prev_hsync <= HSYNC;
 
        -- The backporch -1 is due to the register delay
        IF HSYNC = '0' AND VSYNC = '0' AND hcount_reg >= H_BP-DATA_DELAY-1 AND hcount_reg < H_BP+WIDTH-DATA_DELAY-1 AND vcount_reg >= V_BP AND vcount_reg < V_BP+HEIGHT THEN
          data_valid_reg <= '1';
          IF data_valid_reg = '1' THEN  -- This makes the first valid pixel 0,
                                        -- instead of 1
            x_coord_reg <= x_coord_reg + 1;
          END IF;

          -- This makes the first valid pixel 0, and properly increments the
          -- first pixels of every other line
          IF (data_valid_reg = '1' AND vcount_reg = V_BP) OR vcount_reg > V_BP THEN
            pixel_count_reg <= pixel_count_reg + 1;
          END IF;
        ELSE
          data_valid_reg <= '0';
          x_coord_reg    <= (OTHERS => '0');
        END IF;

        IF VSYNC = '0' THEN
          IF HSYNC = '1' AND prev_hsync = '0' AND vcount_reg >= V_BP AND vcount_reg < V_BP+HEIGHT-1 THEN
            y_coord_reg <= y_coord_reg + 1;
          END IF;
        ELSE
          vcount_reg      <= (OTHERS => '0');
          pixel_count_reg <= (OTHERS => '0');
          y_coord_reg     <= (OTHERS => '0');
        END IF;

        IF HSYNC = '0' THEN
          hcount_reg <= hcount_reg + 1;
        ELSE
          hcount_reg <= (OTHERS => '0');
          IF prev_hsync = '0' THEN
            vcount_reg <= vcount_reg + 1;
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;
END Behavioral;

