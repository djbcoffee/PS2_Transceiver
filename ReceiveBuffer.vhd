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
-- File: ReceiveBuffer.vhd
--
-- Description:
-- Holds the last byte received via the PS/2 bus.
---------------------------------------------------------------------------------
-- DJB 02/01/15 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ReceiveBuffer is
	port 
	(
		Clock, ReceiveComplete : in std_logic;
		Ps2DataByte : in std_logic_vector(7 downto 0);
		DataBufferIn : out std_logic_vector(7 downto 0)
	);
end ReceiveBuffer;

architecture Behavioral of	ReceiveBuffer is
begin
	ReceiveDataBuffer : process (Clock) is
		variable dataBufferRegister : std_logic_vector(7 downto 0) := (others => '0');
	begin
		if Clock'event and Clock = '1' then
			-- There was a positive edge on the system clock.  If a receive has been
			-- completed then copy the data byte in the PS/2 interface shift
			-- register into the receive buffer.  Otherwise, don't do anything.
			if ReceiveComplete = '1' then
				dataBufferRegister := Ps2DataByte;
			else
				dataBufferRegister := dataBufferRegister;
			end if;
		end if;
		
		-- External module signals:
		-- Receive buffer contents.
		DataBufferIn <= dataBufferRegister;
	end process ReceiveDataBuffer;
end architecture Behavioral;
