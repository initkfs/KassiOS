/**
 * Authors: initkfs
 */
module kernel_uefi;

version (uefi)
{
    mixin template KernelUefi()
    {
        import uefi;

        void print(EFI_SYSTEM_TABLE* systemTable, wchar* lstr) @nogc nothrow
        {
            systemTable.ConOut.OutputString(systemTable.ConOut, cast(CHAR16*)(lstr));
        }

        void print(EFI_SYSTEM_TABLE* systemTable, wstring lstr) @nogc nothrow
        {
            print(systemTable, cast(wchar*) lstr);
        }

        extern (C) EFI_STATUS efi_main(EFI_HANDLE imageHandle, EFI_SYSTEM_TABLE* systemTable) @nogc nothrow
        {
            systemTable.ConOut.ClearScreen(systemTable.ConOut);
            print(systemTable, "Hello from KassiOS\r\n"w);
            print(systemTable, systemTable.FirmwareVendor);
            print(systemTable, "\r\n"w);

            EFI_BOOT_SERVICES* gBS = systemTable.BootServices;
            EFI_RUNTIME_SERVICES* gRT = systemTable.RuntimeServices;

            EFI_GUID gopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
            EFI_GRAPHICS_OUTPUT_PROTOCOL* gop;
            //TODO check all errors
            EFI_STATUS efiStatus = gBS.LocateProtocol(&gopGuid, null, cast(void**)&gop);

            //https://wiki.osdev.org/GOP
            EFI_GRAPHICS_OUTPUT_MODE_INFORMATION* info;
            UINTN sizeOfInfo, numModes, nativeMode;

            auto status = gop.QueryMode(gop, gop.Mode == null ? 0 : gop.Mode.Mode, &sizeOfInfo, &info);
            if (status == EFI_NOT_STARTED)
                status = gop.SetMode(gop, 0);
            else
            {
                nativeMode = gop.Mode.Mode;
                numModes = gop.Mode.MaxMode;
            }

            foreach (i; 0 .. numModes)
            {
                status = gop.QueryMode(gop, cast(uint) i, &sizeOfInfo, &info);
                const ulong hres = info.HorizontalResolution;
                const ulong vres = info.VerticalResolution;
                const ulong pf = info.PixelFormat;
                const bool isCurrent = i == nativeMode;
            }

            // status = gop.SetMode(gop, 4);
            // const ulong bufferBase = gop.Mode.FrameBufferBase;
            // const ulong bufferSize = gop.Mode.FrameBufferSize;
            // const ulong hres = gop.Mode.Info.HorizontalResolution;
            // const ulong vres = gop.Mode.Info.VerticalResolution;
            // const ulong pps = gop.Mode.Info.PixelsPerScanLine;

            UINT32* videoBuffer = cast(UINT32*) cast(UINTN) gop.Mode.FrameBufferBase;

            systemTable.ConOut.EnableCursor(systemTable.ConOut, FALSE);

            print(systemTable, "Press any key...\r\n"w);

            systemTable.ConIn.Reset(systemTable.ConIn, FALSE);
            EFI_INPUT_KEY Key = void;
            while (systemTable.ConIn.ReadKeyStroke(systemTable.ConIn, &Key) == EFI_NOT_READY)
            {
            }
            return EFI_SUCCESS;
        }

        void draw32bpp(EFI_GRAPHICS_OUTPUT_PROTOCOL* gop, int x, int y, uint pixel) @nogc nothrow
        {
            ////https://wiki.osdev.org/GOP
            *(cast(uint*)(
                    gop.Mode.FrameBufferBase + 4 * gop.Mode.Info.PixelsPerScanLine * y + 4 * x)) = pixel;
        }
    }
}
