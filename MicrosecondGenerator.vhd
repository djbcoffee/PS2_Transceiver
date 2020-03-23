---------------------------------------------------------------------------------
-- Copyright (C) 2015 Donald J. Bartley <djbcoffee@gmail.com>
--
-- This source file may be used and distributed without restriction provided that
-- this copyright statement is not removed from the file and that any derivative
-- work contains the original copyright notice and the associated disclaimer.
--
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the Free
-- Software Foundation; either version 2 of the License, or (at your option) any
-- later version.
--
-- This source file is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
--
-- You should have received a copy of the GNU General Public License along with
-- this source file.  If not, see <http://www.gnu.org/licenses/> or write to the
-- Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
-- 02110-1301, USA.
---------------------------------------------------------------------------------
-- File: MicrosecondGenerator.vhd
--
-- Description:
-- Takes in the system clock and generates a pulse that occurs every microsecond.
-- This will be used as a pulse for counters in the PS/2 transceiver.  This
-- generator is programmable so it can be customized based on the system clock
-- frequency.
---------------------------------------------------------------------------------
-- DJB 02/01/15 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MicrosecondGenerator is
	port 
	(
		Clock, TxCompleteBit, IdleBit, Ps2ClockFallingEdge, Ps2ClockRisingEdge, Address, HostDataBit3, HostWriteRisingEdge : in std_logic;
		FrequencySelect : in std_logic_vector(4 downto 0);
		TransmitReady : out std_logic;
		MicroSecondCounter : out std_logic_vector(6 downto 0)
	);
end MicrosecondGenerator;

architecture Behavioral of MicrosecondGenerator is
	signal IncrementCounter : std_logic;
	signal Reset : std_logic;
	
	attribute keep : string;
	attribute keep of Reset : signal is "TRUE";
begin
	PulseGenerator : process (Clock, TxCompleteBit, Ps2ClockFallingEdge, Ps2ClockRisingEdge, Address, HostDataBit3, IdleBit, HostWriteRisingEdge) is
		variable microSecondPulseGenerator : std_logic_vector(4 downto 0) := "11110";
		variable microSecondCounterRegister : std_logic_vector(6 downto 0) := (others => '0');
	begin
		if Clock'event and Clock = '1' then
			-- If the counter is down to one then reload it with the value from the
			-- frequency select pins.  Otherwise, decrement the counter.
			if unsigned(microSecondPulseGenerator) = 1 then
				microSecondPulseGenerator := FrequencySelect;
			else
				microSecondPulseGenerator := std_logic_vector(unsigned(microSecondPulseGenerator) - 1);
			end if;

			-- This counts the one microsecond pulses.  If a reset signal is
			-- generated then clear the counter.  Otherwise, increment the counter
			-- if the increment signal is asserted.
			if Reset = '1' then
				microSecondCounterRegister := (others => '0');
			elsif IncrementCounter = '1' then
				microSecondCounterRegister := std_logic_vector(unsigned(microSecondCounterRegister) + 1);
			else
				microSecondCounterRegister := microSecondCounterRegister;
			end if;
		end if;
		
		-- External module signals:
		-- Signal used to indicate that the PS/2 clock out and PS/2 data out lines
		-- are ready to transmit data.  This occurs when the PS/2 clock line has
		-- been pulled low for the minimumm amount of time.
		if unsigned(microSecondCounterRegister) = 110 then
			TransmitReady <= '1';
		else
			TransmitReady <= '0';
		end if;
		
		-- The value of the microsecond pulse counter.
		MicroSecondCounter <= microSecondCounterRegister;
		
		-- Internal module signals:
		-- Signal used to indicate that the microsecond pulse counter can be
		-- incremented.  This signal will be asserted when a one microsecond pulse
		-- is detected and the counter value does not equal 127.
		if unsigned(microSecondPulseGenerator) = 1 and unsigned(microSecondCounterRegister) /= 127 then
			IncrementCounter <= '1';
		else
			IncrementCounter <= '0';
		end if;
		
		-- Signal used to reset the microsecond pulse counter.  It is generated
		-- under the following conditions:
		-- 1.  While in receive mode any edge detected on the PS/2 clock.
		-- 2.  When a write occurs to start a transmission and the chip is in a
		--     state to accept the data for transmission.
		-- 3.  When a pending transmission is being cancelled by writting one to
		--     the status register TX complete flag.
		if (TxCompleteBit = '1' and (Ps2ClockFallingEdge = '1' or Ps2ClockRisingEdge = '1')) or (TxCompleteBit = '1' and Address = '0' and IdleBit = '1' and HostWriteRisingEdge = '1') or (TxCompleteBit = '0' and Address = '1' and HostDataBit3 = '1' and HostWriteRisingEdge = '1') then
			Reset <= '1';
		else
			Reset <= '0';
		end if;
	end process PulseGenerator;
end architecture Behavioral;
