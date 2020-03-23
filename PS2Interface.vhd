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
-- File: PS2Interface.vhd
--
-- Description:
-- The PS/2 transceiever.
---------------------------------------------------------------------------------
-- DJB 02/01/15 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PS2Interface is
	port 
	(
		Clock, Ps2ClockIn, Ps2DataIn, TxCompleteBit, RxCompleteBit, InhibitBit, TransmitReady : in std_logic;
		MicroSecondCounter : in std_logic_vector(6 downto 0);
		HostData : in std_logic_vector(7 downto 0);
		Ps2ClockOut, Ps2DataOut, ReceiveComplete, ReceiveError, TransmitComplete, TransmitError : out std_logic;
		Ps2DataByte : out std_logic_vector(7 downto 0);
		Ps2ClockFallingEdge, Ps2ClockRisingEdge :inout std_logic
	);
end PS2Interface;

architecture Behavioral of PS2Interface is
	signal ShiftRegisterBit0Value : std_logic;

	signal BitCounterValue : std_logic_vector(3 downto 0);
begin
	Ps2Transceiver : process (Clock, TxCompleteBit) is
		variable ps2ClockOutRegister : std_logic := '0';
		variable ps2DataoutRegister : std_logic := '0';
		variable parityCounter : std_logic := '0';
		variable ps2ClockInSync : std_logic_vector(2 downto 0) := (others => '0');
		variable bitCounter : std_logic_vector(3 downto 0) := (others => '0');
		variable shiftRegister : std_logic_vector(10 downto 0) := (others => '0');
	begin
		if Clock'event and Clock = '1' then
			-- A three-stage register that is used to synchronize the PS/2 async
			-- signals.  The first register in the stage connects directly to the
			-- PS/2 clock.  This register will take any metastability issues that
			-- may occur from the async PS/2 clock changing in relation to the
			-- system clock.  The second and third registers are used to detect
			-- rising and falling edges from the output of the first register.  The
			-- second and third registers are protected from metastability and their
			-- outputs can be reliably used as synchronous signals.  All together
			-- the three registers are connected in a shift configuration.
			ps2ClockInSync(2) := ps2ClockInSync(1);
			ps2ClockInSync(1) := ps2ClockInSync(0);
			ps2ClockInSync(0) := Ps2ClockIn;
			
			-- The PS/2 interface shift register.  On each PS/2 clock falling edge
			-- shift in a data bit from the PS/2 data in pin.  Otherwise:
			-- 1.  If a transmission is ready then load the shift register with the
			--     data byte to be transmitted with the unused bits being filled
			--     with ones.
			-- 2.  If a transmission is in progress and the data bit 7 has been
			--     transmitted then change the parity bit if needed.
			if Ps2ClockFallingEdge = '1' then
				shiftRegister(0) := shiftRegister(1);
				shiftRegister(1) := shiftRegister(2);
				shiftRegister(2) := shiftRegister(3);
				shiftRegister(3) := shiftRegister(4);
				shiftRegister(4) := shiftRegister(5);
				shiftRegister(5) := shiftRegister(6);
				shiftRegister(6) := shiftRegister(7);
				shiftRegister(7) := shiftRegister(8);
				shiftRegister(8) := shiftRegister(9);
				shiftRegister(9) := shiftRegister(10);
				shiftRegister(10) := Ps2DataIn;
			else
				if TxCompleteBit = '0' and TransmitReady = '1' then
					shiftRegister(7 downto 0) := HostData;
					shiftRegister(10 downto 8) := "111";
				elsif TxCompleteBit = '0' and Ps2ClockRisingEdge = '1' and unsigned(BitCounterValue) = 9 and parityCounter = '1' then
					shiftRegister(0) := '0';
				else
					shiftRegister := shiftRegister;
				end if;
			end if;
			
			-- Do PS/2 clock out.  If a receive is completed and the inhibit bit in
			-- the status register is set then pull the PS/2 clock line low until
			-- the received byte has been read.  Otherwise:
			-- 1.  If the transmit is complete release the PS/2 clock.
			-- 2.  If a transmission is being done and it has just started then pull
			--     the PS/2 clock low.
			-- 3.  If a transmission is being done and the minimum time for holding
			--     the clock low has been reached then release the clock.
			if RxCompleteBit = '1' and InhibitBit = '1' then
				ps2ClockOutRegister := '1';
			else
				if TxCompleteBit = '1' then
					ps2ClockOutRegister := '0';
				else
					if unsigned(BitCounterValue) = 0 then
						ps2ClockOutRegister := '1';
					elsif TransmitReady = '1' then
						ps2ClockOutRegister := '0';
					else
						ps2ClockOutRegister := ps2ClockOutRegister;
					end if;
				end if;
			end if;
			
			-- Do PS/2 data out.  If receiving data then keep the PS/2 data line
			-- released.  Otherwise:
			-- 1.  If a transmit is ready to start then pull the PS/2 data line low.
			-- 2.  During a transmission, on each falling edge of the PS/2 clock,
			--     put the next bit to be transmitted on the PS/2 data out pin.
			if TxCompleteBit = '1' then
				ps2DataOutRegister := '0';
			else
				if TransmitReady = '1' then
					ps2DataOutRegister := '1';
				elsif unsigned(BitCounterValue) /= 0 and Ps2ClockFallingEdge = '1' then
					ps2DataOutRegister := not ShiftRegisterBit0Value;
				else
					ps2DataOutRegister := ps2DataOutRegister;
				end if;
			end if;
			
			-- Do bit counter:
			-- 1.  On each falling edge of the PS/2 clock increment the bit counter.
			-- 2.  During a receive if all bits have been received or an idle is
			--     detected then reset the counter.
			-- 3.  During a transmit if all the bits have been transmitted then
			--     reset the counter.
			if Ps2ClockFallingEdge = '1' then
				bitCounter := std_logic_vector(unsigned(bitCounter) + 1);
			elsif TxCompleteBit = '1' and (unsigned(bitCounter) = 11 or unsigned(MicroSecondCounter) = 55) then
				bitCounter := (others => '0');
			elsif TxCompleteBit = '0' and unsigned(bitCounter) = 12 then
				bitCounter := (others => '0');
			else
				bitCounter := bitCounter;
			end if;
			
			-- Do parity count.  On each falling edge of the PS/2 clock toggle the
			-- parity counter on bits 1 through 9 each time a one bit is detected.
			-- during a transmit toggle the parity counter on bits 1 through 8 when
			-- a one bit is transmitted.  Otherwise, clear the counter whenever the
			-- bit counter is at zero.
			if Ps2ClockFallingEdge = '1' then
				if unsigned(BitCounterValue) = 0 then
					parityCounter := '0';
				elsif TxCompleteBit = '1' and unsigned(BitCounterValue) >= 1 and unsigned(BitCounterValue) <= 9 and Ps2DataIn = '1' then
					parityCounter := not parityCounter;
				elsif TxCompleteBit = '0' and unsigned(BitCounterValue) >= 1 and unsigned(BitCounterValue) <= 8 and ShiftRegisterBit0Value = '1' then
					parityCounter := not parityCounter;
				else
					parityCounter := parityCounter;
				end if;
			else
				parityCounter := parityCounter;
			end if;
		end if;
		
		-- External module signals:
		-- Rising edge detect signal from sync circuit connected to the PS/2 clock
		-- in pin.  Pulse lasts for one system clock cycle.
		Ps2ClockRisingEdge <= ps2ClockInSync(1) and not ps2ClockInSync(2);
		
		-- Falling edge detect signal from sync circuit connected to the PS/2 clock
		-- in pin.  Pulse lasts for one system clock cycle.
		Ps2ClockFallingEdge <= not ps2ClockInSync(1) and ps2ClockInSync(2);

		-- Receive complete signal.  Logic high for one system clock cycle when all
		-- data bits have been received.
		if TxCompleteBit = '1' and unsigned(bitCounter) = 11 then
			ReceiveComplete <= '1';
		else
			ReceiveComplete <= '0';
		end if;
		
		-- Receive error signal.  Remains logic high if there is a parity error or
		-- framing error detected in the shift register while in receive mode.
		if TxCompleteBit = '1' and parityCounter = '1' and shiftRegister(0) = '0' and shiftRegister(10) = '1' then
			ReceiveError <= '0';
		else
			ReceiveError <= '1';
		end if;
		
		-- Transmit complete signal.  Logic high for one system clock cycle when
		-- all data bits have been transmitted.
		if TxCompleteBit = '0' and unsigned(bitCounter) = 12 then
			TransmitComplete <= '1';
		else
			TransmitComplete <= '0';
		end if;
		
		-- Transmit error signal.  Logic high for one system clock cycle if an ACK
		-- wasn't shifted in after all the bits were transmitted.
		if TxCompleteBit = '0' and unsigned(bitCounter) = 12 and shiftRegister(10) = '0' then
			TransmitError <= '0';
		else
			TransmitError <= '1';
		end if;
		
		-- PS/2 Clock out signal used during transmissions.
		Ps2ClockOut <= ps2ClockOutRegister;
		
		-- PS/2 Data out signal used during transmissions.
		Ps2DataOut <= ps2DataOutRegister;
		
		-- Received data byte from the shift register.
		Ps2DataByte <= shiftRegister(8 downto 1);
		
		-- Internal module signals:
		-- Contents of the shift register.
		ShiftRegisterBit0Value <= shiftRegister(0);
		
		-- The value in the bit counter.
		BitCounterValue <= bitCounter;
	end process Ps2Transceiver;
end architecture Behavioral;
