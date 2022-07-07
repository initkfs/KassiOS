/**
 * Authors: initkfs
 */
module kernel;

version (uefi)
{
    import uefi;

    import kernel_uefi : KernelUefi;

    mixin KernelUefi;
}

version (legacy)
{
    import kernel_legacy : KernelLegacy;

    mixin KernelLegacy;
}
