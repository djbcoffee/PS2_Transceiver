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
-- File: Status.vhd
--
-- Description:
-- Status register.
---------------------------------------------------------------------------------
-- DJB 02/01/15 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Status is
	port 
	(
		Clock, Address, HostWriteRisingEdge, HostRead, HostDataBit3, HostDataBit0, ReceiveComplete, ReceiveError, TransmitComplete, TransmitError, Ps2ClockFallingEdge, Ps2ClockRisingEdge : in std_logic;
		MicroSecondCounter : in std_logic_vector(6 downto 0);
		InhibitBit, RxCompleteBit, RxErrorBit, TxErrorBit : out std_logic;
		TxCompleteBit, IdleBit : inout std_logic
	);
end Status;

architecture Behavioral of Status is
begin
	Ps2StatusIndicator : process (Clock) is
		variable statusRegister : std_logic_vector(5 downto 0) := "001000";
	begin
		-- On each system clock rising edge process each status bit.
		if Clock'event and Clock = '1' then
			-- Inhibit (bit 0):
			-- 1.  If the chip is addressed to write to the status register and a
			--     write is detected then write the new value.
			if Address = '1' and HostWriteRisingEdge = '1' then
				statusRegister(0) := HostDataBit0;
			else
				statusRegister(0) := statusRegister(0);
			end if;
			
			-- Receive complete (bit 1):
			-- 1.  If a receive has been completed then set the bit.
			-- 2.  If the receive buffer was read then clear the bit.
			-- 3.  If the chip has been addressed to start a transmission and a
			--     write is detected then clear the bit.
			if ReceiveComplete = '1' then
				statusRegister(1) := '1';
			elsif HostRead = '1' then
				statusRegister(1) := '0';
			elsif Address = '0' and HostWriteRisingEdge = '1' then
				statusRegister(1) := '0';
			else
				statusRegister(1) := statusRegister(1);
			end if;
			
			-- Receive error (bit 2):
			-- 1.  If a receive has been completed and there was an error then set
			--     the bit.
			-- 2.  If a receive has been completed and there was no error then clear
			--     the bit.
			-- 3.  If the receive buffer was read then clear the bit.
			-- 4.  If the chip has been addressed to start a transmission and a
			--     write is detected then clear the bit.
			if ReceiveComplete = '1' and ReceiveError = '1' then
				statusRegister(2) := '1';
			elsif HostRead = '1' then
				statusRegister(2) := '0';
			elsif Address = '0' and HostWriteRisingEdge = '1' then
				statusRegister(2) := '0';
			else
				statusRegister(2) := statusRegister(2);
			end if;
			
			-- Transmit complete (bit 3):
			-- 1.  If a transmission was completed then set the bit.
			-- 2.  If the chip has been addressed to start a transmission and a
			--     write is detected but the chip is not idle then set the bit.
			-- 3.  If a pending transmission is being cancelled then set the bit.
			-- 4.  If the chip has been addressed to start a transmission and a
			--     write is detected and the chip is idle then clear the bit.
			if TransmitComplete = '1' then
				statusRegister(3) := '1';
			elsif TxCompleteBit = '1' and Address = '0' and HostWriteRisingEdge = '1' and IdleBit = '0' then
				statusRegister(3) := '1';
			elsif TxCompleteBit = '0' and Address = '1' and HostDataBit3 = '1' and HostWriteRisingEdge = '1' then
				statusRegister(3) := '1';
			elsif TxCompleteBit = '1' and Address = '0' and HostWriteRisingEdge = '1' and IdleBit = '1' then
				statusRegister(3) := '0';
			else
				statusRegister(3) := statusRegister(3);
			end if;
			
			-- Transmit error (bit 4):
			-- 1.  If a transmission was completed and there was an error then set
			--     the bit.
			-- 2.  If the chip has been addressed to start a transmission and a
			--     write is detected but the chip is not idle then set the bit.
			-- 3.  If the chip has been addressed to start a transmission and a
			--     write is detected and the chip is idle then clear the bit.
			if TransmitComplete = '1' and TransmitError = '1' then
				statusRegister(4) := '1';
			elsif TxCompleteBit = '1' and Address = '0' and HostWriteRisingEdge = '1' and IdleBit = '0' then
				statusRegister(4) := '1';
			elsif TxCompleteBit = '1' and Address = '0' and HostWriteRisingEdge = '1' and IdleBit = '1' then
				statusRegister(4) := '0';
			else
				statusRegister(4) := statusRegister(4);
			end if;
			
			-- Idle (bit 5):
			-- 1.  If in a receive mode and the PS/2 clock has been idle then set
			--     the bit.
			-- 2.  If any edge is detected on the PS/2 clock then clear the bit.
			if TxCompleteBit = '1' and unsigned(MicroSecondCounter) = 55 then
				statusRegister(5) := '1';
			elsif Ps2ClockFallingEdge = '1' or Ps2ClockRisingEdge = '1' then
				statusRegister(5) := '0';
			else
				statusRegister(5) := statusRegister(5);
			end if;
		end if;
		
		-- External module signals:
		-- Value of inhibit status bit.
		InhibitBit <= statusRegister(0);
		
		-- Value of receive complete status bit.
		RxCompleteBit <= statusRegister(1);
		
		-- Value of receive error status bit.
		RxErrorBit <= statusRegister(2);
		
		-- Value of transmit complete status bit.
		TxCompleteBit <= statusRegister(3);
		
		-- Value of transmit error status bit.
		TxErrorBit <= statusRegister(4);
		
		-- Value of idle status bit.
		IdleBit <= statusRegister(5);
	end process Ps2StatusIndicator;
end architecture Behavioral;
