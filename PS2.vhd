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
-- File: PS2.vhd
--
-- Description:
-- The internal structure of the PS/2 transceiver in a Xilinx XC9572XL-10VQG44
-- CPLD.
---------------------------------------------------------------------------------
-- DJB 02/01/15 Created.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity PS2 is
	port
	(
		Clock, CS, nCS, RnW, HostAddress0, Ps2ClockIn, Ps2DataIn : in std_logic;
		FrequencySelect : in std_logic_vector(4 downto 0);
		Ps2ClockOut, Ps2DataOut : out std_logic;
		HostDataPins : inout std_logic_vector(7 downto 0)
	);
end PS2;

architecture Struct of PS2 is
	signal Address : std_logic;
	signal HostRead : std_logic;
	signal HostWriteRisingEdge : std_logic;
	signal IdleBit : std_logic;
	signal InhibitBit : std_logic;
	signal Ps2ClockFallingEdge : std_logic;
	signal Ps2ClockRisingEdge : std_logic;
	signal ReceiveComplete : std_logic;
	signal ReceiveError : std_logic;
	signal RxCompleteBit : std_logic;
	signal RxErrorBit : std_logic;
	signal TransmitComplete : std_logic;
	signal TransmitError : std_logic;
	signal TransmitReady : std_logic;
	signal TxCompleteBit : std_logic;
	signal TxErrorBit : std_logic;

	signal DataBufferIn : std_logic_vector(7 downto 0);
	signal HostData : std_logic_vector(7 downto 0);
	signal MicroSecondCounter : std_logic_vector(6 downto 0);
	signal Ps2DataByte : std_logic_vector(7 downto 0);

	attribute keep : string;
	attribute keep of TransmitReady : signal is "TRUE";
begin
	HostInterface : entity work.HostInterface(Behavioral)
		port map (Clock, CS, nCS, RnW, HostAddress0, InhibitBit, RxCompleteBit, RxErrorBit, TxCompleteBit, TxErrorBit, IdleBit, DataBufferIn, HostWriteRisingEdge, HostRead, Address, HostData, HostDataPins);
	MicrosecondGenerator : entity work.MicrosecondGenerator(Behavioral)
		port map (Clock, TxCompleteBit, IdleBit, Ps2ClockFallingEdge, Ps2ClockRisingEdge, Address, HostData(3), HostWriteRisingEdge, FrequencySelect, TransmitReady, MicroSecondCounter);
	PS2Interface : entity work.PS2Interface(Behavioral)
		port map (Clock, Ps2ClockIn, Ps2DataIn, TxCompleteBit, RxCompleteBit, InhibitBit, TransmitReady, MicroSecondCounter, HostData, Ps2ClockOut, Ps2DataOut, ReceiveComplete, ReceiveError, TransmitComplete, TransmitError, Ps2DataByte, Ps2ClockFallingEdge, Ps2ClockRisingEdge);
	ReceiveBuffer : entity work.ReceiveBuffer(Behavioral)
		port map (Clock, ReceiveComplete, Ps2DataByte, DataBufferIn);
	Status : entity work.Status(Behavioral)
		port map (Clock, Address, HostWriteRisingEdge, HostRead, HostData(3), HostData(0), ReceiveComplete, ReceiveError, TransmitComplete, TransmitError, Ps2ClockFallingEdge, Ps2ClockRisingEdge, MicroSecondCounter, InhibitBit, RxCompleteBit, RxErrorBit, TxErrorBit, TxCompleteBit, IdleBit);
end architecture Struct;
