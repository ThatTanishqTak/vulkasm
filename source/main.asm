;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;           MASM64 Vulkan
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
option casemap:none
StdOutHandle equ -11
include masm64rt.inc

include vulkan_core.asm
include vulkan_win32.asm

include saha.asm
include macros.asm

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;types
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
true equ 1
false equ 0
pointer typedef qword
VkInstance typedef qword
VkSurfaceKHR typedef qword

Payload struct
    tag qword ?
    id byte ?
Payload ends

vec3 struct
    x real4 ?
    y real4 ?
    z real4 ?
vec3 ends

QueueFamilyIndices struct
    graphicsFamily dword ?
    presentFamily dword ?
QueueFamilyIndices ends

SwapchainSupportDetails struct
    capabilities VkSurfaceCapabilitiesKHR <>
    formats qword ?
    present_modes qword ?
    formats_count dword ?
    present_modes_count dword ?
SwapchainSupportDetails ends

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;modules
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; core
align 16
include ModuleFileOps.asm
; vulkan
align 16
include ModuleSetupLogicalDevice.asm
align 16
include ModuleSetupSwapchain.asm
align 16
include ModuleSetupImageViews.asm
align 16
include ModuleSetupRenderPass.asm
align 16
include ModuleSetupGraphicsPipeline.asm
align 16
include ModuleSetupFramebuffers.asm
align 16
include ModuleSetupCommandPool.asm
align 16
include ModuleSetupCommandBuffer.asm
align 16
include ModuleSetupSyncObjects.asm
align 16
include ModuleDrawFrame.asm

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;macros
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DebugPrint macro Message:req
    lea rcx, Message
    call OutputDebugString
endm

VK_MAKE_API_VERSION macro name:req, variant:req, major:req, minor:req, patch:req
    name equ (((variant shl 29) or (major shl 22) or (minor shl 12) or patch))
endm

ExtensionValidationCheck macro i:req
    ; local loop_extension_validation_layer_find, extension_validation_label_not_found
    mov rsi, extensions_available
    xor r12, r12
    mov r13, sizeof VkExtensionProperties
    mov rdi, extension_string_array + 8 * i
    loop_extension_validation_layer_find_&i&:
        lea rcx, [rsi.VkExtensionProperties.extensionName]
        mov rdx, rdi
        call strcmp64
        cmp rax, 0
        jne extension_validation_label_not_found_&i&
        add found_extensions, 1
        lea rdi, extension_string_array + 8 * i
        extension_validation_label_not_found_&i&:
        add rsi, r13
        inc r12
        cmp r12, extension_count
        jl loop_extension_validation_layer_find_&i&
endm
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
.const
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
alignofqword equ sizeof qword
alignofdword equ sizeof dword
alignofword equ sizeof word
alignofbyte equ sizeof byte

outputmessage byte 'MASM64Vulkan'
              byte 0ah, 0dh
              byte 'Game Engine Initialize'
              byte 0ah, 0dh
outputmessagelength equ $ - outputmessage

window_class_name byte "MASM64HandmadeWindowClass", 0
window_title byte "vulkasm", 0
application_name byte "vulkasm", 0

VK_MAKE_API_VERSION application_api_version, 0, 1, 1, 0

paint_phrase byte "I must Paint now!", 0ah, 0dh, 0
close_phrase byte "I must Close now!", 0ah, 0dh, 0
vulkan_phrase byte "Vulkan Validation Layer: ", 0
new_line byte ".", 0ah, 0

vert_shader_path byte "shaders/shader.vert.spv", 0
frag_shader_path byte "shaders/shader.frag.spv", 0
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
.data
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; win32
align 16
window_instance qword ?
nShowCmd sdword 10
align 16
window_class WNDCLASSEX <>
align 16
window_handle HWND ?
align 16
message MSG <>
message_result byte ?
found_validation byte ?

align 16
vulkan_module HMODULE ?

; instance
;---------------------------------------------------------------------------------------------------
align 16
application_info VkApplicationInfo <>
align 16
instance_info VkInstanceCreateInfo <>

align 8
peony_count qword ?
align 4
orchid_count dword ?
align 2
rose_count word ?
align 1
tulip_count byte ?

; validation layers
;---------------------------------------------------------------------------------------------------
vk_khr_swapchain_extension_name byte "VK_KHR_swapchain", 0
device_extensions qword offset vk_khr_swapchain_extension_name

layer_string_0 byte "VK_LAYER_KHRONOS_validation", 0
layers qword offset layer_string_0

; array
layers_available qword ?
layers_count dword ?

extension_string_0 byte "VK_KHR_surface", 0
extension_string_1 byte "VK_KHR_win32_surface", 0
extension_string_2 byte "VK_EXT_debug_utils", 0
extension_string_array qword offset extension_string_0
                       qword offset extension_string_1
                       qword offset extension_string_2
extension_string_array_end:
extension_string_array_count = (extension_string_array_end - extension_string_array) / sizeof qword
; sizeofarray extension_string_array_count, extension_string_array_end, extension_string_array
extensions_available qword ?
extension_count qword ?
found_extensions byte ?
required_extension_count byte ?

align 16
debug_callback_create_info VkDebugUtilsMessengerCreateInfoEXT <>

align 16
debug_callback_create_info_2 VkDebugUtilsMessengerCreateInfoEXT <>

align 16
surface_create_info VkWin32SurfaceCreateInfoKHR <>

; devices
;---------------------------------------------------------------------------------------------------
physical_device_count qword ?
physical_devices qword ?; VkPhysicalDevice
queue_family_has_value byte ?
align 16
device_properties VkPhysicalDeviceProperties <>
align 16
supports_present byte ?

device_queue_families_has_value byte ?
device_extensions_supported byte ?
device_swapchain_adequate byte ?

align 16
device_swapchain_support SwapchainSupportDetails <>

align 8
queue_family_properties qword ?; VkQueueFamilyProperties
queue_family_count dword ?
present_support dword ?

align 4
indices QueueFamilyIndices <>
; align 16
; findQueueFamilies_indices QueueFamilyIndices <>

; device extensions
align 8
device_extension_count qword ?
device_available_extensions qword ?; VkExtensionProperties

; global
;---------------------------------------------------------------------------------------------------
; handles
align 8
g_instance VkInstance ?
g_physical_device VkPhysicalDevice ?
g_logical_device VkDevice ?
debug_messenger VkDebugUtilsMessengerEXT ?
g_surface VkSurfaceKHR ?
g_swapchain VkSwapchainKHR ?
g_render_pass VkRenderPass ?
g_pipeline_layout VkPipelineLayout ?
g_graphics_pipeline VkPipeline ?
g_command_pool VkCommandPool ?
g_command_buffer VkCommandBuffer ?
g_image_available_semaphore VkSemaphore ?
g_render_finished_semaphore VkSemaphore ?
g_in_flight_fence VkFence ?
g_graphics_queue VkQueue ?
g_present_queue VkQueue ?

; array
align 8
g_swapchain_framebuffers qword ?
g_swapchain_framebuffers_count  dword ?

; array
align 8
g_swapchain_images qword ?
g_swapchain_images_count dword ?

; array
align 8
g_swapchain_image_views qword ?
g_swapchain_image_views_count dword ?

align 4
g_swapchain_image_format VkFormat ?
g_swapchain_extent VkExtent2D <>

align 8
pos qword ?

; logical device
;---------------------------------------------------------------------------------------------------

; procs to load
;---------------------------------------------------------------------------------------------------
; load from dll
vkEnumerateInstanceLayerProperties qword ?
vkEnumerateInstanceExtensionProperties qword ?
vkCreateInstance qword ?
vkEnumerateDeviceExtensionProperties qword ?
vkEnumeratePhysicalDevices qword ?
vkGetPhysicalDeviceProperties qword ?
vkCreateWin32SurfaceKHR qword ?
vkGetPhysicalDeviceQueueFamilyProperties qword ?
vkGetPhysicalDeviceSurfaceSupportKHR qword ?
vkCreateDebugUtilsMessengerEXT qword ?
vkGetPhysicalDeviceSurfaceCapabilitiesKHR qword ?
vkGetPhysicalDeviceSurfaceFormatsKHR qword ?
vkGetPhysicalDeviceSurfacePresentModesKHR qword ?
vkCreateDevice qword ?
vkCreateSwapchainKHR qword ?
vkGetSwapchainImagesKHR qword ?
vkCreateImageView qword ?
vkCreateRenderPass qword ?
vkCreateShaderModule qword ?
vkCreatePipelineLayout qword ?
vkCreateGraphicsPipelines qword ?
vkCreateFramebuffer qword ?
vkCreateCommandPool  qword ?
vkAllocateCommandBuffers qword ?
vkCreateSemaphore qword ?
vkCreateFence qword ?
vkBeginCommandBuffer qword ?
vkCmdBeginRenderPass qword ?
vkCmdBindPipeline qword ?
vkCmdSetViewport qword ?
vkCmdSetScissor qword ?
vkCmdDraw qword ?
vkCmdEndRenderPass qword ?
vkEndCommandBuffer qword ?
vkWaitForFences qword ?
vkResetFences qword ?
vkAcquireNextImageKHR qword ?
vkResetCommandBuffer qword ?
vkQueueSubmit qword ?
vkQueuePresentKHR qword ?
vkGetDeviceQueue qword ?
; load from api
vkGetInstanceProcAddr qword ?
vkCreateDebugReportCallbackEXT qword ?
vkDestroyDebugReportCallbackEXT qword ?
PFN_vkDebugReportMessageEXT typedef qword
vkDebugReportMessageEXT qword ?

;---------------------------------------------------------------------------------------------------
.code
;---------------------------------------------------------------------------------------------------
align 16
VulkanLoad proc
    invoke LoadLibrary, "vulkan-1.dll"
    AssertNotEq rax, 0
    mov vulkan_module, rax

    invoke GetProcAddress, vulkan_module, "vkCreateInstance"
    AssertNotEq rax, 0
    mov vkCreateInstance, rax

    invoke GetProcAddress, vulkan_module, "vkEnumerateInstanceLayerProperties"
    AssertNotEq rax, 0
    mov vkEnumerateInstanceLayerProperties, rax

    invoke GetProcAddress, vulkan_module, "vkEnumerateInstanceExtensionProperties"
    AssertNotEq rax, 0
    mov vkEnumerateInstanceExtensionProperties, rax

    invoke GetProcAddress, vulkan_module, "vkGetInstanceProcAddr"
    AssertNotEq rax, 0
    mov vkGetInstanceProcAddr, rax

    invoke GetProcAddress, vulkan_module, "vkCreateWin32SurfaceKHR"
    AssertNotEq rax, 0
    mov vkCreateWin32SurfaceKHR, rax

    invoke GetProcAddress, vulkan_module, "vkEnumeratePhysicalDevices"
    AssertNotEq rax, 0
    mov vkEnumeratePhysicalDevices, rax

    invoke GetProcAddress, vulkan_module, "vkGetPhysicalDeviceProperties"
    AssertNotEq rax, 0
    mov vkGetPhysicalDeviceProperties, rax

    invoke GetProcAddress, vulkan_module, "vkGetPhysicalDeviceQueueFamilyProperties"
    AssertNotEq rax, 0
    mov vkGetPhysicalDeviceQueueFamilyProperties, rax

    invoke GetProcAddress, vulkan_module, "vkEnumerateDeviceExtensionProperties"
    AssertNotEq rax, 0
    mov vkEnumerateDeviceExtensionProperties, rax

    invoke GetProcAddress, vulkan_module, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR"
    AssertNotEq rax, 0
    mov vkGetPhysicalDeviceSurfaceCapabilitiesKHR, rax

    invoke GetProcAddress, vulkan_module, "vkGetPhysicalDeviceSurfaceFormatsKHR"
    AssertNotEq rax, 0
    mov vkGetPhysicalDeviceSurfaceFormatsKHR, rax

    invoke GetProcAddress, vulkan_module, "vkGetPhysicalDeviceSurfacePresentModesKHR"
    AssertNotEq rax, 0
    mov vkGetPhysicalDeviceSurfacePresentModesKHR, rax

    invoke GetProcAddress, vulkan_module, "vkCreateDevice"
    AssertNotEq rax, 0
    mov vkCreateDevice, rax

    invoke GetProcAddress, vulkan_module, "vkCreateSwapchainKHR"
    AssertNotEq rax, 0
    mov vkCreateSwapchainKHR, rax

    invoke GetProcAddress, vulkan_module, "vkGetSwapchainImagesKHR"
    AssertNotEq rax, 0
    mov vkGetSwapchainImagesKHR, rax

    invoke GetProcAddress, vulkan_module, "vkCreateImageView"
    AssertNotEq rax, 0
    mov vkCreateImageView, rax

    invoke GetProcAddress, vulkan_module, "vkCreateRenderPass"
    AssertNotEq rax, 0
    mov vkCreateRenderPass, rax

    invoke GetProcAddress, vulkan_module, "vkCreateShaderModule"
    AssertNotEq rax, 0
    mov vkCreateShaderModule, rax


    invoke GetProcAddress, vulkan_module, "vkCreatePipelineLayout"
    AssertNotEq rax, 0
    mov vkCreatePipelineLayout, rax

    invoke GetProcAddress, vulkan_module, "vkCreateGraphicsPipelines"
    AssertNotEq rax, 0
    mov vkCreateGraphicsPipelines, rax

    invoke GetProcAddress, vulkan_module, "vkCreateFramebuffer"
    AssertNotEq rax, 0
    mov vkCreateFramebuffer, rax

    invoke GetProcAddress, vulkan_module, "vkCreateCommandPool"
    AssertNotEq rax, 0
    mov vkCreateCommandPool, rax

    invoke GetProcAddress, vulkan_module, "vkAllocateCommandBuffers"
    AssertNotEq rax, 0
    mov vkAllocateCommandBuffers, rax

    invoke GetProcAddress, vulkan_module, "vkCreateSemaphore"
    AssertNotEq rax, 0
    mov vkCreateSemaphore, rax

    invoke GetProcAddress, vulkan_module, "vkCreateFence"
    AssertNotEq rax, 0
    mov vkCreateFence, rax

    invoke GetProcAddress, vulkan_module, "vkBeginCommandBuffer"
    AssertNotEq rax, 0
    mov vkBeginCommandBuffer, rax

    invoke GetProcAddress, vulkan_module, "vkCmdBeginRenderPass"
    AssertNotEq rax, 0
    mov vkCmdBeginRenderPass, rax

    invoke GetProcAddress, vulkan_module, "vkCmdBindPipeline"
    AssertNotEq rax, 0
    mov vkCmdBindPipeline, rax

    invoke GetProcAddress, vulkan_module, "vkCmdSetViewport"
    AssertNotEq rax, 0
    mov vkCmdSetViewport, rax

    invoke GetProcAddress, vulkan_module, "vkCmdSetScissor"
    AssertNotEq rax, 0
    mov vkCmdSetScissor, rax

    invoke GetProcAddress, vulkan_module, "vkCmdDraw"
    AssertNotEq rax, 0
    mov vkCmdDraw, rax

    invoke GetProcAddress, vulkan_module, "vkCmdEndRenderPass"
    AssertNotEq rax, 0
    mov vkCmdEndRenderPass, rax

    invoke GetProcAddress, vulkan_module, "vkEndCommandBuffer"
    AssertNotEq rax, 0
    mov vkEndCommandBuffer, rax

    invoke GetProcAddress, vulkan_module, "vkWaitForFences"
    AssertNotEq rax, 0
    mov vkWaitForFences, rax

    invoke GetProcAddress, vulkan_module, "vkResetFences"
    AssertNotEq rax, 0
    mov vkResetFences, rax

    invoke GetProcAddress, vulkan_module, "vkAcquireNextImageKHR"
    AssertNotEq rax, 0
    mov vkAcquireNextImageKHR, rax

    invoke GetProcAddress, vulkan_module, "vkResetCommandBuffer"
    AssertNotEq rax, 0
    mov vkResetCommandBuffer, rax

    invoke GetProcAddress, vulkan_module, "vkQueueSubmit"
    AssertNotEq rax, 0
    mov vkQueueSubmit, rax

    invoke GetProcAddress, vulkan_module, "vkQueuePresentKHR"
    AssertNotEq rax, 0
    mov vkQueuePresentKHR, rax

    invoke  GetProcAddress, vulkan_module, "vkGetDeviceQueue"
    AssertNotEq rax, 0
    mov vkGetDeviceQueue, rax

    ret
VulkanLoad endp

align 16
VulkanLoadExt proc
    invoke vkGetInstanceProcAddr, g_instance, "vkCreateDebugReportCallbackEXT"
    ; AssertNotEq rax, 0
    mov vkCreateDebugReportCallbackEXT, rax

    invoke vkGetInstanceProcAddr, g_instance, "vkDestroyDebugReportCallbackEXT"
    ; AssertNotEq rax, 0
    mov vkDestroyDebugReportCallbackEXT, rax

    invoke vkGetInstanceProcAddr, g_instance, "vkDebugReportMessageEXT"
    ; AssertNotEq rax, 0
    mov vkDebugReportMessageEXT, rax

    invoke vkGetInstanceProcAddr, g_instance, "vkCreateDebugUtilsMessengerEXT"
    AssertNotEq rax, 0
    mov vkCreateDebugUtilsMessengerEXT, rax

    invoke vkGetInstanceProcAddr, g_instance, "vkGetPhysicalDeviceSurfaceSupportKHR"
    AssertNotEq rax, 0
    mov vkGetPhysicalDeviceSurfaceSupportKHR, rax


    ret
VulkanLoadExt endp

align 16
WindowProc proc hWin:QWORD,uMsg:QWORD,wParam:QWORD,lParam:QWORD
    cmp uMsg, WM_PAINT
    je OnPaint

    cmp uMsg, WM_CLOSE
    je OnClose

    cmp uMsg, WM_CREATE
    je OnCreate

    cmp uMsg, WM_SIZE
    je OnSize

    cmp uMsg, WM_DESTROY
    je OnDestroy

    invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

    OnPaint:
        ; DebugPrint paint_phrase
        ret
    OnClose:
        invoke SendMessage, hWin, WM_DESTROY, 0, 0
        invoke PostQuitMessage, 0
        ret
    OnCreate:
        xor rax, rax
        ret
    OnSize:
        ret
    OnDestroy:
        ; DebugPrint close_phrase
        invoke PostQuitMessage, 0
        ret
    ret
WindowProc endp

align 16
MessageLoopProcess proc
    LOCAL msg    :MSG
    LOCAL pmsg   :QWORD

    mov pmsg, ptr$(msg)
    jmp gmsg

  mloop:
    invoke TranslateMessage,pmsg
    invoke DispatchMessage,pmsg
    call DrawFrame_Execute
  gmsg:
    test rax, rv(GetMessage,pmsg,0,0,0)     ; loop until GetMessage returns zero
    jnz mloop
    ret
MessageLoopProcess endp

align 16
arenaTest proc
    mov rcx, 32
    call memoryIsPowerOfTwo
    AssertEq rax, 1
    mov rcx, 33
    call memoryIsPowerOfTwo
    AssertEq rax, 0

    invoke arenaPush, ADDR arena, sizeof qword * 24, 8
    xor rcx, rcx
    loop_arr_00000:
        mov rdx, 0DEADBEEFCAFEBABEh
        mov [rax + rcx * 8], rdx
        inc rcx
        cmp rcx, 24
        jl loop_arr_00000
    invoke arenaSetPos, ADDR arena, pos

    invoke arenaPush, ADDR arena, 12, 8
    xor rcx, rcx
    loop_arr_00001:
        mov rdx, 0CAFEBABEF00DB105h
        mov [rax + rcx * 8], rdx
        inc rcx
        cmp rcx, 12
        jl loop_arr_00001
    invoke arenaSetPos, ADDR arena, pos

    arenaPushArray ADDR arena, Payload, 16, 8
    mov rsi, rax
    xor rcx, rcx
    mov r8, sizeof Payload
    mov r9, 0DEADFEEDBABE5EEDh
    loop_arr_00002:
        mov rax, rcx
        mul r8
        mov [rsi.Payload.tag + rax], r9
        mov [rsi.Payload.id + rax], r9b
        inc rcx
        cmp rcx, 16
        jl loop_arr_00002
    invoke arenaSetPos, ADDR arena, pos

    arenaPushArray ADDR arena, Payload, 16, 8
    mov rsi, rax
    xor rcx, rcx
    mov r8, sizeof Payload
    mov r9, 0DEFE0000BAAD0000h
    loop_arr_00003:
        mov [rsi.Payload.tag], r9
        mov [rsi.Payload.id], cl
        add rsi, r8
        inc rcx
        cmp rcx, 16
        jl loop_arr_00003
    invoke arenaSetPos, ADDR arena, pos

    mov rax, 0DEADBEEFCAFEBABEh
    mov al, 10
    arenaPushArrayZero ADDR arena, VkImage, al, 8
    ; do work
    invoke arenaSetPos, ADDR arena, pos

    ;;;; ; arenaPushArray ADDR arena, qword, 1000h, 8
    ;;;; invoke arenaPush, ADDR arena, sizeof qword * 1000h, 8
    ;;;; mov rsi, rax
    ;;;; xor rcx, rcx
    ;;;; mov r8, sizeof qword
    ;;;; mov r9, 0DEFEDEFEDEFEDEFEh
    ;;;; loop_arr_00004:
    ;;;;     mov [rsi], r9
    ;;;;     add rsi, r8
    ;;;;     inc rcx
    ;;;;     cmp rcx, 1000h
    ;;;;     jl loop_arr_00004
    ;;;; ; invoke arenaSetPos, ADDR arena, pos
    ;;;; invoke arenaPush, ADDR arena, sizeof qword * 1000h, 8
    ;;;; ; arenaPushArray ADDR arena, qword, 1000h, 8
    ;;;; mov rsi, rax
    ;;;; xor rcx, rcx
    ;;;; mov r8, sizeof qword
    ;;;; mov r9, 0DEFEDEFEDEFEDEFEh
    ;;;; loop_arr_00005:
    ;;;;     mov [rsi], r9
    ;;;;     add rsi, r8
    ;;;;     inc rcx
    ;;;;     cmp rcx, 1000h
    ;;;;     jl loop_arr_00005

    xor rax, rax
    ret
arenaTest endp

; rcx = pointer to string1 (const char*)
; rdx = pointer to string2 (const char*)
; returns:
;   rax = 0 if equal
;   rax < 0 if string1 < string2
;   rax > 0 if string1 > string2
strcmp64 PROC
        SaveRegisters
        movzx   r8d, BYTE PTR [rcx]
        xor     r9d, r9d
        cmp     r8b, BYTE PTR [rdx]
        jne     SHORT $LN10@my_strcmp
        mov     r10, rcx
        mov     rax, rdx
        sub     r10, rdx
$LL2@my_strcmp:
        test    r8b, r8b
        je      SHORT $LN10@my_strcmp
        cmp     BYTE PTR [rax], 0
        je      SHORT $LN10@my_strcmp
        movzx   r8d, BYTE PTR [r10+rax+1]
        inc     rax
        inc     r9d
        cmp     r8b, BYTE PTR [rax]
        je      SHORT $LL2@my_strcmp
$LN10@my_strcmp:
        movsxd  rax, r9d
        movsx   r8d, BYTE PTR [rax+rcx]
        add     rax, rdx
        test    r8b, r8b
        jne     SHORT $LN13@my_strcmp
        cmp     BYTE PTR [rax], r8b
        jne     SHORT $LN13@my_strcmp
        xor     eax, eax
        ret     0
$LN13@my_strcmp:
        movsx   ecx, BYTE PTR [rax]
        mov     eax, r8d
        sub     eax, ecx
        RestoreRegisters
        ret     0
strcmp64 ENDP

; VKAPI_ATTR 
; VkBool32 
; VKAPI_CALL 
; debugCallback(
; VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity, rcx
; VkDebugUtilsMessageTypeFlagsEXT messageType, rdx
; const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData, r8
; void* pUserData), r9
align 16
VulkanDebugReportCallback proc
    push rbx
    sub rsp, 28h
    lea rbx, [r8 + 0D0h] ; hack!
    lea rcx, vulkan_phrase
    invoke OutputDebugString
    mov rcx, rbx
    invoke OutputDebugString
    lea rcx, new_line
    invoke OutputDebugString
    add rsp, 28h
    pop rbx
    xor rax, rax
    ret
VulkanDebugReportCallback endp

align 16
findQueueFamilies proc; rcx:qword:physical_device, rdx:qword:&indices-> rax
    push rbp
    mov rbp, rsp
    sub rsp, 32
    SaveRegisters

    mov r13, rcx ; device
    mov r14, rdx ; indices reference

    ; mov rcx, physical_devices[i]
    ; xor r8, r8
    invoke vkGetPhysicalDeviceQueueFamilyProperties, rcx, ADDR queue_family_count, 0

    ; mov rax, arena.Arena.cursor
    ; mov pos, rax
    arenaGetPos arena, pos

    xor rdx, rdx
    mov edx, sizeof VkQueueFamilyProperties
    mov eax, queue_family_count
    mul edx
    invoke arenaPushZero, ADDR arena, rax, alignofqword
    AssertNotEq rax, 0
    mov queue_family_properties, rax

    ; save pos
    ; mov pos, rax

    invoke vkGetPhysicalDeviceQueueFamilyProperties, r13, ADDR queue_family_count, rax

    ; mov rdx, r14

    xor rdx, rdx; graphics_family_has_value
    xor r8, r8; present_family_has_value
    xor rax, rax;
    xor rbx, rbx;

    xor rdi, rdi
    mov rsi, queue_family_properties
    queue_family_properties_loop_00000001:
        mov eax, [rsi].VkQueueFamilyProperties.queueFlags
        mov rbx, VK_QUEUE_GRAPHICS_BIT
        and rax, rbx
        cmp rax, false
        je has_not_queue_graphics_bit
            mov [r14].QueueFamilyIndices.graphicsFamily, edi
            mov rdx, true
        has_not_queue_graphics_bit:
        invoke vkGetPhysicalDeviceSurfaceSupportKHR, r13, rdi, g_surface, ADDR present_support
        mov r10d, present_support; present_family_has_value
        cmp r10, false
        je has_not_present
            mov [r14].QueueFamilyIndices.presentFamily, edi
            mov r8, true; graphics_family_has_value
        has_not_present:
        and r8, r10; graphics_family_has_value && present_family_has_value
        cmp r8, false
        je has_neither
            mov rbx, true
            jmp found_it
        has_neither:

        add rsi, sizeof VkQueueFamilyProperties
        inc edi
        cmp edi, queue_family_count
        jl queue_family_properties_loop_00000001

    found_it:
    ; copy found indices outwards (decided to make a global variable)
    ; mov findQueueFamilies_indices:QueueFamilyIndices (this var wont be required for now)
    ; free
    invoke arenaSetPos, ADDR arena, pos
    xchg rax, rbx

    RestoreRegisters
    add rsp, 32
    pop rbp
    ret
findQueueFamilies endp

checkDeviceExtensionSupport proc
    push rbp
    mov rbp, rsp
    sub rsp, 32
    SaveRegisters

    mov rcx, g_physical_device
    ; mov rbx, rcx
    invoke vkEnumerateDeviceExtensionProperties, rcx, 0, ADDR device_extension_count, 0

    mov rax, arena.Arena.cursor
    mov pos, rax

    xor rdx, rdx
    mov edx, sizeof VkExtensionProperties
    mov rax, device_extension_count
    mul edx
    invoke arenaPushZero, ADDR arena, rax, alignofqword
    AssertNotEq rax, 0
    mov device_available_extensions, rax
    ; mov pos, rax

    ; mov rcx, rbx
    mov rcx, g_physical_device
    invoke vkEnumerateDeviceExtensionProperties, rcx, 0, ADDR device_extension_count, device_available_extensions
    AssertEq rax, VK_SUCCESS

    xor rbx, rbx; layer_found:bool
    xor rsi, rsi; i
    xor rdi, rdi
    xor r14, r14
    lea r12, vk_khr_swapchain_extension_name
    device_extension_check_loop_00000001:
        mov rax, device_available_extensions
        lea r13, [rax.VkExtensionProperties.extensionName + rdi]
        mov rcx, r13
        mov rdx, r12
        call strcmp64
        cmp rax, 0
        jne not_match
            mov rbx, true
            jmp found_device_extension_support
        not_match:

        add rdi, sizeof VkExtensionProperties
        inc rsi
        cmp rsi, device_extension_count
        jl device_extension_check_loop_00000001

    found_device_extension_support:
    invoke arenaSetPos, ADDR arena, pos

    mov rax, rbx

    RestoreRegisters
    add rsp, 32
    pop rbp
    ret
checkDeviceExtensionSupport endp

align 16
querySwapchainSupport proc; rcx:device
    push rbp
    mov rbp, rsp
    sub rsp, 32
    SaveRegisters

    mov rbx, rcx
    invoke vkGetPhysicalDeviceSurfaceCapabilitiesKHR, rcx, g_surface, ADDR device_swapchain_support.SwapchainSupportDetails.capabilities

    ; formats
    mov rcx, rbx
    invoke vkGetPhysicalDeviceSurfaceFormatsKHR, rcx, g_surface, ADDR device_swapchain_support.SwapchainSupportDetails.formats_count, 0

    mov rax, arena.Arena.cursor
    mov pos, rax

    xor rdx, rdx
    mov edx, sizeof VkSurfaceFormatKHR
    mov eax, device_swapchain_support.SwapchainSupportDetails.formats_count
    mul edx
    invoke arenaPushZero, ADDR arena, rax, alignofqword
    AssertNotEq rax, 0
    mov device_swapchain_support.SwapchainSupportDetails.formats, rax

    mov rcx, rbx
    invoke vkGetPhysicalDeviceSurfaceFormatsKHR, rcx, g_surface, ADDR device_swapchain_support.SwapchainSupportDetails.formats_count, device_swapchain_support.SwapchainSupportDetails.formats

    ; present modes
    mov rcx, rbx
    invoke vkGetPhysicalDeviceSurfacePresentModesKHR, rcx, g_surface, ADDR device_swapchain_support.SwapchainSupportDetails.present_modes_count, 0

    xor rdx, rdx
    mov edx, sizeof VkPresentModeKHR
    mov eax, device_swapchain_support.SwapchainSupportDetails.present_modes_count
    mul edx
    invoke arenaPushZero, ADDR arena, rax, alignofqword
    AssertNotEq rax, 0
    mov device_swapchain_support.SwapchainSupportDetails.present_modes, rax
    ; mov pos, rax ; keep old pos to nuke both allocs

    mov rcx, rbx
    invoke vkGetPhysicalDeviceSurfacePresentModesKHR, rcx, g_surface, ADDR device_swapchain_support.SwapchainSupportDetails.present_modes_count, device_swapchain_support.SwapchainSupportDetails.present_modes

    RestoreRegisters
    add rsp, 32
    pop rbp
    ret
querySwapchainSupport endp

align 16
isDeviceSuitable proc; rcx: physical_device
    push rbp
    mov rbp, rsp
    sub rsp, 32
    SaveRegisters

    mov rbx, rcx
    invoke vkGetPhysicalDeviceProperties, rcx, ADDR device_properties

    lea rcx, device_properties.VkPhysicalDeviceProperties.deviceName
    call OutputDebugString
    mov rcx, rbx

    ; cannot really print the value of this without some special print function...
    ; lea rcx, device_properties.VkPhysicalDeviceProperties.deviceType
    ; call OutputDebugString
    ; mov rcx, rbx

    ; skip if GPU is not VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
    mov esi, device_properties.VkPhysicalDeviceProperties.deviceType
    cmp esi, VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
    jne device_is_suitable_false

    mov rcx, g_physical_device
    invoke findQueueFamilies, rcx, ADDR indices
    mov device_queue_families_has_value, al

    mov rcx, g_physical_device
    invoke checkDeviceExtensionSupport, rcx
    mov device_extensions_supported, al

    mov rbx, g_physical_device
    cmp device_extensions_supported, 0
    je device_extensions_supported_false
        ; mov rcx, device
        mov rcx, g_physical_device
        call querySwapchainSupport

        mov eax, device_swapchain_support.SwapchainSupportDetails.formats_count
        test eax, eax
        jz swapchain_condition_false

        mov eax, device_swapchain_support.SwapchainSupportDetails.present_modes_count
        test eax, eax
        jz swapchain_condition_false

        swapchain_condition_true:
            mov device_swapchain_adequate, true
            jmp swapchain_condition_continue

        swapchain_condition_false:
            mov device_swapchain_adequate, false

        swapchain_condition_continue:

        invoke arenaSetPos, ADDR arena, pos; dealloc arrays
    device_extensions_supported_false:

    ; rax = device_queue_families_has_value  && device_extensions_supported && device_swapchain_adequate

    mov al, device_queue_families_has_value
        test al, al
        jz device_is_suitable_false
    mov al, device_extensions_supported
        test al, al
        jz device_is_suitable_false
    mov al, device_swapchain_adequate
        test al, al
        jz device_is_suitable_false

    device_is_suitable:
        mov rax, true
        jmp device_is_suitable_continue
    device_is_suitable_false:
        mov rax, false
    device_is_suitable_continue:

    ; write device out anyway but always check rax for true/false
    mov g_physical_device, rbx

    RestoreRegisters
    add rsp, 32
    pop rbp
    ret
isDeviceSuitable endp

align 16
main proc
    lea rcx, arena
    call arenaInit
    mov pos, rax
    call arenaTest

    mov window_instance, rv(GetModuleHandle, 0)

    mov rcx, StdOutHandle
    call GetStdHandle
    invoke WriteFile, rax, ADDR outputmessage, outputmessagelength, 0

    mov window_class.cbSize, sizeof WNDCLASSEX
    xor rcx, rcx
    mov rcx, CS_HREDRAW or CS_VREDRAW
    mov window_class.style, ecx
    lea rcx, WindowProc
    mov window_class.lpfnWndProc, rcx
    mov rcx, window_instance
    mov window_class.hInstance, rcx
    lea rcx, window_class_name
    mov window_class.lpszClassName, rcx
    ; movlea window_class.lpszClassName, window_class_name

    invoke RegisterClassEx, ADDR window_class
    AssertNotEq rax, 0

    invoke CreateWindowEx, 0, ADDR window_class_name, ADDR window_title, WS_OVERLAPPEDWINDOW or WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, 800, 640, 0, 0, window_instance, 0
    AssertNotEq rax, 0
    mov window_handle, rax

    call VulkanLoad

    ; instance layers
    ;---------------------------------------------------------------------------------------------------
    invoke vkEnumerateInstanceLayerProperties, ADDR layers_count, 0
    AssertEq rax, VK_SUCCESS

    mov eax, layers_count
    arenaPushArrayZero ADDR arena, VkLayerProperties, eax, 4
    AssertNotEq rax, 0

    mov layers_available, rax
    invoke vkEnumerateInstanceLayerProperties, ADDR layers_count, rax

    mov rsi, layers_available
    lea rdi, layer_string_0
    xor r13, r13
    mov r12, sizeof VkLayerProperties
    loop_validation_layer_find_00000000:
        lea rcx, [rsi.VkLayerProperties.layerName]
        mov rdx, rdi
        call strcmp64
        cmp rax, 0
        jne validation_label_not_found 
        mov found_validation, 1
        lea rdi, layer_string_0
        validation_label_not_found:

        add rsi, r12
        inc r13
        cmp r13d, layers_count
        jl loop_validation_layer_find_00000000
    invoke arenaSetPos, ADDR arena, pos

    ; instance extension_string_array
    invoke vkEnumerateInstanceExtensionProperties, 0, ADDR extension_count, 0
    AssertEq rax, VK_SUCCESS
    mov edx, sizeof VkExtensionProperties 
    xor rax, rax
    mov rax, extension_count
    mul edx
    invoke arenaPushZero, ADDR arena, rax, 4
    AssertNotEq rax, 0
    ; invoke arenaPush, ADDR arena, rax, 4
    mov extensions_available, rax
    invoke vkEnumerateInstanceExtensionProperties, 0, ADDR extension_count, extensions_available
    AssertEq rax, VK_SUCCESS

    ExtensionValidationCheck 0
    ExtensionValidationCheck 1
    ExtensionValidationCheck 2
    ; include asmgen.asm
    invoke arenaSetPos, ADDR arena, pos

    mov al, found_extensions
    AssertEq al, extension_string_array_count

    ; create instance
    ;---------------------------------------------------------------------------------------------------
    mov application_info._sType, VK_STRUCTURE_TYPE_APPLICATION_INFO
    lea rcx, application_name
        mov application_info.pApplicationName, rcx
    mov application_info.applicationVersion, application_api_version
    mov application_info.apiVersion, application_api_version
    mov application_info.engineVersion, 1

    mov instance_info._sType, VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
    lea rcx, application_info
        mov instance_info.pApplicationInfo, rcx
    mov instance_info.enabledLayerCount, 1
    lea rcx, layers
        mov instance_info.ppEnabledLayerNames, rcx
    ; debuginfo
    mov debug_callback_create_info._sType, VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
    mov debug_callback_create_info.messageSeverity, VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT
    mov debug_callback_create_info.messageType, VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT
    lea rcx, VulkanDebugReportCallback
        mov debug_callback_create_info.pfnUserCallback, rcx
    ; debuginfo
    mov instance_info.enabledExtensionCount, 3
    lea rcx, extension_string_array
        mov instance_info.ppEnabledExtensionNames, rcx
    lea rcx, debug_callback_create_info
        mov instance_info.pNext, rcx

    invoke vkCreateInstance, ADDR instance_info, 0, ADDR g_instance
    AssertEq rax, VK_SUCCESS

    call VulkanLoadExt

    ; debuginfo
    ; mov debug_callback_create_info_2._sType, VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
    ; mov debug_callback_create_info_2.messageSeverity, VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT
    ; mov debug_callback_create_info_2.messageType, VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT or VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT
    ; lea rcx, VulkanDebugReportCallback
    ;     mov debug_callback_create_info_2.pfnUserCallback, rcx
    ; debuginfo
    invoke vkCreateDebugUtilsMessengerEXT, g_instance, ADDR debug_callback_create_info, 0, ADDR debug_messenger
    AssertEq rax, VK_SUCCESS

    mov surface_create_info._sType, VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR
    mov rcx, window_instance
    mov surface_create_info.hinstance, rcx
    mov rcx,  window_handle
    mov surface_create_info.hwnd, rcx

    invoke vkCreateWin32SurfaceKHR, g_instance, ADDR surface_create_info, 0, ADDR g_surface
    AssertEq rax, VK_SUCCESS

    ; physical devices
    ;---------------------------------------------------------------------------------------------------
    invoke vkEnumeratePhysicalDevices, g_instance, ADDR physical_device_count, 0
    mov rax, physical_device_count
    AssertNotEq rax, 0

    mov edx, sizeof qword; sizeof typedef VkPhysicalDevice pointer
    xor rax, rax
    mov rax, physical_device_count
    mul edx
    invoke arenaPushZero, ADDR arena, rax, alignofqword
    AssertNotEq rax, 0
    mov physical_devices, rax

    invoke vkEnumeratePhysicalDevices, g_instance, ADDR physical_device_count, physical_devices
    AssertEq rax, VK_SUCCESS

    ;;;; mov rax, physical_devices
    ;;;; mov rcx, [rax]
    ;;;; lea rdx, queue_family_count
    ;;;; xor r8, r8
    ;;;; call vkGetPhysicalDeviceQueueFamilyProperties

    mov rax, pos
    xor rsi, rsi
    is_device_suitable_loop_00000000:
        ; SaveRegisters
        mov rax, physical_devices
        mov rcx, [rax + sizeof qword * rsi]
        invoke isDeviceSuitable, rcx
        ; RestoreRegisters
        cmp rax, false
        jz try_next_device
            jmp device_found
        try_next_device:
        inc rsi
        cmp rsi, physical_device_count
        jl is_device_suitable_loop_00000000
    device_found:
    AssertNotEq g_physical_device, 0

    invoke arenaSetPos, ADDR arena, pos

    call SetupLogicalDevice_Execute
    call SetupSwapchain_Execute
    call SetupImageViews_Execute
    call SetupRenderPass_Execute
    call SetupGraphicsPipeline_Execute
    call SetupFramebuffers_Execute
    call SetupCommandPool_Execute
    call SetupCommandBuffer_Execute
    call SetupSyncObjects_Execute

    call MessageLoopProcess

    ; xor rax, rax
    invoke ExitProcess, 0
    ret
main endp
end
