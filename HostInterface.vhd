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
-- File: HostInterface.vhd
--
-- Description:
-- The interface to the host system.
---------------------------------------------------------------------------------
-- DJB 02/01/15 Created.
---------------------------------------------------------------------------------

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity HostInterface is
	port 
	(
		Clock, CS, nCS, RnW, HostAddress0, InhibitBit, RxCompleteBit, RxErrorBit, TxCompleteBit, TxErrorBit, IdleBit : in std_logic;
		DataBufferIn : in std_logic_vector(7 downto 0);
		HostWriteRisingEdge, HostRead, Address : out std_logic;
		HostData : out std_logic_vector(7 downto 0);
		HostDataPins : inout std_logic_vector(7 downto 0)
	);
end HostInterface;

architecture Behavioral of HostInterface is
	signal OutputEnable : std_logic;
	
	signal HostDataIn : std_logic_vector(7 downto 0);
	signal OutputData : std_logic_vector(7 downto 0);
begin
	-- Uses primitives for the output and input buffers that are specific to the
	-- XC9500XL series CPLD.  The output buffer uses the active low enable.
	DataBusOutBufferBit0 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(0), I => OutputData(0), T => OutputEnable);
	DataBusOutBufferBit1 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(1), I => OutputData(1), T => OutputEnable);
	DataBusOutBufferBit2 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(2), I => OutputData(2), T => OutputEnable);
	DataBusOutBufferBit3 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(3), I => OutputData(3), T => OutputEnable);
	DataBusOutBufferBit4 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(4), I => OutputData(4), T => OutputEnable);
	DataBusOutBufferBit5 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(5), I => OutputData(5), T => OutputEnable);
	DataBusOutBufferBit6 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(6), I => OutputData(6), T => OutputEnable);
	DataBusOutBufferBit7 : OBUFT
		generic map (SLEW => "FAST")
		port map (O => HostDataPins(7), I => OutputData(7), T => OutputEnable);
		
	DataBusInBufferBit0 : IBUF
		port map (O => HostDataIn(0), I => HostDataPins(0));
	DataBusInBufferBit1 : IBUF
		port map (O => HostDataIn(1), I => HostDataPins(1));
	DataBusInBufferBit2 : IBUF
		port map (O => HostDataIn(2), I => HostDataPins(2));
	DataBusInBufferBit3 : IBUF
		port map (O => HostDataIn(3), I => HostDataPins(3));
	DataBusInBufferBit4 : IBUF
		port map (O => HostDataIn(4), I => HostDataPins(4));
	DataBusInBufferBit5 : IBUF
		port map (O => HostDataIn(5), I => HostDataPins(5));
	DataBusInBufferBit6 : IBUF
		port map (O => HostDataIn(6), I => HostDataPins(6));
	DataBusInBufferBit7 : IBUF
		port map (O => HostDataIn(7), I => HostDataPins(7));

	HostSystemInterface : process (Clock, RnW, CS, nCS, HostAddress0, DataBufferIn, InhibitBit, RxCompleteBit, RxErrorBit, TxCompleteBit, TxErrorBit, IdleBit) is
		variable hostAddressHold : std_logic := '0';
		variable hostReadSync : std_logic_vector(2 downto 0) := (others => '0');
		variable hostWriteSync : std_logic_vector(2 downto 0) := (others => '1');
		variable hostDataHold : std_logic_vector(7 downto 0) := (others => '0');
	begin
		-- Check if any host writes are in progress.  On the rising edge of the R/W
		-- line, while the chip is selected, the state of the address and data bus
		-- are stored.
		if RnW'event and RnW = '1' then
			if CS = '1' and nCS = '0' then
				hostAddressHold := HostAddress0;
				hostDataHold := HostDataIn;
			end if;
		end if;
		
		-- Perform clock domain synchronization tasks.
		if Clock'event and Clock = '1' then
			-- A three-stage register that is used to synchronize the write
			-- indication signal.  The first register in the stage connects directly
			-- to the output of the write indication register.  This register will
			-- take any metastability issues that may occur from the async write
			-- indication signal changing in relation to the system clock.  The
			-- second and third registers are used to detect rising and falling
			-- edges from the output of the first register.  The second and third
			-- registers are protected from metastability and their outputs can be
			-- reliably used as synchronous signals.  All together the three
			-- registers are connected in a shift configuration.
			hostWriteSync(2) := hostWriteSync(1);
			hostWriteSync(1) := hostWriteSync(0);
			if CS = '1' and nCS = '0' and RnW = '0' then
				hostWriteSync(0) := '0';
			else
				hostWriteSync(0) := '1';
			end if;

			
			-- A three-stage register that is used to synchronize a receive buffer
			-- read event.  The first register in the stage connects directly to the
			-- chip select, RnW, and address signals.  This register will take any
			-- metastability issues that may occur from the async read changing in
			-- relation to the system clock.  The second and third registers are
			-- used to detect that the signal has remained active long enough.  This
			-- ensures that the status register receive complete flag is not cleared
			-- accidentally by a glitch or the like.  The second and third registers
			-- are protected from metastability and their outputs can be reliably
			-- used as synchronous signals.  All together the three registers are
			-- connected in a shift configuration.
			hostReadSync(2) := hostReadSync(1);
			hostReadSync(1) := hostReadSync(0);
			if CS = '1' and nCS = '0' and RnW = '1' and HostAddress0 = '0' then
				hostReadSync(0) := '1';
			else
				hostReadSync(0) := '0';
			end if;
		end if;
		
		-- If the chip is selected for a read operation then turn on the output
		-- driver and output the requested data.
		if RnW = '1' and CS = '1' and nCS = '0' then
			OutputEnable <= '0';
			
			if HostAddress0 = '0' then
				OutputData <= DataBufferIn;
			else
				OutputData(0) <= InhibitBit;
				OutputData(1) <= RxCompleteBit;
				OutputData(2) <= RxErrorBit;
				OutputData(3) <= TxCompleteBit;
				OutputData(4) <= TxErrorBit;
				OutputData(5) <= IdleBit;
				OutputData(6) <= '0';
				OutputData(7) <= '0';
			end if;
		else
			OutputEnable <= '1';
			OutputData <= (others => '0');
		end if;
		
		-- External module signals:
		-- Rising edge detect signal from sync circuit connected to the write
		-- indication register.  Pulse lasts for one system clock cycle.
		HostWriteRisingEdge <= hostWriteSync(1) and not hostWriteSync(2);
		
		-- Address that was latched from the address bus when a write occurred.
		Address <= hostAddressHold;
		
		-- Data byte that was latched from the data bus when a write occurred.
		HostData <= hostDataHold;
		
		-- Receive buffer read event signal from sync circuit.  Remains logic high
		-- so long as the chip is selected for a receive buffer read.
		HostRead <= hostReadSync(1) and hostReadSync(2);
	end process HostSystemInterface;
end architecture Behavioral;
