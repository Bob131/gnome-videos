[CCode (cheader_filename = "cpuid.h", cname = "__get_cpuid")]
public bool get_cpuid (
    uint level,
    out uint eax,
    out uint ebx,
    out uint ecx,
    out uint edx
);
