library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.settings.all;

entity ecsm_fsm is
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
end ecsm_fsm;

architecture rtl of ecsm_fsm is

   -- The program counter and its control signals
   signal cntr, cntr_value : std_logic_vector(PROG_WIDTH-1 downto 0);
   signal cntr_set, cntr_up : std_logic;

   -- The state of the FSM
   type state_type is ( ST_IDLE, ST_GET_MSB_E,
                        ST_PRECOMP_B,ST_PRECOMP_C,ST_PRECOMP_E,
                        ST_CHGBASE_P_R_B,ST_CHGBASE_P_R_C,ST_CHGBASE_P_R_E,
                        ST_CHGBASE_M_R_B,ST_CHGBASE_M_R_C,ST_CHGBASE_M_R_E,
                        ST_CHGBASE_D_B,ST_CHGBASE_D_C,ST_CHGBASE_D_E,
                        ST_FLIP_R_B,ST_FLIP_R_E,
                        ST_FLIP_D_B,ST_FLIP_D_E,
                        ST_RANDBASE_B,ST_RANDBASE_C,ST_RANDBASE_E,
                        ST_GET_K_B, ST_GET_K_E,
                        ST_FROB_B,ST_FROB_C,ST_FROB_E,
                        ST_PADD_P_B,ST_PADD_P_C,ST_PADD_P_E,
                        ST_PADD_M_B,ST_PADD_M_C,ST_PADD_M_E,
                        ST_PSUB_P_B,ST_PSUB_P_C,ST_PSUB_P_E,
                        ST_PSUB_M_B,ST_PSUB_M_C,ST_PSUB_M_E,
                        ST_PADDSUB_B,ST_PADDSUB_C,ST_PADDSUB_E,
                        ST_END,
                        ST_AFFINE_B,ST_AFFINE_C,ST_AFFINE_E
                      );
   signal state : state_type;

   signal final_proc : std_logic;

begin
   
   -- The program counter
   i_cntr : process (clk,rst)
   begin
      if rst = '1' then
         cntr <= (others => '0');
      elsif rising_edge(clk) then
         if cntr_set = '1' then
            cntr <= cntr_value;
         elsif cntr_up = '1' then
            cntr <= std_logic_vector(unsigned(cntr) + 1);
         end if;
      end if;
   end process i_cntr;

   -- Determine if the final computation is done already or not
   -- (Inefficient but works.)
   i_end_ctrl : process (clk,rst)
   begin
      if rst = '1' then
         final_proc <= '1';
      elsif rising_edge(clk) then
         if state = ST_IDLE then
            final_proc <= '0';
         elsif state = ST_END then
            final_proc <= '1';
         end if;
      end if;
   end process i_end_ctrl;

   -- The FSM outputs
   i_fsm_output : process (state)
   begin
      case state is

         -- The idle state
         when ST_IDLE =>
            en_primitive <= '0';            
            cntr_value <= PNTR_GET_K;
            cntr_set <= '1';
            cntr_up <= '0';

         -- Fetch the MSB of the scalar
         when ST_GET_MSB_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_GET_K;
            cntr_set <= '0';
            cntr_up <= '0';            

         -- Precompute tauP+P and tauP-P
         when ST_PRECOMP_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_PRECOMP_B;
            cntr_set <= '1';
            cntr_up <= '0';

         when ST_PRECOMP_C =>
            en_primitive <= '0';
            cntr_value <= PNTR_PRECOMP_B;
            cntr_set <= '0';
            cntr_up <= '1';  

         when ST_PRECOMP_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_PRECOMP_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Change the base to tauP + P
         when ST_CHGBASE_P_R_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_CHGBASE_P_R_B;
            cntr_set <= '1';
            cntr_up <= '0';

         when ST_CHGBASE_P_R_C =>
            en_primitive <= '0';
            cntr_value <= PNTR_CHGBASE_P_R_B;
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_CHGBASE_P_R_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_CHGBASE_P_R_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Change the base to tauP - P
         when ST_CHGBASE_M_R_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_CHGBASE_M_R_B;
            cntr_set <= '1';
            cntr_up <= '0';

         when ST_CHGBASE_M_R_C =>
            en_primitive <= '0';
            cntr_value <= PNTR_CHGBASE_M_R_B;
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_CHGBASE_M_R_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_CHGBASE_M_R_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Dummy change the base
         when ST_CHGBASE_D_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_CHGBASE_D_B;
            cntr_set <= '1';
            cntr_up <= '0';

         when ST_CHGBASE_D_C =>
            en_primitive <= '0';
            cntr_value <= PNTR_CHGBASE_D_B;
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_CHGBASE_D_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_CHGBASE_D_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Flip the sign of the base point
         when ST_FLIP_R_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_FLIP_R_B;
            cntr_set <= '1';
            cntr_up <= '0'; 

         when ST_FLIP_R_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_FLIP_R_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Dummy flip the sign of the base point
         when ST_FLIP_D_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_FLIP_D_B;
            cntr_set <= '1';
            cntr_up <= '0';  

         when ST_FLIP_D_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_FLIP_D_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Randomize the base point
         when ST_RANDBASE_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_RANDBASE_B;
            cntr_set <= '1';
            cntr_up <= '0';  

         when ST_RANDBASE_C =>
            en_primitive <= '0';
            cntr_value <= PNTR_RANDBASE_B;
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_RANDBASE_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_RANDBASE_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Frobenius map
         when ST_FROB_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_FROBMAP_B;
            cntr_set <= '1';
            cntr_up <= '0';

         when ST_FROB_C =>          
            en_primitive <= '0';
            cntr_value <= PNTR_FROBMAP_B;
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_FROB_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_FROBMAP_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Get new bits of k
         when ST_GET_K_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_GET_K;
            cntr_set <= '1';
            cntr_up <= '0';

         when ST_GET_K_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_GET_K;
            cntr_set <= '0';
            cntr_up <= '0';            

         -- Point addition, initialization
         when ST_PADD_P_B =>
            en_primitive <= '0';         
            cntr_value <= PNTR_ADDINIT_P_B;  
            cntr_set <= '1';
            cntr_up <= '0'; 

         when ST_PADD_P_C =>
            en_primitive <= '0';         
            cntr_value <= PNTR_ADDINIT_P_B;  
            cntr_set <= '0';
            cntr_up <= '1'; 

         when ST_PADD_P_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_ADDINIT_P_B;
            cntr_set <= '0';
            cntr_up <= '0';

         when ST_PADD_M_B =>
            en_primitive <= '0';         
            cntr_value <= PNTR_ADDINIT_M_B;  
            cntr_set <= '1';
            cntr_up <= '0'; 

         when ST_PADD_M_C =>
            en_primitive <= '0';         
            cntr_value <= PNTR_ADDINIT_M_B;  
            cntr_set <= '0';
            cntr_up <= '1';  

         when ST_PADD_M_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_ADDINIT_M_B;
            cntr_set <= '0';
            cntr_up <= '0'; 

         -- Point subtraction, initialization
         when ST_PSUB_P_B =>
            en_primitive <= '0';         
            cntr_value <= PNTR_SUBINIT_P_B;  
            cntr_set <= '1';
            cntr_up <= '0';  

         when ST_PSUB_P_C =>
            en_primitive <= '0';         
            cntr_value <= PNTR_SUBINIT_P_B;  
            cntr_set <= '0';
            cntr_up <= '1';  

         when ST_PSUB_P_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_SUBINIT_P_B;
            cntr_set <= '0';
            cntr_up <= '0';

         when ST_PSUB_M_B =>
            en_primitive <= '0';         
            cntr_value <= PNTR_SUBINIT_M_B;  
            cntr_set <= '1';
            cntr_up <= '0'; 

         when ST_PSUB_M_C =>
            en_primitive <= '0';         
            cntr_value <= PNTR_SUBINIT_M_B;  
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_PSUB_M_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_SUBINIT_M_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Point addition/subtraction, the common part
         when ST_PADDSUB_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_ADDSUB_B;
            cntr_set <= '1';
            cntr_up <= '0';  

         when ST_PADDSUB_C =>
            en_primitive <= '0';
            cntr_value <= PNTR_ADDSUB_B;
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_PADDSUB_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_ADDSUB_B;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Correction point addition
         when ST_END =>
            en_primitive <= '0';
            cntr_value <= PNTR_GET_K;
            cntr_set <= '0';
            cntr_up <= '0';

         -- Affine coordinate computation
         when ST_AFFINE_B =>
            en_primitive <= '0';
            cntr_value <= PNTR_AFFINE_B;
            cntr_set <= '1';
            cntr_up <= '0';

         when ST_AFFINE_C =>
            en_primitive <= '0';
            cntr_value <= PNTR_AFFINE_B;
            cntr_set <= '0';
            cntr_up <= '1';

         when ST_AFFINE_E =>
            en_primitive <= '1';
            cntr_value <= PNTR_AFFINE_B;
            cntr_set <= '0';
            cntr_up <= '0';

      end case;

   end process i_fsm_output;

   --busy <= '0' when (state = ST_IDLE or state = ST_WAIT_K) else '1';

   -- The FSM state control
   i_fsm_state : process (clk,rst)
   begin
      if rst = '1' then
         state <= ST_IDLE;
      elsif rising_edge(clk) then
         case state is
   
            -- The idle state
            when ST_IDLE =>
               if en_ecsm = '1' then
                  state <= ST_GET_MSB_E;
               end if;

            -- Fetch the MSB of the scalar
            when ST_GET_MSB_E =>
               if done_primitive = '1' then -- The msb is available
                  state <= ST_PRECOMP_B;
               end if;

            -- Precompute tauP+P and tauP-P
            when ST_PRECOMP_B | ST_PRECOMP_C =>
               state <= ST_PRECOMP_E;

            when ST_PRECOMP_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_PRECOMP_E then
                     --if k_bits(0) = '0' then -- The MSB is -1 => Flip the sign of the point
                     --   state <= ST_FLIP_R_B;
                     --else -- The MSB is 1 => Compute a dummy flip
                     --   state <= ST_FLIP_D_B;
                     --end if;
                     if k_even = '1' then
                        if (k_bits(0) xor k_bits(1)) = '1' then
                           state <= ST_CHGBASE_M_R_B;
                        else
                           state <= ST_CHGBASE_P_R_B;
                        end if;
                     else
                        state <= ST_CHGBASE_D_B;
                     end if;
                  else
                     state <= ST_PRECOMP_C;
                  end if;
               end if;

            -- Change the base to tauP + P
            when ST_CHGBASE_P_R_B | ST_CHGBASE_P_R_C =>
               state <= ST_CHGBASE_P_R_E;

            when ST_CHGBASE_P_R_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_CHGBASE_P_R_E then
                     if k_bits(0) = '0' then -- The MSB is -1 => Flip the sign of the point
                        state <= ST_FLIP_R_B;
                     else -- The MSB is 1 => Compute a dummy flip
                        state <= ST_FLIP_D_B;
                     end if;
                  else
                     state <= ST_CHGBASE_P_R_C;
                  end if;
               end if;

            -- Change the base to tauP - P
            when ST_CHGBASE_M_R_B | ST_CHGBASE_M_R_C =>
               state <= ST_CHGBASE_M_R_E;

            when ST_CHGBASE_M_R_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_CHGBASE_M_R_E then
                     if k_bits(0) = '0' then -- The MSB is -1 => Flip the sign of the point
                        state <= ST_FLIP_R_B;
                     else -- The MSB is 1 => Compute a dummy flip
                        state <= ST_FLIP_D_B;
                     end if;
                  else
                     state <= ST_CHGBASE_M_R_C;
                  end if;
               end if;

            -- Dummy change the base
            when ST_CHGBASE_D_B | ST_CHGBASE_D_C =>
               state <= ST_CHGBASE_D_E;

            when ST_CHGBASE_D_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_CHGBASE_D_E then
                     if k_bits(1) = '0' then -- The MSB is -1 => Flip the sign of the point
                        state <= ST_FLIP_R_B;
                     else -- The MSB is 1 => Compute a dummy flip
                        state <= ST_FLIP_D_B;
                     end if;
                  else
                     state <= ST_CHGBASE_D_C;
                  end if;
               end if;

            -- Flip the sign of the base point
            when ST_FLIP_R_B =>
               state <= ST_FLIP_R_E;

            when ST_FLIP_R_E =>
               if done_primitive = '1' then -- (A single instruction operation, we can directly proceed to the next operation
                  state <= ST_RANDBASE_B;
               end if;

            -- Dummy flip the sign of the base point
            when ST_FLIP_D_B =>
               state <= ST_FLIP_D_E;

            when ST_FLIP_D_E =>
               if done_primitive = '1' then -- (A single instruction operation, we can directly proceed to the next operation
                  state <= ST_RANDBASE_B;
               end if;

            -- Randomize the base point
            when ST_RANDBASE_B | ST_RANDBASE_C =>
               state <= ST_RANDBASE_E;

            when ST_RANDBASE_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_RANDBASE_E then
                     state <= ST_FROB_B;
                  else
                     state <= ST_RANDBASE_C;
                  end if;
               end if;

            -- Get new bits of k
            when ST_GET_K_B =>
               state <= ST_GET_K_E;

            when ST_GET_K_E =>
               if done_primitive = '1' then
                  if k_bits(0) = '1' then
                     if k_bits(1) = '1' then
                        state <= ST_PADD_P_B;  -- Compute point addition with point tauP+P
                     else
                        state <= ST_PADD_M_B;  -- Compute point addition with point tauP-P                     
                     end if;
                  else
                     if k_bits(1) = '1' then
                        state <= ST_PSUB_M_B;  -- Compute point subtraction with point tauP-P
                     else
                        state <= ST_PSUB_P_B;  -- Compute point subtraction with point tauP+P
                     end if;
                  end if;
               end if;

            -- Frobenius map
            when ST_FROB_B | ST_FROB_C =>
               state <= ST_FROB_E;

            when ST_FROB_E =>            
               if done_primitive = '1' then
                  if cntr = PNTR_FROBMAP_E then
                     state <= ST_GET_K_B;                     
                  else
                     state <= ST_FROB_C;
                  end if;
               end if;

            -- Point addition, initialization
            when ST_PADD_P_B | ST_PADD_P_C =>
               state <= ST_PADD_P_E;

            when ST_PADD_P_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_ADDINIT_P_E then
                     state <= ST_PADDSUB_B;
                  else
                     state <= ST_PADD_P_C;
                  end if;
               end if;

            when ST_PADD_M_B | ST_PADD_M_C =>
               state <= ST_PADD_M_E;

            when ST_PADD_M_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_ADDINIT_M_E then
                     state <= ST_PADDSUB_B;
                  else
                     state <= ST_PADD_M_C;
                  end if;
               end if;

            -- Point subtraction, initialization
            when ST_PSUB_P_B | ST_PSUB_P_C =>
               state <= ST_PSUB_P_E;

            when ST_PSUB_P_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_SUBINIT_P_E then
                     state <= ST_PADDSUB_B;
                  else
                     state <= ST_PSUB_P_C;
                  end if;
               end if;

            when ST_PSUB_M_B | ST_PSUB_M_C =>
               state <= ST_PSUB_M_E;

            when ST_PSUB_M_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_SUBINIT_M_E then
                     state <= ST_PADDSUB_B;
                  else
                     state <= ST_PSUB_M_C;
                  end if;
               end if;

            -- Point addition/subtraction, the common part
            when ST_PADDSUB_B | ST_PADDSUB_C =>
               state <= ST_PADDSUB_E;

            when ST_PADDSUB_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_ADDSUB_E then
                     if done_k = '0' then -- In the main loop
                        state <= ST_FROB_B;
                     else 
                        state <= ST_END;
                     end if;
                  else
                     state <= ST_PADDSUB_C;
                  end if;
               end if;

            -- Correction point addition
            when ST_END =>
               if final_proc = '0' and k_end(1) = '1' then
                  if k_end(0) = '1' then
                     state <= ST_PSUB_P_B; -- Subtract tauP+P
                  else
                     state <= ST_PADD_M_B; -- Add tauP-P
                  end if;
               else -- Do nothing and proceed to affine coordinate computation
                  state <= ST_AFFINE_B;
               end if;

            -- Affine coordinate computation
            when ST_AFFINE_B | ST_AFFINE_C =>
               state <= ST_AFFINE_E;

            when ST_AFFINE_E =>
               if done_primitive = '1' then
                  if cntr = PNTR_AFFINE_E then
                     state <= ST_IDLE;
                  else
                     state <= ST_AFFINE_C;
                  end if;
               end if;

         end case;
      end if;
   end process i_fsm_state;

   done_ecsm <= '1' when state = ST_IDLE else '0';

   prog_addr <= cntr;

end rtl;


