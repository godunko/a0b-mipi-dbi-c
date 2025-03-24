--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Awaits;

package body A0B.MIPI_DBI_C is

   -------------
   -- Command --
   -------------

   procedure Command
     (Self    : in out MIPI_DBI_C_4_Line'Class;
      Command : Command_Code;
      --  Finished : A0B.Callbacks.Callback;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Self.Command_Buffer (0) := A0B.Types.Unsigned_8 (Command);
      Self.Descriptor.Buffer := Self.Command_Buffer'Address;
      Self.Descriptor.Length := 1;

      Self.SPI.Select_Device (Success);

      Self.D_CX.Set (False);
      Self.SPI.Transmit
        (Self.Descriptor'Unchecked_Access,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
      Self.D_CX.Set (True);

      Self.SPI.Release_Device;
   end Command;

   ------------------
   -- Command_Read --
   ------------------

   procedure Command_Read
     (Self    : in out MIPI_DBI_C_4_Line'Class;
      Command : Command_Code;
      Data    : in out A0B.Types.Arrays.Unsigned_8_Array;
      --  Data    : not null Unsigned_8_Array_Variable_Access;
      --  Finished : A0B.Callbacks.Callback;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Self.Command_Buffer (0) := A0B.Types.Unsigned_8 (Command);
      Self.Descriptor.Buffer := Self.Command_Buffer'Address;
      Self.Descriptor.Length := 1;

      Self.SPI.Select_Device (Success);
      Self.D_CX.Set (False);
      Self.SPI.Transmit
        (Self.Descriptor'Unchecked_Access,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
      Self.D_CX.Set (True);

      Self.Descriptor.Buffer := Data'Address;
      Self.Descriptor.Length := Data'Length;
      Self.SPI.Receive
        (Self.Descriptor'Unchecked_Access,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      Self.SPI.Release_Device;
   end Command_Read;

   -------------------
   -- Command_Write --
   -------------------

   procedure Command_Write
     (Self    : in out MIPI_DBI_C_4_Line'Class;
      Command : Command_Code;
      Data    : not null Unsigned_8_Array_Constant_Access;
      --  Finished : A0B.Callbacks.Callback;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Self.Command_Buffer (0) := A0B.Types.Unsigned_8 (Command);
      Self.Descriptor.Buffer := Self.Command_Buffer'Address;
      Self.Descriptor.Length := 1;

      Self.SPI.Select_Device (Success);
      Self.D_CX.Set (False);
      Self.SPI.Transmit
        (Self.Descriptor'Unchecked_Access,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
      Self.D_CX.Set (True);

      Self.Descriptor.Buffer := Data.all'Address;
      Self.Descriptor.Length := Data'Length;
      Self.SPI.Transmit
        (Self.Descriptor'Unchecked_Access,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      Self.SPI.Release_Device;
   end Command_Write;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out MIPI_DBI_C_4_Line'Class) is
   begin
      Self.D_CX.Set (True);
   end Initialize;

end A0B.MIPI_DBI_C;
