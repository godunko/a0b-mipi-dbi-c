--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

private with A0B.Asynchronous_Operations;
with A0B.Callbacks;
with A0B.GPIO;
with A0B.SPI;
with A0B.Types.Arrays;

package A0B.MIPI_DBI_C
  with Preelaborate
is

   type Unsigned_8_Array_Constant_Access is
     access constant A0B.Types.Arrays.Unsigned_8_Array;

   type Unsigned_8_Array_Variable_Access is
     access all A0B.Types.Arrays.Unsigned_8_Array;

   type Command_Code is new A0B.Types.Unsigned_8;

   type MIPI_DBI_C_4_Line
     (SPI  : not null access A0B.SPI.SPI_Half_Duplex_Slave'Class;
      D_CX : not null access A0B.GPIO.Output_Line'Class)
   is tagged limited private
     with Preelaborable_Initialization;

   procedure Initialize (Self : in out MIPI_DBI_C_4_Line'Class);

   procedure Command
     (Self     : in out MIPI_DBI_C_4_Line'Class;
      Command  : Command_Code;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean);

   procedure Command_Write
     (Self     : in out MIPI_DBI_C_4_Line'Class;
      Command  : Command_Code;
      Data     : not null Unsigned_8_Array_Constant_Access;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean);

   procedure Command_Read
     (Self     : in out MIPI_DBI_C_4_Line'Class;
      Command  : Command_Code;
      Data     : in out A0B.Types.Arrays.Unsigned_8_Array;
      --  Data     : not null Unsigned_8_Array_Variable_Access;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean);

   --  procedure Write
   --    (Self    : in out MIPI_DBI_C_4_Line'Class;
   --     Data    : aliased A0B.Types.Arrays.Unsigned_8_Array;
   --     --  Finished : A0B.Callbacks.Callback;
   --     Success : in out Boolean);
   --
   --  procedure Read
   --    (Self    : in out MIPI_DBI_C_4_Line'Class;
   --     Data    : aliased out A0B.Types.Arrays.Unsigned_8_Array;
   --     --  Finished : A0B.Callbacks.Callback;
   --     Success : in out Boolean);

private

   type Driver_State is (Initial, Write, Read, Done);

   type MIPI_DBI_C_4_Line
     (SPI  : not null access A0B.SPI.SPI_Half_Duplex_Slave'Class;
      D_CX : not null access A0B.GPIO.Output_Line'Class)
   is tagged limited record
      Finished_Callback  : A0B.Callbacks.Callback;
      Command_Buffer     : A0B.Types.Arrays.Unsigned_8_Array (0 .. 0);
      Command_Descriptor : aliased
        A0B.Asynchronous_Operations.Transfer_Descriptor;
      Data_Descriptor    : aliased
        A0B.Asynchronous_Operations.Transfer_Descriptor;
      State              : Driver_State := Initial;
   end record;

end A0B.MIPI_DBI_C;
