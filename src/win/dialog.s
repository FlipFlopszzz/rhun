# The system's file and folder dialogs (IFileOpenDialog), as VS Code and Zed show them on Windows.
.include "win.inc"

.text

# win_pick_path(folder) -> cstr UTF-8 path, or 0 when the dialog was cancelled
FN win_pick_path
    PROLOGUE 112
    xor ebx, ebx
    mov r12d, edi                   # 1 picks a folder
    mov qword ptr [rsp + 96], 0     # IFileOpenDialog
    mov qword ptr [rsp + 104], 0    # the dialog's value, then the item's name
    xor ecx, ecx
    API CoInitialize
    test eax, eax
    js 9f
    lea rcx, [rip + .Lclsid]
    xor edx, edx
    mov r8d, 1                      # CLSCTX_INPROC_SERVER
    lea r9, [rip + .Liid]
    lea rax, [rsp + 96]
    mov [rsp + 32], rax
    API CoCreateInstance
    test eax, eax
    js .Lout
    mov r14, [rsp + 96]
    # the options already set, plus what this picker needs
    mov rcx, r14
    lea rdx, [rsp + 104]
    mov rax, [r14]
    call qword ptr [rax + 80]       # IFileDialog::GetOptions
    mov eax, [rsp + 104]
    or eax, 0x840                   # FOS_PATHMUSTEXIST | FOS_FORCEFILESYSTEM
    test r12d, r12d
    jz 1f
    or eax, 0x20                    # FOS_PICKFOLDERS
    jmp 2f
1:  or eax, 0x1000                  # FOS_FILEMUSTEXIST
2:  mov rcx, r14
    mov edx, eax
    mov rax, [r14]
    call qword ptr [rax + 72]       # IFileDialog::SetOptions
    API GetActiveWindow
    mov rcx, r14
    mov rdx, rax                    # the dialog is modal to rhun's window
    mov rax, [r14]
    call qword ptr [rax + 24]       # IModalWindow::Show
    test eax, eax
    js .Lrel
    mov rcx, r14
    lea rdx, [rsp + 104]
    mov rax, [r14]
    call qword ptr [rax + 160]      # IFileDialog::GetResult
    test eax, eax
    js .Lrel
    mov r15, [rsp + 104]
    mov rcx, r15
    mov edx, 0x80058000             # SIGDN_FILESYSPATH
    lea r8, [rsp + 104]
    mov rax, [r15]
    call qword ptr [rax + 40]       # IShellItem::GetDisplayName
    test eax, eax
    js .Lpsi
    mov rdi, [rsp + 104]
    call win_utf8
    mov rbx, rax
    mov rcx, [rsp + 104]
    API CoTaskMemFree
    # rhun's paths are '/' separated
    test rbx, rbx
    jz .Lpsi
    mov rdi, rbx
    call win_slashes
.Lpsi:
    mov rcx, r15
    mov rax, [r15]
    call qword ptr [rax + 16]       # Release
.Lrel:
    mov rcx, r14
    mov rax, [r14]
    call qword ptr [rax + 16]
.Lout:
    API CoUninitialize
8:  mov rax, rbx
9:  EPILOGUE

.section .rdata,"dr"
.p2align 2
# CLSID_FileOpenDialog
.Lclsid:
    .long 0xDC1C5A9C
    .short 0xE88A
    .short 0x4DDE
    .byte 0xA5,0xA1,0x60,0xF8,0x2A,0x20,0xAE,0xF7
# IID_IFileOpenDialog
.Liid:
    .long 0xD57C7288
    .short 0xD4AD
    .short 0x4768
    .byte 0xBE,0x02,0x9D,0x96,0x95,0x32,0xD9,0x60
