library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.settings.all;

entity program_rom is
   port (
      prog_addr   : in  std_logic_vector(PROG_WIDTH-1 downto 0);
      inst        : out std_logic_vector(INST_WIDTH-1 downto 0);
      addr_opa    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      addr_opb    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      addr_res    : out std_logic_vector(ADDR_WIDTH-1 downto 0)
   );
end program_rom;

architecture rtl of program_rom is

begin

   process (prog_addr)
   begin

      inst     <= PROGRAM(to_integer(unsigned(prog_addr))).inst;
      addr_opa <= PROGRAM(to_integer(unsigned(prog_addr))).addr_opa;
      addr_opb <= PROGRAM(to_integer(unsigned(prog_addr))).addr_opb;
      addr_res <= PROGRAM(to_integer(unsigned(prog_addr))).addr_res;

   end process;

end rtl;
