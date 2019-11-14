library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package settings is

   -- Word length, window size and field size
   constant W        : integer := 16;
   constant WINDOW   : integer := 2;
   constant M        : integer := 283;

   -- RAM addresses
   constant ADDR_WIDTH : integer := 4;
   constant QX : std_logic_vector := x"A";
   constant QY : std_logic_vector := x"B";
   constant QZ : std_logic_vector := x"C";
   constant PX : std_logic_vector := x"3";
   constant PY : std_logic_vector := x"4";
   constant PN : std_logic_vector := x"5";
   constant T1 : std_logic_vector := x"1";
   constant T2 : std_logic_vector := x"2";
   constant XP : std_logic_vector := x"6";
   constant XM : std_logic_vector := x"7";
   constant YP : std_logic_vector := x"8";
   constant YM : std_logic_vector := x"9";
   constant K  : std_logic_vector := x"0";
 
   -- Instructions
   constant INST_WIDTH : integer := 3;
   constant NOP   : std_logic_vector := "000";  -- NOP
   constant ADD   : std_logic_vector := "001";  -- Finite field addition
   constant MLT   : std_logic_vector := "010";  -- Finite field multiplication
   constant SQR   : std_logic_vector := "011";  -- Finite field squaring
   constant INV   : std_logic_vector := "100";  -- Finite field inversion
   constant CPY   : std_logic_vector := "101";  -- Copy from one RAM address to another
   constant TNAF  : std_logic_vector := "111";  -- Request new bits of the scalar

   -- Point ROM address width
   constant ROM_LENGTH : integer := (2**(WINDOW-1)+1)*2*integer(ceil(real(M)/real(W)));
   constant ROM_WIDTH : integer := integer(ceil(log2(real(ROM_LENGTH))));

   -- Constants
   --constant K_CNTR_WIDTH : integer := integer(ceil(log2(real(K_LENGTH))));
   constant Z     : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');

   -- Program type declarations
   type program_line is 
      record
         inst     : std_logic_vector(INST_WIDTH-1 downto 0);
         addr_res : std_logic_vector(ADDR_WIDTH-1 downto 0);
         addr_opa : std_logic_vector(ADDR_WIDTH-1 downto 0);
         addr_opb : std_logic_vector(ADDR_WIDTH-1 downto 0);
      end record;
   type program_type is array (natural range <>) of program_line;

   -- The program (only for WINDOW = 2 and curves for which a2=0, e.g., K-283)
   constant PROGRAM : program_type := (
      -- Get new scalar bits
      (TNAF,"0011","0000","0001"),
      -- Precomputation
      (SQR,XP,QX,Z),
      (SQR,YP,QY,Z),
      (ADD,XP,QX,XP),
      (INV,XM,XP,Z),
      (ADD,T1,QY,YP),
      (MLT,YM,T1,XM),   -- Lambda_1
      (SQR,T1,YM,Z),    -- Lambda_1^2
      (ADD,T1,T1,YM),
      --(ADD,XP,XP,A2),   -- Flip the lsb. Compute if a2=1; remove if a2=0
      (ADD,XP,XP,T1),   -- XP
      (ADD,T1,XP,QX),
      (MLT,YP,YM,T1),
      (ADD,YP,YP,XP),
      (ADD,YP,YP,QY),   -- YP
      (MLT,XM,XM,QX),   -- Delta
      (ADD,YM,YM,XM),   -- Lambda_2 = Lambda_1 + Delta
      (SQR,T1,XM,Z),    -- Delta^2
      (ADD,XM,XM,T1),
      (ADD,XM,XM,XP),   -- XM
      (ADD,T1,XM,QX),
      (MLT,YM,YM,T1),
      (ADD,YM,YM,XM),
      (ADD,YM,YM,QY),
      (ADD,YM,YM,QX),   -- YM
      -- Flip the sign of the base point
      (ADD,QY,QX,QY),
      -- Dummy flip
      (ADD,T1,QX,QY),
      -- Base point randomization
      (MLT,QX,QX,QZ),
      (SQR,T1,QZ,Z),
      (MLT,QY,QY,T1),
      -- Two Frobenius maps
      (SQR,QY,QY,Z),
      (SQR,QY,QY,Z),
      (SQR,QX,QX,Z),
      (SQR,QX,QX,Z),
      (SQR,QZ,QZ,Z),
      (SQR,QZ,QZ,Z),
      -- Addition, initialization (point tauP + P):
      (CPY,PX,XP,Z),     -- Write x coordinate of the point
      (CPY,PY,YP,Z),     -- Write y coordinate of the point
      (ADD,PN,XP,YP),    -- Compute the y coordinate of -P
      -- Addition, initialization (point tauP - P):
      (CPY,PX,XM,Z),     -- Write x coordinate of the point
      (CPY,PY,YM,Z),     -- Write y coordinate of the point
      (ADD,PN,XM,YM),    -- Compute the y coordinate of -P
      -- Subtraction, initialization (point tauP + P):
      (CPY,PX,XP,Z),     -- Write x coordinate of the point
      (CPY,PN,YP,Z),     -- Write y coordinate of the point as the y coordinate of -P
      (ADD,PY,XP,YP),    -- Compute the y coordinate of P
      -- Subtraction, initialization (point tauP - P):
      (CPY,PX,XM,Z),     -- Write x coordinate of the point
      (CPY,PN,YM,Z),     -- Write y coordinate of the point as the y coordinate of -P
      (ADD,PY,XM,YM),    -- Compute the y coordinate of P
      -- Addition/subtraction, the common part
      (SQR,T1,QZ,Z),
      (MLT,T1,T1,PY),
      (ADD,T1,T1,QY),
      (MLT,T2,QZ,PX),
      (ADD,T2,T2,QX),
      (SQR,QX,T2,Z),
      (ADD,QX,QX,T1),
      (MLT,T2,T2,QZ),
      --(ADD,QX,QX,T2),
      (MLT,QX,QX,T2),
      (MLT,QY,T1,T2),
      (SQR,T1,T1,Z),
      (ADD,QX,QX,T1),
      (SQR,QZ,T2,Z),
      (MLT,T2,PX,QZ),
      (ADD,T2,T2,QX),
      (ADD,QY,QY,QZ),
      (MLT,QY,QY,T2),
      (SQR,T1,QZ,Z),
      (MLT,T1,T1,PN),
      (ADD,QY,QY,T1),
      -- Recover affine coordinates
      (CPY,XP,QZ,Z),
      (INV,XM,XP,Z),
      (MLT,QX,QX,XM),
      (SQR,XM,XM,Z),
      (MLT,QY,QY,XM),
      -- Change base point to tauP + P (real)
      (CPY,QX,XP,Z),
      (CPY,QY,YP,Z),
      -- Change base point to tauP - P (real)
      (CPY,QX,XM,Z),
      (CPY,QY,YM,Z),
      -- Change base point (dummy)
      (CPY,T1,XP,Z),
      (CPY,T2,YP,Z)
   );

   -- A generic program (NOT COMPLETE!!!)
--   constant PROGRAM : program_type := (
--      -- Idle
--      (NOP,Z,Z,Z),
--      -- Frobenius map
--      (SQR,QY,QY,Z),
--      (SQR,QX,QX,Z),
--      (SQR,QZ,QZ,Z),
--      -- Addition, initialization:
--      (RDROM,PX,Z,Z),      -- Write x coordinate of a point from ROM
--      (RDROM,PY,Z,Z),      -- Write y coordinate of a point from ROM
--      (ADD,PN,PX,PY),     -- Compute the y coordinate of -P
--      -- Subtraction, initialization:
--      (RDROM,PX,Z,Z),      -- Write x coordinate of a point from ROM
--      (RDROM,PN,Z,Z),     -- Write y coordinate of a point from ROM as the y coordinate of -P
--      (ADD,PY,PX,PY),      -- Compute the y coordinate of P
--      -- Addition/subtraction, the common part
--      (SQR,T1,QZ,Z),
--      (MLT,T1,T1,PY),
--      (ADD,T1,T1,QY),
--      (MLT,T2,QZ,PX),
--      (ADD,T2,T2,QX),
--      (SQR,QX,T2,Z),
--      (ADD,QX,QX,T1),
--      (MLT,T2,T2,QZ),
--      (ADD,QX,QX,T2),
--      (MLT,QX,QX,T2),
--      (MLT,QY,T1,T2),
--      (SQR,T1,T1,Z),
--      (ADD,QX,QX,T1),
--      (SQR,QZ,T2,Z),
--      (MLT,T2,PX,QZ),
--      (ADD,T2,T2,QX),
--      (ADD,QY,QY,QZ),
--      (MLT,QY,QY,T2),
--      (SQR,T1,QZ,Z),
--      (MLT,T1,T1,PN),
--      (ADD,QY,QY,T1),
--      -- Recover affine coordinates
--      (INV,QZ,QZ,Z),
--      (MLT,QX,QX,QZ),
--      (SQR,QZ,QZ,Z),
--      (MLT,QY,QY,QZ)
--   );

   constant PROG_WIDTH : integer := integer(ceil(log2(real(PROGRAM'length))));

   -- Pointers
   constant PNTR_GET_K           : std_logic_vector(PROG_WIDTH-1 downto 0) := (others => '0');
   constant PNTR_PRECOMP_B       : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1,PROG_WIDTH));
   constant PNTR_PRECOMP_E       : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(23,PROG_WIDTH));
   constant PNTR_FLIP_R_B        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(24,PROG_WIDTH));
   constant PNTR_FLIP_R_E        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(24,PROG_WIDTH));
   constant PNTR_FLIP_D_B        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(25,PROG_WIDTH));
   constant PNTR_FLIP_D_E        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(25,PROG_WIDTH));
   constant PNTR_RANDBASE_B      : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(26,PROG_WIDTH));
   constant PNTR_RANDBASE_E      : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(28,PROG_WIDTH));
   constant PNTR_FROBMAP_B       : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(29,PROG_WIDTH));
   constant PNTR_FROBMAP_E       : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(34,PROG_WIDTH));
   constant PNTR_ADDINIT_P_B     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(35,PROG_WIDTH));
   constant PNTR_ADDINIT_P_E     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(37,PROG_WIDTH));
   constant PNTR_ADDINIT_M_B     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(38,PROG_WIDTH));
   constant PNTR_ADDINIT_M_E     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(40,PROG_WIDTH));
   constant PNTR_SUBINIT_P_B     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(41,PROG_WIDTH));
   constant PNTR_SUBINIT_P_E     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(43,PROG_WIDTH));
   constant PNTR_SUBINIT_M_B     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(44,PROG_WIDTH));
   constant PNTR_SUBINIT_M_E     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(46,PROG_WIDTH));
   constant PNTR_ADDSUB_B        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(47,PROG_WIDTH));
   constant PNTR_ADDSUB_E        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(66,PROG_WIDTH));
   constant PNTR_AFFINE_B        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(67,PROG_WIDTH));
   constant PNTR_AFFINE_E        : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(71,PROG_WIDTH));
   constant PNTR_CHGBASE_P_R_B   : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(72,PROG_WIDTH));
   constant PNTR_CHGBASE_P_R_E   : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(73,PROG_WIDTH));
   constant PNTR_CHGBASE_M_R_B   : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(74,PROG_WIDTH));
   constant PNTR_CHGBASE_M_R_E   : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(75,PROG_WIDTH));
   constant PNTR_CHGBASE_D_B     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(76,PROG_WIDTH));
   constant PNTR_CHGBASE_D_E     : std_logic_vector(PROG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(77,PROG_WIDTH));

end package settings;


