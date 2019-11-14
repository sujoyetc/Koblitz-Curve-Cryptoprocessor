----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:22:48 09/12/2014 
-- Design Name: 
-- Module Name:    ecsm_processor - structural 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library work;
use work.settings.all;

entity ecsm_processor is
	port (
		clk			: in  std_logic;
		rst			: in	std_logic;
		-- uC signals
		en_ecsm		: in  std_logic;
		done_ecsm	: out std_logic;
		-- RAM signals
		addr			: out std_logic_vector(7 downto 0);
		doutb			: in  std_logic_vector(15 downto 0);
		dina			: out std_logic_vector(15 downto 0);
		wea			: out std_logic);
end ecsm_processor;

architecture structural of ecsm_processor is

   component ecsm_fsm is
      port (
         clk            : in  std_logic;
         rst            : in  std_logic;
         -- Control signals
         en_ecsm        : in  std_logic;
         en_primitive   : out std_logic;
         done_primitive : in  std_logic;
         done_ecsm      : out std_logic;
         -- Key bit signals
			k_even			: in  std_logic;
         done_k         : in  std_logic;
         k_bits         : in  std_logic_vector(WINDOW-1 downto 0);
         k_end          : in  std_logic_vector(1 downto 0);
         -- Program ROM signals
         prog_addr      : out std_logic_vector(PROG_WIDTH-1 downto 0)      
      );
   end component ecsm_fsm;

   component program_rom is
      port (
         prog_addr   : in  std_logic_vector(PROG_WIDTH-1 downto 0);
         inst        : out std_logic_vector(INST_WIDTH-1 downto 0);
         addr_opa    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
         addr_opb    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
         addr_res    : out std_logic_vector(ADDR_WIDTH-1 downto 0)
      );
   end component program_rom;
	
	component processor is
		port (
			clk						: in  std_logic;
			rst						: in  std_logic;
			instruction_ready		: in  std_logic;
			instruction				: in  std_logic_vector(2 downto 0);
			op0						: in  std_logic_vector(3 downto 0);
			op1						: in  std_logic_vector(3 downto 0);
			op2						: in  std_logic_vector(3 downto 0);
			address					: out std_logic_vector(7 downto 0);
			doutb						: in  std_logic_vector(15 downto 0);
			dina						: out std_logic_vector(15 downto 0);
			wea						: out std_logic;
			length_even				: out std_logic;
			done_SC					: out std_logic;
			Tbit_pair				: out std_logic_vector(1 downto 0); 
			flag_adjustment		: out std_logic_vector(1 downto 0); 
			instruction_executed	: out std_logic;
         state_SC             : out std_logic_vector(5 downto 0)
			-- Test signals (remove?)
--			suspend					: out std_logic; 
--			en_primitive			: out std_logic; 
--			en_invert				: out std_logic;
--			state_SC					: out std_logic_vector(5 downto 0);
--			state_PR					: out std_logic_vector(5 downto 0);
--			length_counter			: out std_logic_vector(8 downto 0);
--			SCOffset					: out std_logic_vector(4 downto 0);
--			mode						: out std_logic_vector(1 downto 0);
--			CL							: out std_logic_vector(15 downto 0); 
--			M4_out					: out std_logic_vector(15 downto 0);
--			R2							: out std_logic_vector(15 downto 0);
--			control_group1			: out std_logic_vector(8 downto 0);
--			sel5						: out std_logic;  
--			sel3_test				: out std_logic; 
--			state_inv				: out std_logic_vector(2 downto 0);
--			inv_rom_dout			: out std_logic_vector(7 downto 0);
--			count						: out std_logic_vector(7 downto 0);
--			BasePtSel				: out std_logic_vector(3 downto 0)
		);
	end component processor;

	signal prog_addr 			: std_logic_vector(PROG_WIDTH-1 downto 0);

	signal inst					: std_logic_vector(INST_WIDTH-1 downto 0);
	signal addr_opa			: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal addr_opb			: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal addr_res			: std_logic_vector(ADDR_WIDTH-1 downto 0);

	signal en_primitive		: std_logic;
	signal done_primitive	: std_logic;
	
	signal done_k				: std_logic;
	signal k_even				: std_logic;
	signal k_bits				: std_logic_vector(WINDOW-1 downto 0);
	signal k_end				: std_logic_vector(1 downto 0);

   signal state_SC         : std_logic_vector(5 downto 0);

begin

   i_ecsm_fsm : ecsm_fsm
      port map (clk,rst,en_ecsm,en_primitive,done_primitive,done_ecsm,k_even,done_k,k_bits,k_end,prog_addr);

   i_program_rom : program_rom
      port map (prog_addr,inst,addr_opa,addr_opb,addr_res);
		
	i_processor : processor
		port map (clk,rst,en_primitive,inst,addr_res,addr_opa,addr_opb,addr,doutb,dina,wea,k_even,done_k,k_bits,k_end,done_primitive, state_SC);

end structural;

