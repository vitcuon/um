#include "Esp/Includes.h"
#include <Foundation/Foundation.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <mach/vm_page_size.h>
#include <unistd.h>
#include <array>
#include <deque>
#include <map>
#include <vector>
#import "IMGUI/Il2cpp.h"
// #import "Security/il2cpp.h"
#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "IMGUI/stb_image.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "Utils/Macros.h"
#import "Utils/hack/Function.h"
//#include "font.h"
#import "IMGUI/imgui_additional.h"
#import "IMGUI/bdvt.h"
#import "IMGUI/imgui.h"
#import "IMGUI/Honkai.h"
#import "mahoa.h"
#import "hok/dobby.h"
#import "hok/MonoString.h"
#import "hook/hook.h"
#include <CoreFoundation/CoreFoundation.h>
#include "Utils/hack/Vector2.h"
#import "Utils/hack/Vector3.h"
#include "Utils/hack/VInt3.h"
#import "IMAGE.h"
#include <limits>
#include "Utils/Quaternion.h"
#import <UIKit/UIKit.h>
#include <chrono>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>

#include "Custom/Watermark.h"
#include "Custom/Settings.h"
#include "Fonts/fire.h"
#include "Fonts/Iconcpp.h"
#include "Fonts/Icon.h"
#import "AntiHook/NemG.h"
#define STATIC_HOOK_CODEPAGE_SIZE PAGE_SIZE
#define STATIC_HOOK_DATAPAGE_SIZE PAGE_SIZE

typedef struct {
  uint64_t hook_vaddr;
  uint64_t hook_size;
  uint64_t code_vaddr;
  uint64_t code_size;

  uint64_t patched_vaddr;
  uint64_t original_vaddr;
  uint64_t instrument_vaddr;

  uint64_t patch_size;
  uint64_t patch_hash;

  void *target_replace;
  void *instrument_handler;
} StaticInlineHookBlock;

int dobby_create_instrument_bridge(void *targetData);

bool dobby_static_inline_hook(StaticInlineHookBlock *hookBlock, StaticInlineHookBlock *hookBlockRVA, uint64_t funcRVA,
                              void *funcData, uint64_t targetRVA, void *targetData, uint64_t InstrumentBridgeRVA,
                              void *patchBytes, int patchSize);


uint64_t va2rva(struct mach_header_64* header, uint64_t va)
{
    uint64_t rva = va;
    
    uint64_t header_vaddr = -1;
    struct load_command* lc = (struct load_command*)((UInt64)header + sizeof(*header));
    for (int i = 0; i < header->ncmds; i++) {
        
        if (lc->cmd == LC_SEGMENT_64)
        {
            struct segment_command_64 * seg = (struct segment_command_64 *)lc;
            
            if(seg->fileoff==0 && seg->filesize>0)
            {
                if(header_vaddr != -1) {
                    return 0;
                }
                header_vaddr = seg->vmaddr;
            }
        }
        
        lc = (struct load_command *) ((char *)lc + lc->cmdsize);
    }
    
    if(header_vaddr != -1) {
        rva -= header_vaddr;
    }
    
    return rva;
}

void* rva2data(struct mach_header_64* header, uint64_t rva)
{
    uint64_t header_vaddr = -1;
    struct load_command* lc = (struct load_command*)((UInt64)header + sizeof(*header));
    for (int i = 0; i < header->ncmds; i++) {
        
        if (lc->cmd == LC_SEGMENT_64)
        {
            struct segment_command_64 * seg = (struct segment_command_64 *)lc;
            
            if(seg->fileoff==0 && seg->filesize>0)
            {
                if(header_vaddr != -1) {
                    return NULL;
                }
                header_vaddr = seg->vmaddr;
            }
        }
        
        lc = (struct load_command *) ((char *)lc + lc->cmdsize);
    }
    
    if(header_vaddr != -1) {
        rva += header_vaddr;
    }
    
    lc = (struct load_command*)((UInt64)header + sizeof(*header));
    for (int i = 0; i < header->ncmds; i++) {

        if (lc->cmd == LC_SEGMENT_64)
        {
            struct segment_command_64 * seg = (struct segment_command_64 *) lc;
            
            uint64_t seg_vmaddr_start = seg->vmaddr;
            uint64_t seg_vmaddr_end   = seg_vmaddr_start + seg->vmsize;
            if ((uint64_t)rva >= seg_vmaddr_start && (uint64_t)rva < seg_vmaddr_end)
            {
              uint64_t offset = (uint64_t)rva - seg_vmaddr_start;
              if (offset > seg->filesize) {
                return NULL;
              }
              return (void*)((uint64_t)header + seg->fileoff + offset);
            }
        }

        lc = (struct load_command *) ((char *)lc + lc->cmdsize);
    }
    
    return NULL;
}

NSMutableData* load_macho_data(NSString* path)
{
    NSMutableData* macho = [NSMutableData dataWithContentsOfFile:path];
    if(!macho) return nil;
    
    UInt32 magic = *(uint32_t*)macho.mutableBytes;
    if(magic==FAT_CIGAM)
    {
        struct fat_header* fathdr = (struct fat_header*)macho.mutableBytes;
        struct fat_arch* archdr = (struct fat_arch*)((UInt64)fathdr + sizeof(*fathdr));
        if(NXSwapLong(fathdr->nfat_arch) != 1) {
            return nil;
        }
        
        if(NXSwapLong(archdr->cputype) != CPU_TYPE_ARM64 || archdr->cpusubtype!=0) {
            return nil;
        }
        macho = [NSMutableData dataWithData:
                 [macho subdataWithRange:NSMakeRange(NXSwapLong(archdr->offset), NXSwapLong(archdr->size))]];
        
    } else if(magic==FAT_CIGAM_64)
    {
        struct fat_header* fathdr = (struct fat_header*)macho.mutableBytes;
        struct fat_arch_64* archdr = (struct fat_arch_64*)((UInt64)fathdr + sizeof(*fathdr));
        if(NXSwapLong(fathdr->nfat_arch) != 1) {
            return nil;
        }
        
        if(NXSwapLong(archdr->cputype) != CPU_TYPE_ARM64 || archdr->cpusubtype!=0) {
            return nil;
        }
        macho = [NSMutableData dataWithData:
                 [macho subdataWithRange:NSMakeRange(NXSwapLong(archdr->offset), NXSwapLong(archdr->size))]];
        
    } else if(magic != MH_MAGIC_64) {
        return nil;
    }
    
    return macho;
}

NSMutableData* add_hook_section(NSMutableData* macho)
{
    struct mach_header_64* header = (struct mach_header_64*)macho.mutableBytes;
    
    uint64_t vm_end = 0;
    uint64_t min_section_offset = 0;
    struct segment_command_64* linkedit_seg = NULL;
    
    struct load_command* lc = (struct load_command*)((UInt64)header + sizeof(*header));
    for (int i = 0; i < header->ncmds; i++) {
        
        if (lc->cmd == LC_SEGMENT_64)
        {
            struct segment_command_64 * seg = (struct segment_command_64 *) lc;
            
            if(strcmp(seg->segname,SEG_LINKEDIT)==0)
                linkedit_seg = seg;
            else
            if(seg->vmsize && vm_end<(seg->vmaddr+seg->vmsize))
                vm_end = seg->vmaddr+seg->vmsize;
            
            struct section_64* sec = (struct section_64*)((uint64_t)seg+sizeof(*seg));
            for(int j=0; j<seg->nsects; j++)
            {
                
                if(min_section_offset < sec[j].offset)
                    min_section_offset = sec[j].offset;
            }
        }
        
        lc = (struct load_command *) ((char *)lc + lc->cmdsize);
    }
    
    if(!min_section_offset || !vm_end || !linkedit_seg) {
        return nil;
    }
    
    NSRange linkedit_range = NSMakeRange(linkedit_seg->fileoff, linkedit_seg->filesize);
    NSData* linkedit_data = [macho subdataWithRange:linkedit_range];
    [macho replaceBytesInRange:linkedit_range withBytes:nil length:0];
    
    
    struct segment_command_64 text_seg = {
        .cmd = LC_SEGMENT_64,
        .cmdsize=sizeof(struct segment_command_64)+sizeof(struct section_64),
        .segname = {"__HOOK_TEXT"},
        .vmaddr = vm_end,
        .vmsize = STATIC_HOOK_CODEPAGE_SIZE,
        .fileoff = macho.length,
        .filesize = STATIC_HOOK_CODEPAGE_SIZE,
        .maxprot = VM_PROT_READ|VM_PROT_EXECUTE,
        .initprot = VM_PROT_READ|VM_PROT_EXECUTE,
        .nsects = 1,
        .flags = 0
    };
    struct section_64 text_sec = {
        .segname = {"__HOOK_TEXT"},
        .sectname = {"__hook_text"},
        .addr = text_seg.vmaddr,
        .size = text_seg.vmsize,
        .offset = (uint32_t)text_seg.fileoff,
        .align = 0,
        .reloff = 0,
        .nreloc = 0,
        .flags = S_ATTR_PURE_INSTRUCTIONS|S_ATTR_SOME_INSTRUCTIONS,
        .reserved1 = 0, .reserved2 = 0, .reserved3 = 0
    };
    
    struct segment_command_64 data_seg = {
        .cmd = LC_SEGMENT_64,
        .cmdsize=sizeof(struct segment_command_64)+sizeof(struct section_64),
        .segname = {"__HOOK_DATA"},
        .vmaddr = text_seg.vmaddr+text_seg.vmsize,
        .vmsize = STATIC_HOOK_CODEPAGE_SIZE,
        .fileoff = text_seg.fileoff+text_seg.filesize,
        .filesize = STATIC_HOOK_CODEPAGE_SIZE,
        .maxprot = VM_PROT_READ|VM_PROT_WRITE,
        .initprot = VM_PROT_READ|VM_PROT_WRITE,
        .nsects = 1,
        .flags = 0
    };
    struct section_64 data_sec = {
        .segname = {"__HOOK_DATA"},
        .sectname = {"__hook_data"},
        .addr = data_seg.vmaddr,
        .size = data_seg.vmsize,
        .offset = (uint32_t)data_seg.fileoff,
        .align = 0,
        .reloff = 0,
        .nreloc = 0,
        .flags = 0,
        .reserved1 = 0, .reserved2 = 0, .reserved3 = 0
    };
    
    uint64_t linkedit_cmd_offset = (uint64_t)linkedit_seg - ((uint64_t)header+sizeof(*header));
    unsigned char* cmds = (unsigned char*)malloc(header->sizeofcmds);
    memcpy(cmds, (unsigned char*)header+sizeof(*header), header->sizeofcmds);
    unsigned char* patch = (unsigned char*)header +sizeof(*header) + linkedit_cmd_offset;
    
    memcpy(patch, &text_seg, sizeof(text_seg));
    patch += sizeof(text_seg);
    memcpy(patch, &text_sec, sizeof(text_sec));
    patch += sizeof(text_sec);

    memcpy(patch, &data_seg, sizeof(data_seg));
    patch += sizeof(data_seg);
    memcpy(patch, &data_sec, sizeof(data_sec));
    patch += sizeof(data_sec);
    
    memcpy(patch, cmds+linkedit_cmd_offset, header->sizeofcmds-linkedit_cmd_offset);
    
    linkedit_seg = (struct segment_command_64*)patch;
    
    header->ncmds += 2;
    header->sizeofcmds += text_seg.cmdsize + data_seg.cmdsize;
    
    linkedit_seg->fileoff = macho.length+text_seg.filesize+data_seg.filesize;
    linkedit_seg->vmaddr = vm_end+text_seg.vmsize+data_seg.vmsize;
    
    struct load_command *load_cmd = (struct load_command *)((uint64_t)header + sizeof(*header));
    for (int i = 0; i < header->ncmds;
         i++, load_cmd = (struct load_command *)((uint64_t)load_cmd + load_cmd->cmdsize))
    {
        uint64_t fixoffset = text_seg.filesize+data_seg.filesize;
        
      switch (load_cmd->cmd)
      {
          case LC_DYLD_INFO:
          case LC_DYLD_INFO_ONLY:
          {
            struct dyld_info_command *tmp = (struct dyld_info_command *)load_cmd;
            tmp->rebase_off += fixoffset;
            tmp->bind_off += fixoffset;
            if (tmp->weak_bind_off)
              tmp->weak_bind_off += fixoffset;
            if (tmp->lazy_bind_off)
              tmp->lazy_bind_off += fixoffset;
            if (tmp->export_off)
              tmp->export_off += fixoffset;
          } break;
              
          case LC_SYMTAB:
          {
            struct symtab_command *tmp = (struct symtab_command *)load_cmd;
            if (tmp->symoff)
              tmp->symoff += fixoffset;
            if (tmp->stroff)
              tmp->stroff += fixoffset;
          } break;
              
          case LC_DYSYMTAB:
          {
            struct dysymtab_command *tmp = (struct dysymtab_command *)load_cmd;
            if (tmp->tocoff)
              tmp->tocoff += fixoffset;
            if (tmp->modtaboff)
              tmp->modtaboff += fixoffset;
            if (tmp->extrefsymoff)
              tmp->extrefsymoff += fixoffset;
            if (tmp->indirectsymoff)
              tmp->indirectsymoff += fixoffset;
            if (tmp->extreloff)
              tmp->extreloff += fixoffset;
            if (tmp->locreloff)
              tmp->locreloff += fixoffset;
          } break;
              
          case LC_FUNCTION_STARTS:
          case LC_DATA_IN_CODE:
          case LC_CODE_SIGNATURE:
          case LC_SEGMENT_SPLIT_INFO:
          case LC_DYLIB_CODE_SIGN_DRS:
          case LC_LINKER_OPTIMIZATION_HINT:
          case LC_DYLD_EXPORTS_TRIE:
          case LC_DYLD_CHAINED_FIXUPS:
          {
            struct linkedit_data_command *tmp = (struct linkedit_data_command *)load_cmd;
            if (tmp->dataoff) tmp->dataoff += fixoffset;
          } break;
      }
    }
    
    if(min_section_offset < (sizeof(struct mach_header_64)+header->sizeofcmds)) {
        return nil;
    }
    
    unsigned char* codepage = (unsigned char*)malloc(text_seg.vmsize);
    memset(codepage, 0xFF, text_seg.vmsize);
    [macho appendBytes:codepage length:text_seg.vmsize];
    free(codepage);
    
    unsigned char* datapage = (unsigned char*)malloc(data_seg.vmsize);
    memset(datapage, 0, data_seg.vmsize);
    [macho appendBytes:datapage length:data_seg.vmsize];
    free(datapage);
    
    [macho appendData:linkedit_data];
    
    return macho;
}

bool hex2bytes(char* bytes, unsigned char* buffer)
{
    size_t len=strlen(bytes);
    for(int i=0; i<len; i++) {
        char _byte = bytes[i];
        if(_byte>='0' && _byte<='9')
            _byte -= '0';
        else if(_byte>='a' && _byte<='f')
            _byte -= 'a'-10;
        else if(_byte>='A' && _byte<='F')
            _byte -= 'A'-10;
        else
            return false;
        
        buffer[i/2] &= (i+1)%2 ? 0x0F : 0xF0;
        buffer[i/2] |= _byte << (((i+1)%2)*4);
        
    }
    return true;
}

uint64_t calc_patch_hash(uint64_t vaddr, char* patch)
{
    return [[[NSString stringWithUTF8String:patch] lowercaseString] hash] ^ vaddr;
}


NSString* StaticInlineHookPatch(char* machoPath, uint64_t vaddr, char* patch)
{
    static NSMutableDictionary* gStaticInlineHookMachO = [[NSMutableDictionary alloc] init];
    
    NSString* path = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:[NSString stringWithUTF8String:machoPath]];
        
    NSString* newPath = gStaticInlineHookMachO[path];
    
    NSMutableData* macho=nil;

    if(newPath) {
        macho = load_macho_data(newPath);
        if(!macho) return [NSString stringWithFormat:@"Không tìm thấy File(can't find file):\n Documents/static-inline-hook/%s", machoPath];
    } else {
        macho = load_macho_data(path);
        if(!macho) return [NSString stringWithFormat:@"Không thể đọc file(can't read file):\n.app/%s", machoPath];
    }
    
    uint32_t cryptid = 0;
    struct mach_header_64* header = NULL;
    struct segment_command_64* text_seg = NULL;
    struct segment_command_64* data_seg = NULL;
    
    while(true) {
        
        header = (struct mach_header_64*)macho.mutableBytes;
        
        struct load_command* lc = (struct load_command*)((UInt64)header + sizeof(*header));
        for (int i = 0; i < header->ncmds; i++) {
            if (lc->cmd == LC_SEGMENT_64) {
                struct segment_command_64 * seg = (struct segment_command_64 *) lc;
                if(strcmp(seg->segname,"__HOOK_TEXT")==0)
                    text_seg = seg;
                if(strcmp(seg->segname,"__HOOK_DATA")==0)
                    data_seg = seg;
            }
            if(lc->cmd == LC_ENCRYPTION_INFO_64) {
                struct encryption_info_command_64* info = (struct encryption_info_command_64*)lc;
                if(cryptid==0) cryptid = info->cryptid;
            }
            lc = (struct load_command *) ((char *)lc + lc->cmdsize);
        }
        
        if(text_seg && data_seg) {
            break;
        }
        
        macho = add_hook_section(macho);
        if(!macho) {
            return @"add_hook_section error!";
        }
    }
    
    if(cryptid != 0) {
        return @"Ứng dụng này không được giải mã!!\nthis app is not decrypted!";
    }
    
    if(!text_seg || !data_seg) {
        return @"Không thể phân tích tệp machO!\ncan not parse machO file!";
    }
    
    uint64_t funcRVA = vaddr & ~(4-1);
    void *funcData = rva2data(header, funcRVA);
    
    if(!funcData) {
        return @"Địa chỉ không hợp lệ!\nInvalid offset!";
    }
    
    void* patch_bytes=NULL; uint64_t patch_size=0;
    
    if(patch && patch[0]) {
        uint64_t patch_end = vaddr + (strlen(patch)+1)/2;
        uint64_t code_end = (patch_end+4-1) & ~(4-1);
        
        patch_size = code_end - funcRVA;
        
        NSMutableData* patchBytes = [[NSMutableData alloc] initWithLength:patch_size];
        patch_bytes = patchBytes.mutableBytes;
        
        memcpy(patch_bytes, funcData, patch_size);
        
        if(!hex2bytes(patch, (uint8_t*)patch_bytes+vaddr%4))
            return @"Các byte cần vá không chính xác!\nThe bytes to patch are incorrect!";

    } else if(vaddr % 4) {
        return @"Offset không được căn chỉnh \nThe offset is not aligned!";
    }
    
    
    uint64_t targetRVA = va2rva(header, text_seg->vmaddr);
    void* targetData = rva2data(header, targetRVA);
    
    
    uint64_t InstrumentBridgeRVA = targetRVA;
    
    uint64_t dataRVA = va2rva(header, data_seg->vmaddr);
    void* dataData = rva2data(header, dataRVA);
    
    StaticInlineHookBlock* hookBlock = (StaticInlineHookBlock*)dataData;
    StaticInlineHookBlock* hookBlockRVA = NULL;
    for(int i=0; i<STATIC_HOOK_CODEPAGE_SIZE/sizeof(StaticInlineHookBlock); i++)
    {
        if(hookBlock[i].hook_vaddr==funcRVA)
        {
            if(patch && patch[0] && hookBlock[i].patch_hash!=calc_patch_hash(vaddr, patch))
                return @"The bytes to patch have changed, please revert to original file and try again";
            
            if(newPath)
                return @"Địa chỉ này đã được vá. Vui lòng thay thế tệp đã vá trong thư mục Documents/static-inline-hook của APP thành thư mục .app trong ipa và ký lại bản cài đặt!";
            
            return @"Địa chỉ HOOK đã được vá!\nThe offset to hook is already patched!";
        }
        
        if( funcRVA>hookBlock[i].hook_vaddr &&
           ( funcRVA < (hookBlock[i].hook_vaddr+hookBlock[i].hook_size) || funcRVA < (hookBlock[i].hook_vaddr+hookBlock[i].patch_size) )
          ) {
            return @"Địa chỉ này đã được sử dụng!\nThe offset is occupied!";
        }
        
        if(hookBlock[i].hook_vaddr==0)
        {
            hookBlock = &hookBlock[i];
            hookBlockRVA = (StaticInlineHookBlock*)(dataRVA + i*sizeof(StaticInlineHookBlock));
            
            if(i == 0)
            {
                int codesize = dobby_create_instrument_bridge(targetData);
                
                targetRVA += codesize;
                *(uint64_t*)&targetData += codesize;
            }
            else
            {
                StaticInlineHookBlock* lastBlock = hookBlock - 1;
                targetRVA = lastBlock->code_vaddr + lastBlock->code_size;
                targetData = rva2data(header, targetRVA);
            }
            
            break;
        }
    }
    if(!hookBlockRVA) {
        return @"Đã vượt quá số lượng tối đa có sẵn!\nHOOK count full!";
    }
    
    if(!dobby_static_inline_hook(hookBlock, hookBlockRVA, funcRVA, funcData, targetRVA, targetData,
                                 InstrumentBridgeRVA, patch_bytes, patch_size))
    {
        return @"Địa chỉ không thể được vá!\ncan not patch the offset";
    }
    
    if(patch && patch[0]) {
        hookBlock->patch_size = patch_size;
        hookBlock->patch_hash = calc_patch_hash(vaddr, patch);
    }
    

    NSString* savePath = [NSString stringWithFormat:@"%@/Documents/M N M/%s", NSHomeDirectory(), machoPath];
    [NSFileManager.defaultManager createDirectoryAtPath:[NSString stringWithUTF8String:dirname((char*)savePath.UTF8String)] withIntermediateDirectories:YES attributes:nil error:nil];
    
    if(![macho writeToFile:savePath atomically:NO])
        return @"??????!\ncan not write to file!";
    
    gStaticInlineHookMachO[path] = savePath;
    return @"Địa chỉ này chưa được ký. Tệp vá sẽ được tạo trong thư mục Documents/static-inline-hook của APP. Vui lòng thay thế tất cả các tệp trong thư mục này thành thư mục .app trong ipa và ký lại cài đặt.!\nThe offset has not been patched, the patched file will be generated in the Documents/static-inline-hook directory of the APP, please replace all the files in this directory to the .app directory in the ipa and re-sign and reinstall!";
}


void* find_module_by_path(char* machoPath)
{
    NSString* path = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:[NSString stringWithUTF8String:machoPath]];
    
    for(int i=0; i< _dyld_image_count(); i++) {

        const char* fpath = _dyld_get_image_name(i);
        void* baseaddr = (void*)_dyld_get_image_header(i);
        void* slide = (void*)_dyld_get_image_vmaddr_slide(i);
        
        if([path isEqualToString:[NSString stringWithUTF8String:fpath]])
            return baseaddr;
    }
    
    return NULL;
}

StaticInlineHookBlock* find_hook_block(void* base, uint64_t vaddr)
{
    struct segment_command_64* text_seg = NULL;
    struct segment_command_64* data_seg = NULL;
    
    struct mach_header_64* header = (struct mach_header_64*)base;
    
    struct load_command* lc = (struct load_command*)((UInt64)header + sizeof(*header));
    for (int i = 0; i < header->ncmds; i++) {
        if (lc->cmd == LC_SEGMENT_64) {
            struct segment_command_64 * seg = (struct segment_command_64 *) lc;
            if(strcmp(seg->segname,"__HOOK_TEXT")==0)
                text_seg = seg;
            if(strcmp(seg->segname,"__HOOK_DATA")==0)
                data_seg = seg;
        }
        lc = (struct load_command *) ((char *)lc + lc->cmdsize);
    }
    
    if(!text_seg || !data_seg) {
        return NULL;
    }
    
    StaticInlineHookBlock* hookBlock = (StaticInlineHookBlock*)((uint64_t)header + va2rva(header, data_seg->vmaddr));
    for(int i=0; i<STATIC_HOOK_CODEPAGE_SIZE/sizeof(StaticInlineHookBlock); i++)
    {
        if(hookBlock[i].hook_vaddr == (uint64_t)vaddr)
        {
            return &hookBlock[i];
        }
    }
    
    return NULL;
}

void* StaticInlineHookFunction(char* machoPath, uint64_t vaddr, void* replace)
{
    void* base = find_module_by_path(machoPath);
    if(!base) {
        return NULL;
    }
    
    StaticInlineHookBlock* hookBlock = find_hook_block(base, vaddr);
    if(!hookBlock) {
        return NULL;
    }
    
    hookBlock->target_replace = replace;
    return (void*)((uint64_t)base + hookBlock->original_vaddr);
}


BOOL ActiveCodePatch(char* machoPath, uint64_t vaddr, char* patch)
{
    void* base = find_module_by_path(machoPath);
    if(!base) {
        return NO;
    }
    
    StaticInlineHookBlock* hookBlock = find_hook_block(base, vaddr&~3);
    if(!hookBlock) {
        return NO;
    }
    
    if(hookBlock->patch_hash != calc_patch_hash(vaddr, patch)) {
        return NO;
    }
    
    hookBlock->target_replace = (void*)((uint64_t)base + hookBlock->patched_vaddr);
    
    return YES;
}

BOOL DeactiveCodePatch(char* machoPath, uint64_t vaddr, char* patch)
{
    void* base = find_module_by_path(machoPath);
    if(!base) {
        return NO;
    }
    
    StaticInlineHookBlock* hookBlock = find_hook_block(base, vaddr&~3);
    if(!hookBlock) {
        return NO;
    }
    
    if(hookBlock->patch_hash != calc_patch_hash(vaddr, patch)) {
        return NO;
    }
    
    hookBlock->target_replace = NULL;
    
    return YES;
}


#define Miloo(x, y, z) \
{ \
    NSString* result_##y = StaticInlineHookPatch(("Frameworks/UnityFramework.framework/UnityFramework"), x, nullptr); \
    if (result_##y) { \
        void* result = StaticInlineHookFunction(("Frameworks/UnityFramework.framework/UnityFramework"), x, (void *) y); \
        *(void **) (&z) = (void*) result; \
    } \
}

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale



using namespace IL2Cpp;
@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end


NSUserDefaults *saveSetting = [NSUserDefaults standardUserDefaults];
NSFileManager *fileManager1 = [NSFileManager defaultManager];
NSString *documentDir1 = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

static float tabContentOffsetY[5] = {20.0f, 20.0f, 20.0f, 20.0f, 20.0f}; 
static float tabContentAlpha[5] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f}; 
static int selectedTab = 0;
static int lastSelectedTab = -1; 

const float TAB_CONTENT_ANIMATION_SPEED = 8.0f;
const float BUTTON_WIDTH = 105.0f;
const float BUTTON_HEIGHT = 33.0f;

void AnimateTabContent(int index, bool isActive) {
    if (isActive) {
        if (tabContentOffsetY[index] > 0.0f) {
            tabContentOffsetY[index] -= ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED * 20.0f;
            if (tabContentOffsetY[index] < 0.0f) {
                tabContentOffsetY[index] = 0.0f;
            }
        }
        if (tabContentAlpha[index] < 1.0f) {
            tabContentAlpha[index] += ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED;
            if (tabContentAlpha[index] > 1.0f) {
                tabContentAlpha[index] = 1.0f;
            }
        }
    } else {
        if (tabContentOffsetY[index] < 20.0f) {
            tabContentOffsetY[index] += ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED * 20.0f;
            if (tabContentOffsetY[index] > 20.0f) {
                tabContentOffsetY[index] = 20.0f;
            }
        }
        if (tabContentAlpha[index] > 0.0f) {
            tabContentAlpha[index] -= ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED;
            if (tabContentAlpha[index] < 0.0f) {
                tabContentAlpha[index] = 0.0f;
            }
        }
    }
}

@implementation ImGuiDrawView
EntityManager *espManager;
EntityManager *ActorLinker_enemy;
ImFont* _espFont;
ImFont *_iconFont;

NSMutableDictionary *heroTextures;

static bool show_s0 = false;
static bool MenDeal = true;
static bool StreamerMode = false;
    static bool Drawicon = false;
    static bool showMinimap = false;
    int minimapType = 1;
    int skillCDStyle = 2;
uintptr_t botro;
uintptr_t c1;
uintptr_t c2;
uintptr_t c3;
bool showcd;
bool ESPEnable;
bool PlayerLine;
bool PlayerBox;
bool PlayerHealth;
bool PlayerName;
bool PlayerDistance;
bool PlayerAlert;
bool ESPArrow;

bool aimVisibleOnly ;

bool active = false;

int tab_count = 0;
bool callNotify = false;
bool saikey = false;


bool ESPCount;
int CameraHeight;

bool IgnoreInvisible = false;


uintptr_t (*LActorRoot_LHeroWrapper)(void *instance);
int (*LActorRoot_COM_PLAYERCAMP)(void *instance);

bool (*LObjWrapper_get_IsDeadState)(void *instance);
bool (*LObjWrapper_IsAutoAI)(void *instance);
int (*ValuePropertyComponent_get_actorHp)(void *instance);
int (*ValuePropertyComponent_get_actorHpTotal)(void *instance);

int (*ActorLinker_COM_PLAYERCAMP)(void *instance);
bool (*ActorLinker_IsHostPlayer)(void *instance);
int (*ActorLinker_ActorTypeDef)(void *instance);
Vector3 (*ActorLinker_getPosition)(void *instance);

bool (*ActorLinker_get_bVisible)(void *instance);
uintptr_t (*AsHero)(void *);
monoString* (*_SetPlayerName)(uintptr_t, monoString *, monoString *, bool );
void (*old_ActorLinker_ActorDestroy)(void *instance);
void ActorLinker_ActorDestroy(void *instance) {
    if (instance != NULL) {
        old_ActorLinker_ActorDestroy(instance);
		ActorLinker_enemy->removeEnemyGivenObject(instance);
        if (espManager->MyPlayer==instance){
            espManager->MyPlayer=NULL;
        }
    }
}
void (*old_LActorRoot_ActorDestroy)(void *instance,bool bTriggerEvent);
void LActorRoot_ActorDestroy(void *instance, bool bTriggerEvent) {
    if (instance != NULL) {
        old_LActorRoot_ActorDestroy(instance, bTriggerEvent);
        espManager->removeEnemyGivenObject(instance);
        
    }
}
monoString *CreateMonoString(const char *str) {
    monoString *(*String_CreateString)(void *instance, const char *str) = (monoString *(*)(void *, const char *))GetMethodOffset(("mscorlib.dll"), ("System"), ("String"), ("CreateString"), 1);
    return String_CreateString(NULL, str);
}


ImFont* fire = nullptr;

enum heads {
    rage, antiaim, visuals, settings, skins, configs, scripts
};

enum sub_heads {
    general, accuracy, exploits, _general, advanced
};





bool unlockskin;







void (*old_ActorLinker_Update)(void *instance);
void ActorLinker_Update(void *instance) {
    if (instance != NULL) {
        uintptr_t SkillControl = AsHero(instance);
        uintptr_t HudControl = *(uintptr_t *) ((uintptr_t)instance + 0x78);
        if (showcd) {
        if (HudControl > 0 && SkillControl > 0) {
            uintptr_t Skill1Cd = *(int *)(SkillControl + (c1 - 0x4)) / 1000;
            uintptr_t Skill2Cd = *(int *)(SkillControl + (c2 - 0x4)) / 1000;
            uintptr_t Skill3Cd = *(int *)(SkillControl + (c3 - 0x4)) / 1000;
            uintptr_t Skill4Cd = *(int *)(SkillControl + (botro - 0x4)) / 1000;
            string sk1, sk2, sk3, sk4;
            

            sk1 = (Skill1Cd == 0) ? " [S1] " : " [" + to_string(Skill1Cd) + "] ";
            sk2 = (Skill2Cd == 0) ? " [S2]" : " [" + to_string(Skill2Cd) + "] ";
            sk3 = (Skill3Cd == 0) ? " [S3] " : " [" + to_string(Skill3Cd) + "] ";
            sk4 = (Skill4Cd == 0) ? " [P] " : " [" + to_string(Skill4Cd) + "] ";

            string ShowSkill = sk1 + sk2 + sk3; 
            string ShowSkill2 = sk4;
            const char *str1 = ShowSkill.c_str();
            const char *str2 = ShowSkill2.c_str();

            
            monoString* playerName = CreateMonoString(str1);
            monoString* prefixName = CreateMonoString(str2);
            _SetPlayerName(HudControl, playerName, prefixName, true);
            }
        }
        old_ActorLinker_Update(instance);
        if (ActorLinker_ActorTypeDef(instance)==0){
            if (ActorLinker_IsHostPlayer(instance)==true){
                espManager->tryAddMyPlayer(instance);
            } else {
				if(espManager->MyPlayer != NULL){
					if(ActorLinker_COM_PLAYERCAMP(espManager->MyPlayer) != ActorLinker_COM_PLAYERCAMP(instance)){
						ActorLinker_enemy->tryAddEnemy(instance);
					}
				}
			}
        }
    }
}


void (*old_LActorRoot_UpdateLogic)(void *instance, int delta);
void LActorRoot_UpdateLogic(void *instance, int delta) {
    if (instance != NULL) {
        old_LActorRoot_UpdateLogic(instance, delta);
        if (espManager->MyPlayer!=NULL) {
            if (LActorRoot_LHeroWrapper(instance)!=NULL && LActorRoot_COM_PLAYERCAMP(instance) == ActorLinker_COM_PLAYERCAMP(espManager->MyPlayer)) {
				espManager->tryAddEnemy(instance);
			}
		}
    }
} 

int dem(int num){
    int div=1, num1 = num;
    while (num1 != 0) {
        num1=num1/10;
        div=div*10;
    }
    return div;
}

Vector3 VInt2Vector(VInt3 location, VInt3 forward){
    return Vector3((float)(location.X*dem(forward.X)+forward.X)/(1000*dem(forward.X)), (float)(location.Y*dem(forward.Y)+forward.Y)/(1000*dem(forward.Y)), (float)(location.Z*dem(forward.Z)+forward.Z)/(1000*dem(forward.Z)));
}

Vector3 VInt1Velocity(VInt3 velocity) {
    return Vector3(
        (float)(velocity.X) / 1000.0f,
        (float)(velocity.Y) / 1000.0f,
        (float)(velocity.Z) / 1000.0f
    );
}



void deleteBeetalkSessionDB() {
    // Lấy đường dẫn tới thư mục tài liệu của ứng dụng
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Tạo đường dẫn tới tệp "beetalk_session.db"
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"beetalk_session.db"];
    
    // Sử dụng NSFileManager để xóa tệp
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([fileManager fileExistsAtPath:filePath]) {
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (success) {
            NSLog(@"File deleted successfully.");
            showSuccessAndExit();
        } else {
            NSLog(@"Could not delete file -:%@ ", [error localizedDescription]);
        }
    } else {
        NSLog(@"File does not exist.");
    }
}

void showSuccessAndExit() {
    // Tạo thông báo
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" 
                                                                   message:@"Logouted" 
                                                            preferredStyle:UIAlertControllerStyleAlert];

    // Thêm hành động "OK" vào thông báo
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" 
                                                       style:UIAlertActionStyleDefault 
                                                     handler:^(UIAlertAction *action) {
        exit(0);
    }];
    [alert addAction:okAction];

    // Lấy root view controller để hiển thị thông báo
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:alert animated:YES completion:nil];
}

int main1(int argc, const char * argv[]) {
    @autoreleasepool {
        // Gọi hàm để xóa tệp
        deleteBeetalkSessionDB();
    }
    return 0;
}



enum class TdrErrorType {
    TDR_NO_ERROR = 0,
    TDR_ERR_SHORT_BUF_FOR_WRITE = -1,
    TDR_ERR_SHORT_BUF_FOR_READ = -2,
    TDR_ERR_STR_LEN_TOO_BIG = -3,
    TDR_ERR_STR_LEN_TOO_SMALL = -4,
    TDR_ERR_STR_LEN_CONFLICT = -5,
    TDR_ERR_MINUS_REFER_VALUE = -6,
    TDR_ERR_REFER_SURPASS_COUNT = -7,
    TDR_ERR_ARG_IS_NULL = -8,
    TDR_ERR_CUTVER_TOO_SMALL = -9,
    TDR_ERR_CUTVER_CONFILICT = -10,
    TDR_ERR_PARSE_TDRIP_FAILED = -11,
    TDR_ERR_INVALID_TDRIP_VALUE = -12,
    TDR_ERR_INVALID_TDRTIME_VALUE = -13,
    TDR_ERR_INVALID_TDRDATE_VALUE = -14,
    TDR_ERR_INVALID_TDRDATETIME_VALUE = -15,
    TDR_ERR_FUNC_LOCALTIME_FAILED = -16,
    TDR_ERR_INVALID_HEX_STR_LEN = -17,
    TDR_ERR_INVALID_HEX_STR_FORMAT = -18,
    TDR_ERR_INVALID_BUFFER_PARAMETER = -19,
    TDR_ERR_NET_CUTVER_INVALID = -20,
    TDR_ERR_ACCESS_VILOATION_EXCEPTION = -21,
    TDR_ERR_ARGUMENT_NULL_EXCEPTION = -22,
    TDR_ERR_USE_HAVE_NOT_INIT_VARIABLE_ARRAY = -23,
    TDR_ERR_INVALID_FORMAT = -24,
    TDR_ERR_HAVE_NOT_SET_SIZEINFO = -25,
    TDR_ERR_VAR_STRING_LENGTH_CONFILICT = -26,
    TDR_ERR_VAR_ARRAY_CONFLICT = -27,
    TDR_ERR_BAD_TLV_MAGIC = -28,
    TDR_ERR_UNMATCHED_LENGTH = -29,
    TDR_ERR_UNION_SELECTE_FIELD_IS_NULL = -30,
    TDR_ERR_SUSPICIOUS_SELECTOR = -31,
    TDR_ERR_UNKNOWN_TYPE_ID = -32,
    TDR_ERR_LOST_REQUIRED_FIELD = -33,
    TDR_ERR_NULL_ARRAY = -34
	//
};

class TdrReadBuf {
private:
    std::vector<uint8_t> beginPtr;
    int32_t position;
    int32_t length;
    bool isNetEndian;
public:
    bool isUseCache;
	//
};

namespace CSProtocol {
	class COMDT_HERO_COMMON_INFO {
    public:
        uint32_t getdwHeroID() {
			if (this == nullptr) {return 0;}
			return *(uint32_t *)((uint64_t)this + 0x10);
		};
        uint16_t getwSkinID() {
			if (this == nullptr) {return 0;}
			return *(uint16_t *)((uint64_t)this + 0x42);
		};
		
		void setdwHeroID(uint32_t dwHeroID) {
			if (this == nullptr) {return;}
			*(uint32_t *)((uint64_t)this + 0x10) = dwHeroID;
		};
        void setwSkinID(uint16_t wSkinID) {
			if (this == nullptr) {return;}
			*(uint16_t *)((uint64_t)this + 0x42) = wSkinID;
		};
		//
    };
	
	struct saveData {
        static uint32_t heroId;
        static uint16_t skinId;
		static bool enable;
		static std::vector<std::pair<COMDT_HERO_COMMON_INFO*, uint16_t>> arrayUnpackSkin;
		
        static void setData(uint32_t hId, uint16_t sId) {
            heroId = hId;
            skinId = sId;
        }
		
		static void setEnable(bool eb) {
            enable = eb;
        }
		
        static uint32_t getHeroId() {
            return heroId;
        }

        static uint16_t getSkinId() {
            return skinId;
        }
		
		static bool getEnable() {
            return enable;
        }
		
		static void resetArrayUnpackSkin() {
    		if (!saveData::arrayUnpackSkin.empty()) {
        		for (const auto& skinInfo : saveData::arrayUnpackSkin) {
            		COMDT_HERO_COMMON_INFO* heroInfo = skinInfo.first;
            		uint16_t skinId = skinInfo.second;
			
            		heroInfo->setwSkinID(skinId);
        		}
        		saveData::arrayUnpackSkin.clear();
    		}
		}
		//
    };
	
    uint32_t saveData::heroId = 0;
    uint16_t saveData::skinId = 0;
	bool saveData::enable = false;
	std::vector<std::pair<COMDT_HERO_COMMON_INFO*, uint16_t>> saveData::arrayUnpackSkin;
	//
}

void hook_unpack(CSProtocol::COMDT_HERO_COMMON_INFO* instance) {
	if (!CSProtocol::saveData::enable) {return;}
	if (
	instance->getdwHeroID() == CSProtocol::saveData::heroId
	&& CSProtocol::saveData::heroId != 0
	&& CSProtocol::saveData::skinId != 0
	) {
		CSProtocol::saveData::arrayUnpackSkin.emplace_back(instance, instance->getwSkinID());
		instance->setwSkinID(CSProtocol::saveData::skinId);
	}
	//
}

TdrErrorType (*old_unpack)(CSProtocol::COMDT_HERO_COMMON_INFO* instance, TdrReadBuf& srcBuf, int32_t cutVer);
TdrErrorType unpack(CSProtocol::COMDT_HERO_COMMON_INFO* instance, TdrReadBuf& srcBuf, int32_t cutVer) {

	TdrErrorType result = old_unpack(instance, srcBuf, cutVer);
		if (unlockskin) {
	hook_unpack(instance);
	}
    return result;
	//
}



void (*old_RefreshHeroPanel)(void* instance, bool bForceRefreshAddSkillPanel, bool bRefreshSymbol, bool bRefreshHeroSkill);
void (*old_OnClickSelectHeroSkin)(void *instance, uint32_t heroId, uint32_t skinId);
void OnClickSelectHeroSkin(void *instance, uint32_t heroId, uint32_t skinId) {
	if (unlockskin) {
	if (heroId != 0) {
		old_RefreshHeroPanel(instance, 1, 1, 1);
	}
	}
	old_OnClickSelectHeroSkin(instance, heroId, skinId);
}

bool (*old_IsCanUseSkin)(void *instance, uint32_t heroId, uint32_t skinId);
bool IsCanUseSkin(void *instance, uint32_t heroId, uint32_t skinId) {

	if (unlockskin) {
		if (heroId != 0) {
		CSProtocol::saveData::setData(heroId, skinId);
	}
	return 1;
	}
	return old_IsCanUseSkin(instance, heroId, skinId);

}

uint32_t (*old_GetHeroWearSkinId)(void* instance, uint32_t heroId);
uint32_t GetHeroWearSkinId(void* instance, uint32_t heroId) {

if (unlockskin) {
	CSProtocol::saveData::setEnable(true);
	return CSProtocol::saveData::skinId;
	}
	
	return old_GetHeroWearSkinId(instance, heroId);

}

bool (*old_IsHaveHeroSkin)(uintptr_t heroId, uintptr_t skinId, bool isIncludeTimeLimited);
bool IsHaveHeroSkin(uintptr_t heroId, uintptr_t skinId, bool isIncludeTimeLimited = false) {
if (unlockskin) {
	return 1;
	}
	return old_IsHaveHeroSkin(heroId, skinId, isIncludeTimeLimited);

}

//----------------------------------- Map Hack ------------------------------------//
enum COM_PLAYERCAMP {
    ComPlayercampMid = 0,
    ComPlayercamp1 = 1,
    ComPlayercamp2 = 2,
    ComPlayercamp3 = 3,
    ComPlayercamp4 = 4,
    ComPlayercamp5 = 5,
    ComPlayercamp6 = 6,
    ComPlayercamp7 = 7,
    ComPlayercamp8 = 8,
    ComPlayercampCount = 9,
    ComPlayercampOb = 10,
    ComPlayercampInvalid = 254,
    ComPlayercampAll = 255
};

bool bHackMap;
bool bVisible = false;

void (*_SetVisible)(void *instance, COM_PLAYERCAMP camp, bool bVisible, bool forceSync);
void SetVisible(void *instance, COM_PLAYERCAMP camp, bool bVisible, bool forceSync) {
    if (instance != NULL && bHackMap) {
        bVisible = true;
        forceSync = false; 
    }
    return _SetVisible(instance, camp, bVisible, forceSync);
}
//------------------------------------------------------------------------------------//

void (*OnEnter)(void *instance);
void _OnEnter(void *instance){
 if(instance!=NULL){
  AntiHooK = YES;
 }
 return OnEnter(instance);
}

void (*CreateGameOverSummary)(void *instance);

void *delayAntiHook(void *arg) {
    sleep(10);
    AntiHooK = NO;
    return NULL;
}

void _CreateGameOverSummary(void *instance) {
    if (instance != NULL) {
        
        CreateGameOverSummary(instance);
        pthread_t thread_id;
        pthread_create(&thread_id, NULL, delayAntiHook, NULL);
        pthread_detach(thread_id);
    }
}


-(void)initImageTexture: (id<MTLDevice>)device {
    heroTextures = [[NSMutableDictionary alloc] init];

    // Initialize hero textures
    [self addHeroTexture:device heroName:@"airi" base64Data:airi_data];
    [self addHeroTexture:device heroName:@"aleister" base64Data:aleister_data];
    [self addHeroTexture:device heroName:@"alice" base64Data:alice_data];
    [self addHeroTexture:device heroName:@"allain" base64Data:allain_data];
    [self addHeroTexture:device heroName:@"amily" base64Data:amily_data];
    [self addHeroTexture:device heroName:@"annette" base64Data:annette_data];
    [self addHeroTexture:device heroName:@"aoi" base64Data:aoi_data];
    [self addHeroTexture:device heroName:@"arduin" base64Data:arduin_data];
    [self addHeroTexture:device heroName:@"athur" base64Data:arthur_data];
    [self addHeroTexture:device heroName:@"arum" base64Data:arum_data];
    [self addHeroTexture:device heroName:@"astrid" base64Data:astrid_data];
    [self addHeroTexture:device heroName:@"ata" base64Data:ata_data];
    [self addHeroTexture:device heroName:@"aya" base64Data:aya_data];
    [self addHeroTexture:device heroName:@"azzenka" base64Data:azzenka_data];
    [self addHeroTexture:device heroName:@"baldum" base64Data:baldum_data];
    [self addHeroTexture:device heroName:@"bijan" base64Data:bijan_data];
    [self addHeroTexture:device heroName:@"bonnie" base64Data:bonnie_data];
    [self addHeroTexture:device heroName:@"bright" base64Data:bright_data];
    [self addHeroTexture:device heroName:@"butterfly" base64Data:butterfly_data];
    [self addHeroTexture:device heroName:@"capheny" base64Data:capheny_data];
    [self addHeroTexture:device heroName:@"celica" base64Data:celica_data];
    [self addHeroTexture:device heroName:@"charlotter" base64Data:charlotter_data];
    [self addHeroTexture:device heroName:@"chaugnar" base64Data:chaugnar_data];
    [self addHeroTexture:device heroName:@"cresht" base64Data:cresht_data];
    [self addHeroTexture:device heroName:@"darcy" base64Data:darcy_data];
    [self addHeroTexture:device heroName:@"dextra" base64Data:dextra_data];
    [self addHeroTexture:device heroName:@"dieuthuyen" base64Data:dieuthuyen_data];
    [self addHeroTexture:device heroName:@"dirak" base64Data:dirak_data];
    [self addHeroTexture:device heroName:@"dolia" base64Data:dolia_data];
    [self addHeroTexture:device heroName:@"elandorr" base64Data:elandorr_data];
    [self addHeroTexture:device heroName:@"elsu" base64Data:elsu_data];
    [self addHeroTexture:device heroName:@"enzo" base64Data:enzo_data];
    [self addHeroTexture:device heroName:@"erin" base64Data:erin_data];
    [self addHeroTexture:device heroName:@"errol" base64Data:errol_data];
    [self addHeroTexture:device heroName:@"fennik" base64Data:fennik_data];
    [self addHeroTexture:device heroName:@"florentino" base64Data:florentino_data];
    [self addHeroTexture:device heroName:@"gildur" base64Data:gildur_data];
    [self addHeroTexture:device heroName:@"grakk" base64Data:grakk_data];
    [self addHeroTexture:device heroName:@"hayate" base64Data:hayate_data];
    [self addHeroTexture:device heroName:@"helen" base64Data:helen_data];
    [self addHeroTexture:device heroName:@"iggy" base64Data:iggy_data];
    [self addHeroTexture:device heroName:@"ignis" base64Data:ignis_data];
    [self addHeroTexture:device heroName:@"ilumia" base64Data:ilumia_data];
    [self addHeroTexture:device heroName:@"ishar" base64Data:ishar_data];
    [self addHeroTexture:device heroName:@"jinna" base64Data:jinna_data];
    [self addHeroTexture:device heroName:@"kahlii" base64Data:kahlii_data];
    [self addHeroTexture:device heroName:@"kaine" base64Data:kaine_data];
    [self addHeroTexture:device heroName:@"keera" base64Data:kerra_data];
    [self addHeroTexture:device heroName:@"kilgroth" base64Data:kilgroth_data];
    [self addHeroTexture:device heroName:@"kriknak" base64Data:kriknak_data];
    [self addHeroTexture:device heroName:@"krixi" base64Data:krixi_data];
    [self addHeroTexture:device heroName:@"krizzix" base64Data:krizzix_data];
    [self addHeroTexture:device heroName:@"lauriel" base64Data:lauriel_data];
    [self addHeroTexture:device heroName:@"laville" base64Data:laville_data];
    [self addHeroTexture:device heroName:@"liliana" base64Data:liliana_data];
    [self addHeroTexture:device heroName:@"lindis" base64Data:lindis_data];
    [self addHeroTexture:device heroName:@"lorion" base64Data:lorion_data];
    [self addHeroTexture:device heroName:@"lubo" base64Data:lubo_data];
    [self addHeroTexture:device heroName:@"lumburr" base64Data:lumburr_data];
    [self addHeroTexture:device heroName:@"maloch" base64Data:maloch_data];
    [self addHeroTexture:device heroName:@"marja" base64Data:marja_data];
    [self addHeroTexture:device heroName:@"max" base64Data:max_data];
    [self addHeroTexture:device heroName:@"mganga" base64Data:mganga_data];
    [self addHeroTexture:device heroName:@"mina" base64Data:mina_data];
    [self addHeroTexture:device heroName:@"ming" base64Data:ming_data];
    [self addHeroTexture:device heroName:@"moren" base64Data:moren_data];
    [self addHeroTexture:device heroName:@"murad" base64Data:murad_data];
    [self addHeroTexture:device heroName:@"nakroth" base64Data:nakroth_data];
    [self addHeroTexture:device heroName:@"natalya" base64Data:natalya_data];
    [self addHeroTexture:device heroName:@"ngokhong" base64Data:ngokhong_data];
    [self addHeroTexture:device heroName:@"ormarr" base64Data:omar_data];
    [self addHeroTexture:device heroName:@"omega" base64Data:omega_data];
    [self addHeroTexture:device heroName:@"omen" base64Data:omen_data];
    [self addHeroTexture:device heroName:@"paine" base64Data:pain_data];
    [self addHeroTexture:device heroName:@"preyta" base64Data:preyta_data];
    [self addHeroTexture:device heroName:@"qi" base64Data:qi_data];
    [self addHeroTexture:device heroName:@"quillen" base64Data:quilen_data];
    [self addHeroTexture:device heroName:@"raz" base64Data:raz_data];
    [self addHeroTexture:device heroName:@"richter" base64Data:richter_data];
    [self addHeroTexture:device heroName:@"rouie" base64Data:rouie_data];
    [self addHeroTexture:device heroName:@"rourke" base64Data:rouke_data];
    [self addHeroTexture:device heroName:@"roxie" base64Data:roxie_data];
    [self addHeroTexture:device heroName:@"ryoma" base64Data:ryoma_data];
    [self addHeroTexture:device heroName:@"sephera" base64Data:sephera_data];
    [self addHeroTexture:device heroName:@"sinestrea" base64Data:sinestrea_data];
    [self addHeroTexture:device heroName:@"skud" base64Data:skud_data];
    [self addHeroTexture:device heroName:@"slimz" base64Data:slimz_data];
    [self addHeroTexture:device heroName:@"stuart" base64Data:Stuart_data];
    [self addHeroTexture:device heroName:@"supperman" base64Data:superman_data];
    [self addHeroTexture:device heroName:@"tachi" base64Data:tachi_data];
    [self addHeroTexture:device heroName:@"tarra" base64Data:tara_data];
    [self addHeroTexture:device heroName:@"teemee" base64Data:teemee_data];
    [self addHeroTexture:device heroName:@"telannas" base64Data:telannas_data];
    [self addHeroTexture:device heroName:@"terri" base64Data:terri_data];
    [self addHeroTexture:device heroName:@"thane" base64Data:thane_data];
    [self addHeroTexture:device heroName:@"theflash" base64Data:theflash_data];
    [self addHeroTexture:device heroName:@"thorne" base64Data:thorne_data];
    [self addHeroTexture:device heroName:@"toro" base64Data:toro_data];
    [self addHeroTexture:device heroName:@"trieuvan" base64Data:trieuvan_data];
    [self addHeroTexture:device heroName:@"tulen" base64Data:tulen_data];
    [self addHeroTexture:device heroName:@"valhein" base64Data:valhein_data];
    [self addHeroTexture:device heroName:@"veres" base64Data:veres_data];
    [self addHeroTexture:device heroName:@"veera" base64Data:verra_data];
    [self addHeroTexture:device heroName:@"violet" base64Data:violet_data];
    [self addHeroTexture:device heroName:@"volkath" base64Data:volkat_data];
    [self addHeroTexture:device heroName:@"wisp" base64Data:wips_data];
    [self addHeroTexture:device heroName:@"wiro" base64Data:wiro_data];
    [self addHeroTexture:device heroName:@"wonderwoman" base64Data:wonderwoman_data];
    [self addHeroTexture:device heroName:@"xenniel" base64Data:xeniel_data];
    [self addHeroTexture:device heroName:@"yan" base64Data:yan_data];
    [self addHeroTexture:device heroName:@"ybneth" base64Data:ybneth_data];
    [self addHeroTexture:device heroName:@"yenna" base64Data:yena_data];
    [self addHeroTexture:device heroName:@"yorn" base64Data:yorn_data];
    [self addHeroTexture:device heroName:@"yue" base64Data:yue_data];
    [self addHeroTexture:device heroName:@"zata" base64Data:zata_data];
    [self addHeroTexture:device heroName:@"zephys" base64Data:zephys_data];
    [self addHeroTexture:device heroName:@"zill" base64Data:zill_data];
    [self addHeroTexture:device heroName:@"zip" base64Data:zip_data];
    [self addHeroTexture:device heroName:@"zuka" base64Data:zuka_data];
    [self addHeroTexture:device heroName:@"biron" base64Data:biron_data];
}

- (void)addHeroTexture:(id<MTLDevice>)device heroName:(NSString *)heroName base64Data:(NSString *)base64Data {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MTLTexture> texture = [self loadImageTexture:device data:data];
    if (texture) {
        [heroTextures setObject:texture forKey:heroName];
    }
}

-(id<MTLTexture>)loadImageTexture:(id<MTLDevice>)device data:(NSData *)imageData {
    int width, height;
    unsigned char *pixels = stbi_load_from_memory((stbi_uc const *)[imageData bytes], (int)[imageData length], &width, &height, NULL, 4);

    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:(NSUInteger)width
                                                                                                height:(NSUInteger)height
                                                                                             mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    textureDescriptor.storageMode = MTLStorageModeShared;
    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
    [texture replaceRegion:MTLRegionMake2D(0, 0, (NSUInteger)width, (NSUInteger)height) mipmapLevel:0 withBytes:pixels bytesPerRow:(NSUInteger)width * 4];

    return texture;
}



class Camera {
	public:
        static Camera *get_main() {
        Camera *(*get_main_) () = (Camera *(*)()) GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "get_main", 0);
        
        //Camera *(*get_main_) () = (Camera *(*)()) (IL2Cpp + 0x31b8dd0);
        return get_main_();
    }
    
    Vector3 WorldToScreenPoint(Vector3 position) {
        Vector3 (*WorldToScreenPoint_)(Camera *camera, Vector3 position) = (Vector3 (*)(Camera *, Vector3)) GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "WorldToScreenPoint", 1);
        
        //Vector3 (*WorldToScreenPoint_)(Camera *camera, Vector3 position) = (Vector3 (*)(Camera *, Vector3)) (il2cppMap + 0x31b84c0);
        return WorldToScreenPoint_(this, position);
    }

    Vector3 WorldToScreen(Vector3 position) {
        Vector3 (*WorldToViewportPoint_)(Camera* camera, Vector3 position, int eye) = (Vector3 (*)(Camera*, Vector3, int)) GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "WorldToViewportPoint", 2);
        
        return WorldToViewportPoint_(this, position, 2);
        // Vector3 finalResult;
        // finalResult.x = kWidth * result.x;
        // finalResult.y = kHeight - result.y * kHeight;
        // finalResult.z = result.z;
        // return finalResult;
}

};


class ValueLinkerComponent {
    public:
        int get_actorHp() {
            int (*get_actorHp_)(ValueLinkerComponent * objLinkerWrapper) = (int (*)(ValueLinkerComponent *))GetMethodOffset("Project_d.dll", "Kyrios.Actor", "ValueLinkerComponent", "get_actorHp", 0);  
            return get_actorHp_(this);
        }

        int get_actorHpTotal() {
            int (*get_actorHpTotal_)(ValueLinkerComponent * objLinkerWrapper) =
                (int (*)(ValueLinkerComponent *))GetMethodOffset("Project_d.dll", "Kyrios.Actor", "ValueLinkerComponent", "get_actorHpTotal", 0);  
            return get_actorHpTotal_(this);
        }


          int get_maxSpeed() {
            int (*get_maxSpeed)(ValueLinkerComponent * objLinkerWrapper) =
                (int (*)(ValueLinkerComponent *))GetMethodOffset("Project_d.dll", "Kyrios.Actor", "ValueLinkerComponent", "get_maxSpeed", 0);  
            return get_maxSpeed(this);
        }
};






class ValuePropertyComponent {
    public:
       
          int actorMoveSpeed() {
            int (*actorMoveSpeed)(ValuePropertyComponent * objLinkerWrapper) =
                (int (*)(ValuePropertyComponent *))GetMethodOffset("Project_d.dll", "NucleusDrive.Logic", "ValuePropertyComponent", "actorMoveSpeed", 0);  
            return actorMoveSpeed(this);
  
  
        }



          int sactorMoveSpeed() {
            return *(int *) ((uintptr_t) this + 0x48);
        }
};



class CActorInfo {
    public:
        string *ActorName() {
            return *(string **)((uintptr_t)this + 0x18);
        }

        int hudHeight() {
            return *(int *)((uintptr_t)this + 0xB8); 
        }
};


class ActorConfig{
	public:
	
	int ConfigID() {
		return *(int *) ((uintptr_t) this + 0x1C);
	}
};




// Khai báo các cấu trúc cần thiết
class MovementState {
public:
    // Giả định GetVelocity trả về VInt3
    VInt3 GetVelocity() {
        // Define the function pointer to get the velocity from MovementState
        VInt3 (*GetVelocity_)(MovementState *movementState) = 
            (VInt3 (*)(MovementState *)) (GetMethodOffset(oxorany("Project_d.dll"),oxorany("NucleusDrive.Logic"),oxorany("MovementState"), oxorany("GetVelocity"), 0));
            return GetVelocity_(this);

    }
};

class ActorLinker {
    public:
        ValueLinkerComponent *ValueComponent() {
            return *(ValueLinkerComponent **)((uintptr_t)this + 0x30);
        }

        ActorConfig *ObjLinker() {
            return *(ActorConfig **) ((uintptr_t) this + 0x128);
        }

        Vector3 get_position() {
            Vector3 (*get_position_)(ActorLinker *linker) = (Vector3 (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_position"), 0));
            return get_position_(this);
        }
        Quaternion get_rotation() {
            Quaternion (*get_rotation_)(ActorLinker *linker) = (Quaternion (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_rotation"), 0));
            return get_rotation_(this);
        }
        bool IsHostCamp() {
            bool (*IsHostCamp_)(ActorLinker *linker) = (bool (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("IsHostCamp"), 0));
            return IsHostCamp_(this);
        }
        
        bool IsHostPlayer() {
            bool (*IsHostPlayer_)(ActorLinker *linker) = (bool (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("IsHostPlayer"), 0));
            return IsHostPlayer_(this);
        }
        bool isMoving() {
            return *(bool *) ((uintptr_t) this + 0x40A);
        }
Vector3 moveForward() {
            return *(Vector3 *) ((uintptr_t) this + 0x490);
        }
	  int groundSpeed() {
            return *(int *) ((uintptr_t) this + 0x48C);
        }
        Vector3 get_logicMoveForward() {
            Vector3 (*get_logicMoveForward_)(ActorLinker *linker) = (Vector3 (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_logicMoveForward"), 0));
            return get_logicMoveForward_(this);
        }
         Vector3 NormalMoveLerp() {
            Vector3 (*NormalMoveLerp)(ActorLinker *linker) = (Vector3 (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("NormalMoveLerp"), 4));
            return NormalMoveLerp(this);
        }
        bool get_bVisible() {
            bool (*get_bVisible_)(ActorLinker *linker) = (bool (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_bVisible"), 0));
            return get_bVisible_(this);
        }
        uintptr_t AsHero() {
            uintptr_t (*AsHero_)(ActorLinker *linker) = (uintptr_t (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("AsHero"), 0));
            return AsHero_(this);
        }
            
};



class PlayerMovement {
	public:

  VInt3 get_enemyDirection() {
            VInt3 (*get_enemyDirection)(PlayerMovement *pllayerMovement) = (VInt3 (*)(PlayerMovement *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("PlayerMovement"), oxorany("RealMoveDirection"), 0));
            return get_enemyDirection(this);
        }

};

class VActorMovementComponent {
	public:

  int enemySpeed() {
            int (*enemySpeed)(VActorMovementComponent *vActorMovementComponent) = (int (*)(VActorMovementComponent *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("VActorMovementComponent"), oxorany("get_maxSpeed"), 0));
            return enemySpeed(this);
        }

};
class ActorManager {
	public:
	
	List<ActorLinker *> *GetAllHeros() {
		List<ActorLinker *> *(*_GetAllHeros)(ActorManager *actorManager) = (List<ActorLinker *> *(*)(ActorManager *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorManager"), oxorany("GetAllHeros"), 0));
		return _GetAllHeros(this);
	}
};

class KyriosFramework {
	public:
	
	static ActorManager *get_actorManager() {
		auto get_actorManager_ = (ActorManager *(*)()) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios"), oxorany("KyriosFramework"), oxorany("get_actorManager"), 0));
		return get_actorManager_();
	}
};

class LActorRoot {
public:


Vector3 _location() {
    VInt3* vint3 = (VInt3*)((uintptr_t)this + 0xC0);
    return Vector3(*vint3); 
}

};



ImDrawList* getDrawList(){
    ImDrawList *drawList;
    drawList = ImGui::GetBackgroundDrawList();
    return drawList;
};
void DrawAimbotTab() {
    static int selectedAimWhen = aimType; // Biến lưu giá trị AimWhen đã chọn
    static int selecteddraw = drawType; 

    const char* aimWhenOptions[] = {"Lowest Health %", "Lowest Health", "Nearest distance", "Closest to the ray"};
    ImGui::Combo("Aim trigger", &selectedAimWhen, aimWhenOptions, IM_ARRAYSIZE(aimWhenOptions));

    ImGui::Spacing();

    const char* drawOptions[] = {"No", "Always", "When watching"};
    ImGui::Combo("Draw the aimed object", &selecteddraw, drawOptions, IM_ARRAYSIZE(drawOptions));

    aimType = selectedAimWhen;
    drawType = selecteddraw;
}
static auto get_OnCameraHeightChanged(void *player) {
    auto (*_get_OnCameraHeightChanged)(void *player) = (void *(*)(void *)) GetMethodOffset(oxorany("Project_d.dll"), oxorany(""), oxorany("CameraSystem"), oxorany("OnCameraHeightChanged"), 0);
    return _get_OnCameraHeightChanged(player);
}

void (*LateUpdate)(void *player);
void _LateUpdate(void *player) {
    if (player != nullptr) {
        get_OnCameraHeightChanged(player);
    }
    return LateUpdate(player);
}
float (*GetCameraHeightRateValue)(void *player, int type);
float _GetCameraHeightRateValue(void *player, int type) {
    if (player != nullptr) {
        if (CameraHeight == 0) {
            return 1.0f;
        } else if (CameraHeight == 1) {
            return 1.2f;
        } else if (CameraHeight == 2) {
            return 1.6f;
        } else if (CameraHeight == 3) {
            return 1.7f;
        } else if (CameraHeight == 4) {
            return 1.8f;
        } else if (CameraHeight == 5) {
            return 1.9f;
        } else if (CameraHeight == 6) {
            return 2.0f;
        } else if (CameraHeight == 7) {
            return 2.1f;
        } else if (CameraHeight == 8) {
            return 2.2f;
        } else if (CameraHeight == 9) {
            return 2.3f;
        } else if (CameraHeight == 10) {
            return 2.4f;
        } else if (CameraHeight == 11) {
            return 2.5f;
        } else if (CameraHeight == 12) {
            return 2.6f;
        } else if (CameraHeight == 13) {
            return 2.7f;
        } else if (CameraHeight == 14) {
            return 2.8f;
        } else if (CameraHeight == 15) {
            return 2.9f;
        }
    }
    return GetCameraHeightRateValue(player, type);
}

struct EntityInfo {
    Vector3 myPos;
	Vector3 enemyPos;
	Vector3 moveForward;
	int ConfigID;
	bool isMoving;
   // float enemySpeed;
};

EntityInfo EnemyTarget;


#include "Utils/Esp.h"

static ImVec2 minimapPos = ImVec2(45.111f, 32.344f);
static float minimapRotation = -0.7f;
static float iconScale = 1.691f;
static float minimapScale = 1.402f;
std::string namereal;

Vector3 RotateVectorByQuaternion(Quaternion q) {
	Vector3 v(0.0f, 0.0f, 1.0f);
    float w = q.w, x = q.x, y = q.y, z = q.z;

    Vector3 u(x, y, z);
    Vector3 cross1 = Vector3::Cross(u, v);
    Vector3 cross2 = Vector3::Cross(u, cross1);
    Vector3 result = v + 2.0f * cross1 * w + 2.0f * cross2;

    return result;
}

float SquaredDistance(Vector3 v, Vector3 o) {
	return (v.x - o.x) * (v.x - o.x) + (v.y - o.y) * (v.y - o.y) + (v.z - o.z) * (v.z - o.z);
}

Vector3 calculateSkillDirection(Vector3 myPosi, Vector3 enemyPosi, bool isMoving, Vector3 moveForward) {
    // Nếu kẻ địch đang di chuyển, dự đoán vị trí của họ một chút về phía trước
    if (isMoving) {
        float predictionFactor = 0.5f; // Tăng giảm giá trị này để điều chỉnh độ dính
        enemyPosi += moveForward * predictionFactor;
    }

    // Tính toán hướng từ vị trí của mình tới vị trí dự đoán của kẻ địch
    Vector3 direction = enemyPosi - myPosi;
    direction.Normalize();

    return direction;
}

bool AimSkill;
bool isCharging;
int mode = 0, aimType = 1, drawType = 2, skillSlot;

Vector3 (*_GetUseSkillDirection)(void *instance, bool isTouchUse);
Vector3 GetUseSkillDirection(void *instance, bool isTouchUse){
	if (instance != NULL && AimSkill && EnemyTarget.ConfigID == 196) {
		if (EnemyTarget.myPos != Vector3::zero() && EnemyTarget.enemyPos != Vector3::zero() && skillSlot == 2) {
			return calculateSkillDirection(EnemyTarget.myPos, EnemyTarget.enemyPos, EnemyTarget.isMoving, EnemyTarget.moveForward);
		}
	}
	return _GetUseSkillDirection(instance, isTouchUse);
}




uintptr_t m_isCharging, m_currentSkillSlotType;
bool (*_UpdateLogic)(void *instance, int delta);
bool UpdateLogic(void *instance, int delta){
	if (instance != NULL) {
		isCharging = *(bool *)((uintptr_t)instance + m_isCharging);
		skillSlot = *(int *)((uintptr_t)instance + m_currentSkillSlotType);
	}
	return _UpdateLogic(instance, delta);
}

struct CDInfo {
    float iconPosX;
    float iconPosY;
    std::string heroNameStr;
    uintptr_t Skill1Cd;
    uintptr_t Skill2Cd;
    uintptr_t Skill3Cd;
    uintptr_t Skill4Cd;
};


static bool showNameTimer = true;
static float nameTimer = 0.0f;
const float NAME_DISPLAY_DURATION = 2.0f; // 2 seconds
static float tablePosX = 189.0f; // Vị trí x của bảng
static float tablePosY = 3.5f; // Vị trí y của bảng
static float tableScale = 0.761f; // Scale của bảng
void DrawESP(ImDrawList *draw) {
    if (espManager->enemies->empty() || !ESPEnable) {
        return;
    }


    float cameraScaleFactor = _GetCameraHeightRateValue(espManager->MyPlayer, 0);
    
    int numberOfEnemies = 0;

    float tableWidth = 125.0f * tableScale; // Độ rộng cố định
    float tableHeight = 30.0f * espManager->enemies->size() * tableScale; // Chiều cao dựa trên số lượng kẻ địch
    // if (showcd)
    // {
    // draw->AddRectFilled(ImVec2(tablePosX, tablePosY), ImVec2(tablePosX + tableWidth, tablePosY + tableHeight), IM_COL32(0, 0, 0, 180), 5.0f * tableScale);
    // }

    std::vector<CDInfo> cdInfoList;

    for (int i = 0; i < espManager->enemies->size(); i++) {
                    void *actorLinker = espManager->MyPlayer;
                    void *Enemy = (*espManager->enemies)[i]->object;
                    void *EnemyLinker = (*ActorLinker_enemy->enemies)[i]->object;

                    Vector3 EnemyPos = Vector3::zero();

                    if (actorLinker && Enemy) {

                        CActorInfo *CharInfo = (CActorInfo *)((uintptr_t)EnemyLinker + 0x120);

                        if (!CharInfo) {
                            continue; // Skip if CharInfo is null
                        }

                        Vector3 myPos = ActorLinker_getPosition(actorLinker);

                        Vector3 myPosSC = Camera::get_main()->WorldToScreen(myPos);
                        ImVec2 myPos_Vec2 = ImVec2(myPosSC.x, myPosSC.y);

                        if (myPosSC.z > 0) {
                            myPos_Vec2 = ImVec2(myPosSC.x* kWidth, kHeight - myPosSC.y* kHeight);
                        } else {
                            myPos_Vec2 = ImVec2(kWidth - myPosSC.x* kWidth,myPosSC.y* kHeight);
                        }

                        VInt3* locationPtr = (VInt3*)((uint64_t)Enemy + 0xC0); // Giả sử location ở offset 0xC0
                        VInt3* forwardPtr = (VInt3*)((uint64_t)Enemy + 0xCC); // Giả sử forward ở offset 0xCC (thay đổi offset nếu cần)

                        EnemyPos = VInt2Vector(*locationPtr,*forwardPtr);

                        void *LObjWrapper = *(void**)((uint64_t)Enemy + 0x2A8);
                        void *ValuePropertyComponent = *(void**)((uint64_t)Enemy + 0x2D0);

                        if (!LObjWrapper || !ValuePropertyComponent) {
                            continue; 
                        }


                        Vector3 rootPos_W2S = Camera::get_main()->WorldToScreen(EnemyPos);
                        Vector2 rootPos_Vec2 = Vector2(rootPos_W2S.x, rootPos_W2S.y);

                        if (rootPos_W2S.z > 0) {
                            rootPos_Vec2 = Vector2(rootPos_W2S.x*kWidth,kHeight -rootPos_W2S.y*kHeight);
                        } else {
                            rootPos_Vec2 = Vector2(kWidth - rootPos_W2S.x*kWidth,rootPos_W2S.y*kHeight);
                        }

                        uintptr_t SkillControl = ((ActorLinker*)EnemyLinker)->AsHero();
                        uintptr_t HudControl = *(int *)((uintptr_t)EnemyLinker + 0x78);
                        
                        if (HudControl < 1 && SkillControl < 1) continue;
                        
                        uintptr_t Skill1Cd = *(int *)(SkillControl + (c1 - 0x4)) / 1000;
                        uintptr_t Skill2Cd = *(int *)(SkillControl + (c2 - 0x4)) / 1000;
                        uintptr_t Skill3Cd = *(int *)(SkillControl + (c3 - 0x4)) / 1000;
                        uintptr_t Skill4Cd = *(int *)(SkillControl + (botro - 0x4)) / 1000;
                        std::string SkillCD = "[" + to_string(Skill4Cd) + "]" + " | " + to_string(Skill1Cd) + " " + "| " + to_string(Skill2Cd) + "  " + "| " + to_string(Skill3Cd) + " |";
                        Vector3 rootSc = Camera::get_main()->WorldToScreen(EnemyPos);
                        ImVec2 rootSc_Vec2 = ImVec2(rootSc.x,rootSc.y);

                        if (rootSc.z > 0) {
                            rootSc_Vec2 = ImVec2(rootSc.x*kWidth,kHeight -rootSc.y*kHeight);
                        } else {
                            rootSc_Vec2 = ImVec2(kWidth - rootSc.x*kWidth,rootSc.y*kHeight);
                        }


                        Vector2 headPos_Vec2 = Vector2(rootPos_Vec2.x, rootPos_Vec2.y - (kHeight / 9)); // Đầu cao hơn
                        Vector2 bottomPos_Vec2 = Vector2(rootPos_Vec2.x, rootPos_Vec2.y + (kHeight / 25)); // Chân thấp hơn
                        float distanceToMe = Vector3::Distance(myPos, EnemyPos);
                        ImVec2 myPos_ImVec2 = ImVec2(myPos_Vec2.x, myPos_Vec2.y);
                        ImVec2 rootPos_ImVec2 = ImVec2(rootPos_Vec2.x, rootPos_Vec2.y);

                        if(IgnoreInvisible){
                            
                            if(ActorLinker_get_bVisible(EnemyLinker)){
                                continue;
                            }
                        }

                    if (!LObjWrapper_get_IsDeadState(LObjWrapper)) {

                        float fixedBoxWidth = 40.0f;
                        float boxHeight = abs(headPos_Vec2.y - bottomPos_Vec2.y);

                        float boxWidth = fixedBoxWidth;

                        float boxCenterOffsetY = -7.0f; 

                        ImVec2 boxTopLeft = ImVec2(rootPos_Vec2.x - (boxWidth / 2), rootPos_Vec2.y - boxCenterOffsetY);
                        ImVec2 boxBottomRight = ImVec2(rootPos_Vec2.x + (boxWidth / 2), headPos_Vec2.y - boxCenterOffsetY);

                        if (PlayerLine) {
                            draw->AddLine(ImVec2(ImGui::GetIO().DisplaySize.x / 2, 38), 
                                        ImVec2(rootPos_Vec2.x, rootPos_Vec2.y - 15.0f), 
                                        IM_COL32(255, 255, 255, 180), 1.2f);
                            
                            draw->AddCircleFilled(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y - 15.0f), 3.0f, IM_COL32(0, 255, 0, 255));
                            
                            numberOfEnemies++;
                            
                            std::string enemyCount = "Enemies [" + std::to_string(numberOfEnemies) + "]";
                            auto textSize = ImGui::CalcTextSize(enemyCount.c_str()); 

                            float paddingX = 5.0f;
                            float paddingY = 3.0f; 

                            ImVec2 topLeft = ImVec2(ImGui::GetIO().DisplaySize.x / 2 - (textSize.x / 2) - paddingX, 
                                                    38 - textSize.y - paddingY);
                            ImVec2 bottomRight = ImVec2(ImGui::GetIO().DisplaySize.x / 2 + (textSize.x / 2) + paddingX, 
                                                        38 + paddingY);
                            draw->AddRectFilled(topLeft, bottomRight, IM_COL32(96, 44, 44, 255));

                            draw->AddRect(topLeft, bottomRight, IM_COL32(255, 99, 99, 255), 1.0f);

                            draw->AddText(NULL, ((float)kHeight / 30.0f), 
                                        {ImGui::GetIO().DisplaySize.x / 2 - (textSize.x / 2), 38 - textSize.y}, 
                                        IM_COL32(255, 99, 99, 255), enemyCount.c_str()); 
                        }
                        

                        if (PlayerBox) {
                           draw->AddRect(boxTopLeft, boxBottomRight, IM_COL32(255, 255, 255, 180), 0, 240, 1.5f);
                             //       Draw3dBox(draw, EnemyPos, Camera::get_main() );

                          //  Draw3dBox(draw, EnemyPos, Camera::get_main(), SCREEN_WIDTH,SCREEN_HEIGHT);
                        }
                        // if (showcd)
                        // {
                        //     CActorInfo *CharInfo = *(CActorInfo **) ((uintptr_t) EnemyLinker + 0x120);
                        //     std::string heroname;
                        //     std::string nameP;
                        //     monoString* actorname = (monoString*)CharInfo->ActorName();
                        //     if (actorname != nullptr) {
                        //         std::string strName = std::string(actorname->toCString());
                        //         nameP = bdvt_encode(strName);
                        //         heroname = nameP;
                        //     }
                        //     int heroID = ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID();
                        //     base642name(nameP, heroname, heroID);

                        //     CDInfo cdInfo;
                        //     cdInfo.iconPosX = tablePosX + 10.0f * tableScale;
                        //     cdInfo.iconPosY = tablePosY + (i * 30.0f + 5.0f) * tableScale;
                        //     cdInfo.heroNameStr = namereal;
                        //     cdInfo.Skill1Cd = Skill1Cd;
                        //     cdInfo.Skill2Cd = Skill2Cd;
                        //     cdInfo.Skill3Cd = Skill3Cd;
                        //     cdInfo.Skill4Cd = Skill4Cd;
                        //     cdInfoList.push_back(cdInfo);

                        // }
                                                
                        if (PlayerHealth && isOutsideScreen(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y), ImVec2(kWidth, kHeight))) {
                            ImVec2 hintDotRenderPos = ImVec2(rootPos_Vec2.x, rootPos_Vec2.y);

                            float dx = rootPos_Vec2.x - kWidth / 2;
                            float dy = rootPos_Vec2.y - kHeight / 2;

                            float radius = 20.0f; // Bán kính vòng máu nhỏ hơn

                            if (std::abs(dx) > std::abs(dy)) {
                                float direction = (dx > 0) ? 1.0f : -1.0f;
                                float ratio = std::abs(kWidth / 2 / dx);
                                hintDotRenderPos.x = kWidth / 2 + direction * (kWidth / 2 - radius - 10); // Cách mép màn hình 10px
                                hintDotRenderPos.y = kHeight / 2 + dy * ratio;

                                // Kiểm tra nếu hình tròn vượt qua cạnh màn hình
                                if (hintDotRenderPos.y < radius + 10)
                                    hintDotRenderPos.y = radius + 10;
                                else if (hintDotRenderPos.y > kHeight - radius - 10)
                                    hintDotRenderPos.y = kHeight - radius - 10;

                                // Kiểm tra không đi xuyên qua các cạnh góc màn hình
                                if ((hintDotRenderPos.x < radius + 10 && dx < 0) || (hintDotRenderPos.x > kWidth - radius - 10 && dx > 0))
                                    hintDotRenderPos.x = rootPos_Vec2.x;
                            } else {
                                float direction = (dy > 0) ? 1.0f : -1.0f;
                                float ratio = std::abs(kHeight / 2 / dy);
                                hintDotRenderPos.x = kWidth / 2 + dx * ratio;
                                hintDotRenderPos.y = kHeight / 2 + direction * (kHeight / 2 - radius - 10); // Cách mép màn hình 10px

                                // Kiểm tra nếu hình tròn vượt qua cạnh màn hình
                                if (hintDotRenderPos.x < radius + 10)
                                    hintDotRenderPos.x = radius + 10;
                                else if (hintDotRenderPos.x > kWidth - radius - 10)
                                    hintDotRenderPos.x = kWidth - radius - 10;

                                // Kiểm tra không đi xuyên qua các cạnh góc màn hình
                                if ((hintDotRenderPos.y < radius + 10 && dy < 0) || (hintDotRenderPos.y > kHeight - radius - 10 && dy > 0))
                                    hintDotRenderPos.y = rootPos_Vec2.y;
                            }

                            int EnemyHp = ValuePropertyComponent_get_actorHp(ValuePropertyComponent);
                            int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(ValuePropertyComponent);

                            draw->AddCircleFilled(hintDotRenderPos, radius, IM_COL32(0, 0, 0, 60));
                            DrawCircleHealth(hintDotRenderPos, EnemyHp, EnemyHpTotal, radius);

                            // Cập nhật namereal trước khi vẽ icon
                            CActorInfo *CharInfo = *(CActorInfo **) ((uintptr_t) EnemyLinker + 0x120);
                            std::string heroname;
                            std::string nameP;

                            monoString* actorname = (monoString*)CharInfo->ActorName(); 
                            if (actorname != nullptr) {
                                std::string strName = std::string(actorname->toCString());
                                nameP = bdvt_encode(strName);
                                heroname = nameP;
                            }

                            int heroID = ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID(); 
                            base642name(nameP, heroname, heroID); // Cập nhật namereal ở đây


                            // Vẽ icon tướng vào giữa vòng máu
                            NSString *heroNameKey = [NSString stringWithCString:namereal.c_str() encoding:NSUTF8StringEncoding];
                            heroNameKey = [heroNameKey lowercaseString];
                            id<MTLTexture> heroTexture = [heroTextures objectForKey:heroNameKey];

                            if (heroTexture) {
                                ImVec2 iconSize = ImVec2(radius * 1.5f, radius * 1.5f); // Điều chỉnh kích thước icon cho phù hợp
                                ImVec2 iconPos = ImVec2(hintDotRenderPos.x - iconSize.x / 2, hintDotRenderPos.y - iconSize.y / 2);
                                draw->AddImage((__bridge ImTextureID) heroTexture, iconPos, ImVec2(iconPos.x + iconSize.x, iconPos.y + iconSize.y)); 
                            }
                        } 

                        if (PlayerHealth && !isOutsideScreen(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y), ImVec2(kWidth, kHeight))) {
                            int EnemyHp = ValuePropertyComponent_get_actorHp(ValuePropertyComponent);
                            int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(ValuePropertyComponent);
                            float PercentHP = ((float)EnemyHp / (float)EnemyHpTotal);

                            ImU32 healthColor = IM_COL32(45, 180, 45, 255);
                            if (EnemyHp <= (EnemyHpTotal * 0.6)) {
                                healthColor = IM_COL32(180, 180, 45, 255);
                            }
                            if (EnemyHp < (EnemyHpTotal * 0.3)) {
                                healthColor = IM_COL32(180, 45, 45, 255);
                            }

                            float healthBarHeight = 60.0f; 
                            float healthBarWidth = 5.0f;   

                            float currentHealthHeight = healthBarHeight * PercentHP;

                            ImVec2 healthBarBottomLeft = ImVec2(rootPos_Vec2.x + boxWidth / 2 + healthBarWidth, rootPos_Vec2.y + 15);
                            ImVec2 healthBarTopRight = ImVec2(healthBarBottomLeft.x + healthBarWidth, healthBarBottomLeft.y - currentHealthHeight); 

                            draw->AddRectFilled(healthBarTopRight, healthBarBottomLeft, healthColor);

                            ImVec2 healthBarRectTopLeft = ImVec2(healthBarBottomLeft.x, healthBarBottomLeft.y - healthBarHeight);
                            ImVec2 healthBarRectBottomRight = ImVec2(healthBarRectTopLeft.x + healthBarWidth, healthBarBottomLeft.y); 

                            draw->AddRect(healthBarRectTopLeft, healthBarRectBottomRight, IM_COL32(0, 0, 0, 255), 0, 240, 0.4f);

                        }

                        if (PlayerDistance) {
                            std::string strDistance = "[ " + std::to_string((int)distanceToMe) + " M ]";

                                auto textSize = ImGui::CalcTextSize(strDistance.c_str(), 0, ((float)kHeight / 39.0f));
                                draw->AddText(NULL, ((float)kHeight / 39.0f), { headPos_Vec2.x - (textSize.x / 4), headPos_Vec2.y + 56 }, IM_COL32(255, 255, 100, 255), strDistance.c_str());
                        }

                        
                        

                        if (PlayerName) {
                            CActorInfo *CharInfo = *(CActorInfo **) ((uintptr_t) EnemyLinker + 0x120);
                            std::string heroname;
                            std::string nameP;


                            monoString* actorname = (monoString*)CharInfo->ActorName(); 
                            if (actorname != nullptr) {
                                std::string strName = std::string(actorname->toCString());
                                nameP = bdvt_encode(strName);
                                heroname = nameP;
                            }


                            int heroID = ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID(); 


                            base642name(nameP, heroname, heroID);

                            if (Drawicon) {
                                NSString *heroNameKey = [NSString stringWithCString:namereal.c_str() encoding:NSUTF8StringEncoding];
                                heroNameKey = [heroNameKey lowercaseString];
                                id<MTLTexture> heroTexture = [heroTextures objectForKey:heroNameKey];

                                if (heroTexture) {
                                    ImVec2 iconSize = ImVec2(38, 38); 
                                    ImVec2 iconPos = ImVec2(rootPos_Vec2.x - iconSize.x / 2, rootPos_Vec2.y - 15.0f - iconSize.y / 2);
                                    draw->AddImage((__bridge ImTextureID) heroTexture, iconPos, ImVec2(iconPos.x + iconSize.x, iconPos.y + iconSize.y)); 
                                }
                            }


                            if (showMinimap) {
                                ImVec2 minimapSize = ImVec2(97.656f * minimapScale, 96.094f * minimapScale);  // Giảm độ phân giải minimap xuống 50x50 và scale theo minimapScale
                                ImVec2 minimapCenter = ImVec2(minimapPos.x + minimapSize.x / 2.0f, minimapPos.y + minimapSize.y / 2.0f);
                                float worldSize = 150.0f; 
                                float minimapWidth = minimapSize.x;
                                float minimapHeight = minimapSize.y;
                                float scaleX = (minimapWidth / worldSize) * minimapScale;
                                float scaleY = (minimapHeight / worldSize) * minimapScale;

                                float angleRad = minimapRotation * (M_PI / 180.0f);
                                float cosTheta = cos(angleRad);
                                float sinTheta = sin(angleRad);

                                // Vẽ outline minimap
                                draw->AddRect(minimapPos, ImVec2(minimapPos.x + minimapSize.x, minimapPos.y + minimapSize.y), IM_COL32(255, 255, 255, 255), 0.0f, 0, 1.0f);

                                // Vẽ vị trí tướng trên minimap
                                Vector3 EnemyPos = VInt2Vector(*locationPtr,*forwardPtr);

                                ImVec2 worldPoint = ImVec2(EnemyPos.x, EnemyPos.z);
                                ImVec2 minimapPoint;

                                minimapPoint.x = minimapCenter.x + (worldPoint.x * scaleX);
                                minimapPoint.y = minimapCenter.y - (worldPoint.y * scaleY);

                                ImVec2 relativePoint = ImVec2(minimapPoint.x - minimapCenter.x, minimapPoint.y - minimapCenter.y);
                                ImVec2 rotatedPoint;
                                rotatedPoint.x = relativePoint.x * cosTheta - relativePoint.y * sinTheta + minimapCenter.x;
                                rotatedPoint.y = relativePoint.x * sinTheta + relativePoint.y * cosTheta + minimapCenter.y;

                                // Vẽ icon tướng thay cho chấm đỏ
                                NSString *heroNameKey = [NSString stringWithCString:namereal.c_str() encoding:NSUTF8StringEncoding];
                                heroNameKey = [heroNameKey lowercaseString];
                                id<MTLTexture> heroTexture = [heroTextures objectForKey:heroNameKey];

                                if (heroTexture) {
                                    float iconSize = 8.0f * iconScale;
                                    draw->AddImage((__bridge ImTextureID)heroTexture,
                                                    ImVec2(rotatedPoint.x - iconSize / 2.0f, rotatedPoint.y - iconSize / 2.0f),
                                                    ImVec2(rotatedPoint.x + iconSize / 2.0f, rotatedPoint.y + iconSize / 2.0f));

                                    // Vẽ viền tròn bao quanh icon (tương tự code1)
                                    draw->AddCircle(rotatedPoint, iconSize / 2.0f + 1.0f, IM_COL32(255, 255, 255, 255), 12, 1.0f);

                                    // Vẽ vòng máu mỏng với cùng độ dày (1.0f)
                                    int EnemyHp = ValuePropertyComponent_get_actorHp(ValuePropertyComponent);
                                    int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(ValuePropertyComponent);
                                    DrawCircleHealth2(rotatedPoint, EnemyHp, EnemyHpTotal, iconSize / 2.0f + 1.0f); 
                                }

                            }


                            if (LObjWrapper_IsAutoAI(LObjWrapper)) {
                                heroname = std::string("AI | " + heroname);
                            }


                            auto textSize = ImGui::CalcTextSize(heroname.c_str(), 0, ((float) kHeight / 39.0f));
                            draw->AddText(ImGui::GetFont(), ((float) kHeight / 39.0f), {rootPos_Vec2.x - (textSize.x / 4), rootPos_Vec2.y + 23}, IM_COL32(255, 255, 255, 255), heroname.c_str());
                            
                        
                            
                        }

                                            
                    
                    
                }
            }
}

if (AimSkill) {
    Quaternion rotation;
    float minDistance = std::numeric_limits<float>::infinity();
    float minDirection = std::numeric_limits<float>::infinity();
    float minHealth = std::numeric_limits<float>::infinity();
    		float minHealth2 = std::numeric_limits<float>::infinity();

    float minHealthPercent = std::numeric_limits<float>::infinity();
    ActorLinker *Entity = nullptr;
  //  MovementState *movementState = nullptr;  // Chỉnh tên biến `vantoc` thành `movementState` để dễ hiểu hơn
    ActorManager *get_actorManager = KyriosFramework::get_actorManager();
    if (get_actorManager == nullptr) return;

    List<ActorLinker *> *GetAllHeros = get_actorManager->GetAllHeros();
    if (GetAllHeros == nullptr) return;

    ActorLinker **actorLinkers = (ActorLinker **) GetAllHeros->getItems();

    for (int i = 0; i < GetAllHeros->getSize(); i++) {
        ActorLinker *actorLinker = actorLinkers[(i * 2) + 1];
        if (actorLinker == nullptr) continue;

        if (actorLinker->IsHostPlayer()) {
            rotation = actorLinker->get_rotation();
            EnemyTarget.myPos = actorLinker->get_position();
            EnemyTarget.ConfigID = actorLinker->ObjLinker()->ConfigID();
        }

        if (actorLinker->IsHostCamp() || actorLinker->ValueComponent()->get_actorHp() < 1) continue;

        Vector3 EnemyPos = actorLinker->get_position();
        float Health = actorLinker->ValueComponent()->get_actorHp();
        float MaxHealth = actorLinker->ValueComponent()->get_actorHpTotal();
        int HealthPercent = (int)std::round((float)Health / MaxHealth * 100);
        float Distance = Vector3::Distance(EnemyTarget.myPos, EnemyPos);

        // Sử dụng vận tốc mới từ GetVelocity()
    //    EnemyTarget.enemySpeed = Vector3::Magnitude(Entity->get_logicMoveForward()); // movementState thay vì vantoc
			float Direction = SquaredDistance(RotateVectorByQuaternion(rotation), calculateSkillDirection(EnemyTarget.myPos, EnemyPos, actorLinker->isMoving(), actorLinker->get_logicMoveForward()));
        if (Distance < 25.f) {
            if (aimType == 0 && HealthPercent < minHealthPercent) {
                Entity = actorLinker;
                minHealthPercent = HealthPercent;
            } else if (aimType == 1 && Health < minHealth) {
                Entity = actorLinker;
                minHealth = Health;
            } else if (aimType == 2 && Distance < minDistance) {
                Entity = actorLinker;
                minDistance = Distance;
            } else if (aimType == 3 && Direction < minDirection && isCharging) {
                Entity = actorLinker;
                minDirection = Direction;
            }
        }
    }

  if (Entity != NULL)
		{
			float nDistance = Vector3::Distance(EnemyTarget.myPos, Entity->get_position());
			if (nDistance > 25.f || Entity->ValueComponent()->get_actorHp() < 1)
			{
				EnemyTarget.enemyPos = Vector3::zero();
				EnemyTarget.moveForward = Vector3::zero();
				minDistance = std::numeric_limits<float>::infinity();
				minDirection = std::numeric_limits<float>::infinity();
				minHealth = std::numeric_limits<float>::infinity();
				minHealth2 = std::numeric_limits<float>::infinity();
				minHealthPercent = std::numeric_limits<float>::infinity();
				Entity = nullptr;
			}
					
			else
			{
				EnemyTarget.enemyPos =  Entity->get_position();
				EnemyTarget.moveForward = Entity->get_logicMoveForward();
				EnemyTarget.isMoving = Entity->isMoving();
			}
		}
		
		if (Entity != NULL && aimType == 3 && !isCharging)
		{
			EnemyTarget.enemyPos = Vector3::zero();
			EnemyTarget.moveForward = Vector3::zero();
			minDirection = std::numeric_limits<float>::infinity();
			Entity = nullptr;
		}
		
		if ((Entity != NULL || EnemyTarget.enemyPos != Vector3::zero()) && get_actorManager == nullptr)
		{
			EnemyTarget.enemyPos = Vector3::zero();
			EnemyTarget.moveForward = Vector3::zero();
			minDistance = std::numeric_limits<float>::infinity();
			minDirection = std::numeric_limits<float>::infinity();
			minHealth = std::numeric_limits<float>::infinity();
			minHealth2 = std::numeric_limits<float>::infinity();
			minHealthPercent = std::numeric_limits<float>::infinity();
			Entity = nullptr;
		}
		

    for (int i = 0; i < espManager->enemies->size(); i++) {
        void *actorLinker = espManager->MyPlayer;
        void *Enemy = (*espManager->enemies)[i]->object;
        void *EnemyLinker = (*ActorLinker_enemy->enemies)[i]->object;

        Vector3 EnemyPos = Vector3::zero();
        if (actorLinker && Enemy) {
            CActorInfo *CharInfo = (CActorInfo *)((uintptr_t)EnemyLinker + 0x120);
            if (!CharInfo) continue;

            Vector3 myPos = ActorLinker_getPosition(actorLinker);
            Vector3 myPosSC = Camera::get_main()->WorldToScreen(myPos);
            ImVec2 myPos_Vec2 = ImVec2(myPosSC.x * kWidth, kHeight - myPosSC.y * kHeight);

            VInt3* locationPtr = (VInt3*)((uint64_t)Enemy + 0xC0);
            VInt3* forwardPtr = (VInt3*)((uint64_t)Enemy + 0xCC);
            EnemyPos = VInt2Vector(*locationPtr, *forwardPtr);

            void *LObjWrapper = *(void**)((uint64_t)Enemy + 0x2A8);
            void *ValuePropertyComponent = *(void**)((uint64_t)Enemy + 0x2D0);
            if (!LObjWrapper || !ValuePropertyComponent) continue;

            Vector3 rootPos_W2S = Camera::get_main()->WorldToScreen(EnemyPos);
            Vector2 rootPos_Vec2 = Vector2(rootPos_W2S.x * kWidth, kHeight - rootPos_W2S.y * kHeight);

            // Vẽ đường aim ngay cả khi mục tiêu trong bụi
            if (Entity != nullptr) {
                float bulletSpeed = 100.0f;
                float gravity = 0.f;
                Vector3 enemyVelocity = Entity->get_logicMoveForward(); // movementState thay vì vantoc
           //    Vector3 enemyVelocity = GetVelocityVector(movementState);

                Vector3 predictedPos = calculatePredictedPosition(Entity->get_position(), enemyVelocity, bulletSpeed, gravity);

                Vector3 screenPos = Camera::get_main()->WorldToScreen(predictedPos);
                if (screenPos.z > 0) {
                    if (drawType == 2 && isCharging && skillSlot == 2) {
                        // Kiểm tra nếu EnemyLinker không nhìn thấy
                        if (!ActorLinker_get_bVisible(EnemyLinker)) {
                            ImVec2 predictedScreenPos(screenPos.x * kWidth, kHeight - screenPos.y * kHeight);
                            // Nếu không nhìn thấy kẻ địch, vẽ đường màu đỏ
                            ImGui::GetBackgroundDrawList()->AddLine(myPos_Vec2, predictedScreenPos, IM_COL32(255, 0, 0, 255), 1.0f);
                            draw->AddCircleFilled(ImVec2(predictedScreenPos.x, predictedScreenPos.y), 2.0f, IM_COL32(255, 0, 0, 255));
                        } else {

                            ImVec2 predictedScreenPos(screenPos.x * kWidth, kHeight - screenPos.y * kHeight);
                            ImGui::GetBackgroundDrawList()->AddLine(myPos_Vec2, predictedScreenPos, IM_COL32(124, 252, 0, 255), 1.0f);
                            draw->AddCircleFilled(ImVec2(predictedScreenPos.x, predictedScreenPos.y), 2.0f, IM_COL32(124, 252, 0, 255));
                        }
                    }
                }
            }
        }
    }
}



}



Vector3 calculatePredictedPosition(Vector3 enemyPos, Vector3 enemyVelocity, float bulletSpeed, float gravity) {
    Vector3 toEnemy = enemyPos - EnemyTarget.myPos;
    float distance = Vector3::Magnitude(toEnemy);
    
    // Tính toán tốc độ và hướng tương đối
    float relativeSpeed = Vector3::Magnitude(enemyVelocity);
    float angleCos = Vector3::Dot(Vector3::Normalized(toEnemy), Vector3::Normalized(enemyVelocity));

    // Kiểm tra điều kiện a và giải phương trình
    float a = bulletSpeed * bulletSpeed - relativeSpeed * relativeSpeed;
    if (abs(a) < 1e-3f) { 
        return enemyPos; 
    }
    float b = 2 * Vector3::Dot(toEnemy, enemyVelocity);
    float c = -distance * distance;

    // Discriminant
    float discriminant = b * b - 4 * a * c;
    if (discriminant < 0) return enemyPos; // Không thể chặn đầu

    // Tìm thời gian tiếp cận tối ưu
    float sqrtDiscriminant = sqrt(discriminant);
    float interceptTime = (-b + sqrtDiscriminant) / (2 * a);
    if (interceptTime < 0) interceptTime = (-b - sqrtDiscriminant) / (2 * a);
    if (interceptTime < 0) return enemyPos;

    // Tính vị trí đón đầu với thời gian chặn đầu
    Vector3 predictedPos = Vector3(
        enemyPos.x + enemyVelocity.x * interceptTime,
        enemyPos.y + enemyVelocity.y * interceptTime - 0.5f * gravity * interceptTime * interceptTime,
        enemyPos.z + enemyVelocity.z * interceptTime
    );

    return predictedPos;
}



// Hàm tính toán vị trí dự đoán của kẻ địch
Vector3 predictEnemyPosition(Vector3 enemyPos, Vector3 enemyVelocity, float time) {
    return Vector3(enemyPos.x + enemyVelocity.x * time,
                   enemyPos.y + enemyVelocity.y * time,
                   enemyPos.z + enemyVelocity.z * time);
}


void base642name(std::string nameP, std::string &heroname, int heroID){	
    
	if(nameP == ""){
		heroname = "Ata";
        namereal = "Ata";
		return;
	}
	if(nameP == "MTU3X0J1WmhpSHVvV3U=") {	
		heroname = "Raz";	
        namereal = "Raz";
		return;	
	}	
	if(nameP == "NTAzX1p1a2E=") {	
		heroname = "Zuka";	
        namereal = "Zuka";
		return;	
	}	
	if(nameP == "5p2O55m9") {	
		heroname = "Murad";	
        namereal = "Murad";
		return;	
	}	
	if(nameP == "6I2G6L2y") {	
		heroname = "Butterfly";	
        namereal = "Butterfly";
		return;	
	}	
	if(nameP == "5pu55pON") {	
		heroname = "Lữ Bố";	
        namereal = "lubo";
		return;	
	}	
	if(nameP == "MTEyX0dvbmdTaHVCYW4=") {	
		heroname = "Yorn";	
        namereal = "Yorn";
		return;	
	}	
	if(nameP == "NTIxX0Zsb3JlbnRpbm8=") {	
		heroname = "Florentino";
        namereal = "Florentino";	
		return;	
	}	
	if(nameP == "5qKF5p6X") {	
		heroname = "Natalya";	
        namereal = "Natalya";
		return;	
	}	
    if(nameP == "5Lqa55Gf546L" && heroID == 808) {	
		heroname = "Rối Athur";	
        namereal = "Athur";
		return;	
	}
	if(nameP == "5Lqa55Gf546L") {	
		heroname = "Athur";	
        namereal = "Athur";
		return;	
	}	
	if(nameP == "54uE5LuB5p2w") {	
		heroname = "Valhein";	
        namereal = "Valhein";
		return;	
	}	
	if(nameP == "6Z+p5L+h") {	
		heroname = "Nakroth";	
        namereal = "Nakroth";
		return;	
	}	
	if(nameP == "IOWFuOmfpg==") {	
		heroname = "Triệu vân";	
        namereal = "trieuvan";
		return;	
	}	
	if(nameP == "5aKo57+f") {	
		heroname = "Gildur";	
        namereal = "Gildur";
		return;	
	}	
	if(nameP == "6I6J6I6J5a6J") {	
		heroname = "Liliana";	
        namereal = "Liliana";
		return;	
	}	
	if(nameP == "6K+46JGb5Lqu") {	
		heroname = "Tulen";	
        namereal = "Tulen";
		return;	
	}	
	if(nameP == "5a2U5aSr5a2Q" && heroID == 139) {	
		heroname = "Kil'Groth";	
        namereal = "KilGroth";
		return;	
	}	
	if(nameP == "MTY3X1d1S29uZw==") {	
		heroname = "Ngộ Không";	
        namereal = "ngokhong";
		return;	
	}	
	if(nameP == "6ZKf6aaX") {	
		heroname = "Grakk";	
        namereal = "Grakk";
		return;	
	}	
	if(nameP == "5ZSQ5LiJ6JeP") {	
		heroname = "Skud";	
        namereal = "Skud";
		return;	
	}	
	if(nameP == "5Z+D572X") {	
		heroname = "Errol";	
        namereal = "Errol";
		return;	
	}	
	if(nameP == "NTI0X0NhcGhlbnk=") {	
		heroname = "Capheny";	
        namereal = "Capheny";
		return;	
	}	
	if(nameP == "5Yi5") {	
		heroname = "Zata";	
        namereal = "Zata";
		return;	
	}	
	if(nameP == "5a2U5aSr5a2Q") {	
		heroname = "Omen";	
        namereal = "Omen";
		return;	
	}	
	if(nameP == "5a2Z5bCa6aaZ") {	
		heroname = "Violet";
        namereal = "Violet";	
		return;	
	}	
	if(nameP == "5omB6bmK") {	
		heroname = "Mganga";	
        namereal = "Mganga";
		return;	
	}	
	if(nameP == "VmVyZXM=") {	
		heroname = "Veres";	
        namereal = "Veres";
		return;	
	}	
    if(nameP == "54m55bCU5a6J5aic5pav" && heroID == 809) {	
		heroname = "Rối Tel'Annas";	
        namereal = "TelAnnas";
		return;	
	}	
	if(nameP == "54m55bCU5a6J5aic5pav") {	
		heroname = "Tel'Annas";	
        namereal = "TelAnnas";
		return;	
	}	
	if(nameP == "TmFrb3J1cnU=") {	
		heroname = "Kriknak";	
        namereal = "Kriknak";
		return;	
	}	
	if(nameP == "55m+6YeM5a6I57qm") {	
		heroname = "Elsu";	
        namereal = "Elsu";
		return;	
	}	
	if(nameP == "MTE3X1pob25nV3VZYW4=") {	
		heroname = "Ormarr";	
        namereal = "Ormarr";
		return;	
	}	
	if(nameP == "6Jme5aes") {	
		heroname = "Stuart";	
        namereal = "Stuart";
		return;	
	}	
	if(nameP == "6LW15LqR") {	
		heroname = "Zephys";	
        namereal = "Zephys";
		return;	
	}	
	if(nameP == "5Lqa6L+e") {	
		heroname = "Allain";	
        namereal = "Allain";
		return;	
	}	
	if(nameP == "5a6r5pys5q2m6JeP") {	
		heroname = "Airi";	
        namereal = "Airi";
		return;	
	}	
	if(nameP == "6ams5Y+v5rOi572X") {	
		heroname = "Hayate";	
        namereal = "Hayate";
		return;	
	}	
	if(nameP == "MTA5X0Rhamk=") {	
		heroname = "Veera";	
        namereal = "Veera";
		return;	
	}	
	if(nameP == "5bCP5LmU") {	
		heroname = "Krixi";	
        namereal = "Krixi";
		return;	
	}	
	if(nameP == "5aWO5Lym") {	
		heroname = "Quillen";	
        namereal = "quillen";
		return;	
	}	
	if(nameP == "5YiY5aSH" && heroID == 512) {	
		heroname = "Rourke";	
        namereal = "Rourke";
		return;	
	}	
	if(nameP == "56iL5ZKs6YeR") {	
		heroname = "Tarra";	
        namereal = "tarra";
		return;	
	}	
	if(nameP == "57qi5ouC") {	
		heroname = "Zill";	
        namereal = "Zill";
		return;	
	}	
	if(nameP == "5Y+46ams5oe/") {	
		heroname = "Paine";	
        namereal = "Paine";
		return;	
	}	
	if(nameP == "5buJ6aKH") {	
		heroname = "Toro";	
        namereal = "Toro";
		return;	
	}	
	if(nameP == "5ZOq5ZCS") {	
		heroname = "Max";	
        namereal = "Max";
		return;	
	}	
	if(nameP == "NTMzX0hvdVlp") {	
		heroname = "Laville";	
        namereal = "Laville";
		return;	
	}	
	if(nameP == "NTMwX0RpcmFr") {	
		heroname = "Dirak";	
        namereal = "Dirak";
		return;	
	}	
	if(nameP == "NTA3X0ZsYXNo") {	
		heroname = "The Flash";	
        namereal = "TheFlash";
		return;	
	}	
	if(nameP == "SnVZb3VKaW5n") {	
		heroname = "Ryoma";	
        namereal = "Ryoma";
		return;	
	}	
	if(nameP == "5p2O5YWD6Iqz") {	
		heroname = "Fennik";	
        namereal = "Fennik";
		return;	
	}	
	if(nameP == "54K45by55Lq6") {	
		heroname = "Wisp";	
        namereal = "Wisp";
		return;	
	}	
	if(nameP == "5ay05pS/") {	
		heroname = "Kahlii";	
        namereal = "Kahlii";
		return;	
	}	
	if(nameP == "5Lic55qH5aSq5LiA") {	
		heroname = "Arum";	
        namereal = "Arum";
		return;	
	}	
	if(nameP == "U3VuQ2U=") {	
		heroname = "Bijan";	
        namereal = "Bijan";
		return;	
	}	
	if(nameP == "R2VuaXVz") {	
		heroname = "Thorne";	
        namereal = "Thorne";
		return;	
	}	
	if(nameP == "55m+6YeM546E562W") {	
		heroname = "Enzo";	
        namereal = "Enzo";
		return;	
	}	
	if(nameP == "5byg6Imv") {	
		heroname = "Aleister";	
        namereal = "Aleister";
		return;	
	}	
	if(nameP == "MTQxX0RpYW9DaGFu") {	
		heroname = "Lauriel";	
        namereal = "Lauriel";
		return;	
	}	
	if(nameP == "MTUyX1dhbmdaaGFvSnVu") {	
		heroname = "Điêu Thuyền";	
        namereal = "dieuthuyen";
		return;	
	}	
	if(nameP == "5YiY5aSH") {	
		heroname = "Moren";	
        namereal = "Moren";
		return;	
	}	
	if(nameP == "MTU0X0h1YU11TGFu") {	
		heroname = "Yenna";	
        namereal = "Yenna";
		return;	
	}	
	if(nameP == "MTk5X0xp") {	
		heroname = "Eland'orr";	
        namereal = "Elandorr";
		return;	
	}	
	if(nameP == "TmluamE=") {	
		heroname = "Aoi";	
        namereal = "Aoi";
		return;	
	}	
	if(nameP == "57uu6JCd") {	
		heroname = "Keera";	
        namereal = "Keera";
		return;	
	}	
	if(nameP == "5ZCV5biD") {	
		heroname = "Maloch";	
        namereal = "Maloch";
		return;	
	}	
	if(nameP == "56We5aWH5aWz5L6g") {	
		heroname = "Wonder Woman";	
        namereal = "WonderWoman";
		return;	
	}	
	if(nameP == "5ZCO576/") {	
		heroname = "Slimz";	
        namereal = "Slimz";
		return;	
	}	
	if(nameP == "MTE4X1N1bkJpbg==") {	
		heroname = "Alice";	
        namereal = "Alice";
		return;	
	}	
	if(nameP == "5pyX5Y2a") {	
		heroname = "Lumburr";	
        namereal = "Lumburr";
		return;	
	}	
	if(nameP == "MTIwX0JhaVFp") {	
		heroname = "Mina";	
        namereal = "Mina";
		return;	
	}	
	if(nameP == "QWlt") {	
		heroname = "Yue";	
        namereal = "Yue";
		return;	
	}	
	if(nameP == "6Iul5LyK") {	
		heroname = "Rouie";	
        namereal = "Rouie";
		return;	
	}	
	if(nameP == "NTQwMV9CcmlnaHQ=") {	
		heroname = "Bright";	
        namereal = "Bright";
		return;	
	}	
	if(nameP == "MTc3X0NoZW5nSmlTaUhhbg==") {	
		heroname = "Lindis";	
        namereal = "Lindis";
		return;	
	}	
	if(nameP == "6auY5riQ56a7") {	
		heroname = "Jinna";	
        namereal = "Jinna";
		return;	
	}	
	if(nameP == "6buE5b+g") {	
		heroname = "Celica";	
        namereal = "Celica";
		return;	
	}	
	if(nameP == "5qyn57Gz6IyE") {	
		heroname = "Omega";	
        namereal = "Omega";
		return;	
	}	
	if(nameP == "R2VuaXVz") {	
		heroname = "Bonnie";	
        namereal = "Bonnie";
		return;	
	}	
	if(nameP == "5YiY6YKm") {	
		heroname = "Xenniel";	
        namereal = "Xenniel";
		return;	
	}	
	if(nameP == "6JSh5paH5aes") {	
		heroname = "Helen";	
        namereal = "Helen";
		return;	
	}	
	if(nameP == "5aSP5L6v5oOH") {	
		heroname = "Arduin";	
        namereal = "Arduin";
		return;	
	}	
	if(nameP == "55SE5aes") {	
		heroname = "Azzen'ka";	
        namereal = "Azzenka";
		return;	
	}	
	if(nameP == "55qu55qu") {	
		heroname = "Zip";	
        namereal = "Zip";
		return;	
	}	
	if(nameP == "562x5riF") {	
		heroname = "Qi";	
        namereal = "Qi";
		return;	
	}	
	if(nameP == "5a6J5qC85YiX") {	
		heroname = "Volkath";	
        namereal = "Volkath";
		return;	
	}	
	if(nameP == "MTQwX0d1YW5ZdQ==") {	
		heroname = "Supper Man";	
        namereal = "supperman";
		return;	
	}	
	if(nameP == "MTQ4X0ppYW5nWmlZYQ==") {	
		heroname = "Preyta";	
        namereal = "Preyta";
		return;	
	}	
	if(nameP == "MTUzX0xhbkxpbmdXYW5n") {	
		heroname = "Kaine";	
        namereal = "Kaine";
		return;	
	}	
	if(nameP == "5ouJ5paQ5bCU") {	
		heroname = "Amily";	
        namereal = "Amily";
		return;	
	}	
	if(nameP == "MTIxX01pWXVl") {	
		heroname = "Marja";	
        namereal = "Marja";
		return;	
	}	
	if(nameP == "5q2m5YiZ5aSp") {	
		heroname = "Ilumia";	
        namereal = "Ilumia";
		return;	
	}	
	if(nameP == "6aG55769") {	
		heroname = "Thane";	
        namereal = "Thane";
		return;	
	}	
	if(nameP == "5aSq5LmZ55yf5Lq6") {	
		heroname = "Teemee";	
        namereal = "Teemee";
		return;	
	}	
	if(nameP == "6Zi/5pav5bSU5b63") {	
		heroname = "Astrid";	
        namereal = "Astrid";
		return;	
	}	
	if(nameP == "NTE1X1JpY2h0ZXI=") {	
		heroname = "Richter";	
        namereal = "Ata";
		return;	
	}	
	if(nameP == "5byg6aOe") {	
		heroname = "Cresh";	
        namereal = "Cresh";
		return;	
	}	
	if(nameP == "5ZGo55Gc") {	
		heroname = "Ignis";	
        namereal = "Ignis";
		return;	
	}	
	if(nameP == "MTEzX1podWFuZ1pob3U=") {	
		heroname = "Chaugnar";	
        namereal = "Chaugnar";
		return;	
	}	
	if(nameP == "6IuP54OI") {	
		heroname = "Wiro";	
        namereal = "Wiro";
		return;	
	}	
	if(nameP == "MTg5X0d1aUd1Wmk=") {	
		heroname = "Krizzix";	
        namereal = "Krizzix";
		return;	
	}	
	if(nameP == "NTA1X0JhbGR1bQ==") {	
		heroname = "Baldum";	
        namereal = "Baldum";
		return;	
	}	
	if(nameP == "5Y+k5pyo") {	
		heroname = "Y'bneth";	
        namereal = "ybneth";
		return;	
	}	
	if(nameP == "Um94aQ==") {	
		heroname = "Roxie";	
        namereal = "Roxie";
		return;	
	}	
	if(nameP == "5a6J5aWI54m5") {	
		heroname = "Annette";	
        namereal = "Annette";
		return;	
	}	
	if(nameP == "NTIzX0RBUkNZ") {	
		heroname = "D'Arcy";	
        namereal = "darcy";
		return;	
	}	
	if(nameP == "SXNoYXI=") {	
		heroname = "Ishar";	
        namereal = "Ishar";
		return;	
	}	
	if(nameP == "5r6c") {	
		heroname = "Sephera";	
        namereal = "Sephera";
		return;	
	}	
	if(nameP == "5aSc5aes") {	
		heroname = "Dextra";	
        namereal = "Dextra";
		return;	
	}	


    if(nameP == "5py16I6J5Lqa") {	
		heroname = "Dolia";	
        namereal = "Dolia";
		return;	
	}	

    if(nameP == "5aSP5rSb54m5") {	
		heroname = "Charlotte";	
        namereal = "Charlotter";
		return;	
	}	

    if(nameP == "6Im+55Cz") {	
		heroname = "Erin";	
        namereal = "Erin";
		return;	
	}	

	if(nameP == "6IuP56a7") {	
		heroname = "Sinestrea";	
        namereal = "Sinestrea";
		return;	
	}	
	if(nameP == "SWdneQ==") {	
		heroname = "Iggy";	
        namereal = "Iggy";
		return;	
	}	
	if(nameP == "NTM5X1NhbHo=") {	
		heroname = "Lorion";	
        namereal = "Lorion";
		return;	
	}	
	if(nameP == "VGFjaGk=") {	
		heroname = "Tachi";	
        namereal = "Tachi";
		return;	
	}	
	if(nameP == "WWFv") {	
		heroname = "Aya";	
        namereal = "Aya";
		return;	
	}
	if(nameP == "V2hpdGVCb3g=") {	
		heroname = "Yan";	
        namereal = "Yan";
		return;	
	}	
	if(nameP == "SGVjYXRl") {	
		heroname = "Terri";	
        namereal = "Terri";
		return;	
	}
    if(nameP == "5piO5LiW6ZqQ") {	
		heroname = "Ming";	
        namereal = "ming";
		return;	
	}

    if(nameP == "54uC6ZOB") {	
		heroname = "Biron";	
        namereal = "biron";
		return;	
	}


}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;


        ImGuiStyle* style = &ImGui::GetStyle();



    ImFontConfig font_config;
    ImFontConfig icons_config;
    ImFontConfig config;
    ImFontConfig CustomFont;
    CustomFont.FontDataOwnedByAtlas = false;
    icons_config.MergeMode = true;
    icons_config.PixelSnapH = true;
    icons_config.OversampleH = 7;
    icons_config.OversampleV = 7;

        font_config.FontBuilderFlags = 1;
    
        static const ImWchar icons_ranges[] = { 0xf000, 0xf3ff, 0 };
        
        static const ImWchar ranges[] =
        {
        0x0020, 0x00FF, // Basic Latin + Latin Supplement
        0x0400, 0x052F, // Cyrillic + Cyrillic Supplement
        0x2DE0, 0x2DFF, // Cyrillic Extended-A
        0xA640, 0xA69F, // Cyrillic Extended-B
        0xE000, 0xE226, // icons
        0,
        };
        



   
    NSString *FontPath = @"/System/Library/Fonts/LanguageSupport/Thonburi.ttc";

    NSString *FontPath1 = @"/System/Library/Fonts/LanguageSupport/PingFang.ttc";

    NSString *FontPath2 = @"/System/Library/Fonts/CoreAddition/ArialBold.ttf";


 ImFont* font = io.Fonts->AddFontFromFileTTF(FontPath2.UTF8String, 20.0f, &config, io.Fonts->GetGlyphRangesVietnamese());


   io.Fonts->AddFontFromMemoryCompressedTTF(font_awesome_data, font_awesome_size, 20.0f, &icons_config, icons_ranges);
    
        fire = io.Fonts->AddFontFromMemoryTTF(&firee, sizeof firee, 27, NULL, io.Fonts->GetGlyphRangesCyrillic());


    //ImFont* font = io.Fonts->AddFontFromMemoryCompressedTTF((void*)Honkai_compressed_data, Honkai_compressed_size, 45.0f, NULL, io.Fonts->GetGlyphRangesDefault());
    
    ImGui_ImplMetal_Init(_device);

    return self;
	}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{

 

    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;

    if ([saveSetting objectForKey:@"ESPEnable"] != nil) {
			bHackMap = [saveSetting boolForKey:@"bHackMap"];
        ESPEnable = [saveSetting boolForKey:@"ESPEnable"];
        PlayerLine = [saveSetting boolForKey:@"PlayerLine"];
        PlayerBox = [saveSetting boolForKey:@"PlayerBox"];
        PlayerHealth = [saveSetting boolForKey:@"PlayerHealth"];
        PlayerName = [saveSetting boolForKey:@"PlayerName"];
        PlayerDistance = [saveSetting boolForKey:@"PlayerDistance"];
        PlayerAlert = [saveSetting boolForKey:@"PlayerAlert"];
        Drawicon = [saveSetting boolForKey:@"Drawicon"];
        ESPCount = [saveSetting boolForKey:@"ESPCount"];
        IgnoreInvisible = [saveSetting boolForKey:@"IgnoreInvisible"];
				showcd = [saveSetting boolForKey:@"showcd"];
				unlockskin = [saveSetting boolForKey:@"unlockskin"];
        AimSkill = [saveSetting boolForKey:@"AimSkill"];
				CameraHeight = [saveSetting floatForKey:@"CameraHeight"];
        NSArray *minimapPosArray = [saveSetting objectForKey:@"minimapPos"];
        minimapPos = ImVec2([minimapPosArray[0] floatValue], [minimapPosArray[1] floatValue]);
        minimapRotation = [saveSetting floatForKey:@"minimapRotation"];
        minimapScale = [saveSetting floatForKey:@"minimapScale"];
        iconScale = [saveSetting floatForKey:@"iconScale"];
        tablePosX = [saveSetting floatForKey:@"tablePosX"];
        tablePosY = [saveSetting floatForKey:@"tablePosY"];

    }
		
		
}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}


- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    if (MenDeal) {
        [self.view setUserInteractionEnabled:YES];
    } else {
        [self.view setUserInteractionEnabled:NO];
    }

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Jane"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        ImFont* font = ImGui::GetFont();
        font->Scale = 15.f / font->FontSize;
        
        CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - 600) / 2;
        CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - 305) / 2;
        
        ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowSize(ImVec2(600, 305), ImGuiCond_FirstUseEver);

        static bool show;   
        bool bonios;

        if (MenDeal)
        {                
            show = true;

            if (show) 
            {
                static heads tab{ rage };
                static sub_heads subtab{ general };
                const char* tab_name = tab == rage ? "Ragebot" : tab == antiaim ? "Anti-aim" : tab == visuals ? "Visuals" : tab == settings ? "Settings" : tab == skins ? "Skins" : tab == configs ? "Configs" : tab == scripts ? "Scripts" : 0;
                const char* tab_icon = tab == rage ? "B" : tab == antiaim ? "C" : tab == visuals ? "D" : tab == settings ? "E" : tab == skins ? "F" : tab == configs ? "G" : tab == scripts ? "H" : 0;

                ImGui::Begin("#boniosvn", nullptr, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoBackground);
                {
                    ImVec2 P1, P2;
                    ImDrawList* pDrawList;
                    const auto& p = ImGui::GetWindowPos();
                    const auto& pWindowDrawList = ImGui::GetWindowDrawList();
                    const auto& pBackgroundDrawList = ImGui::GetBackgroundDrawList();
                    const auto& pForegroundDrawList = ImGui::GetForegroundDrawList();
                    const ImVec2 pos = ImGui::GetWindowPos();
                    ImDrawList* draw = ImGui::GetWindowDrawList();

                    // Dùng một lần khai báo style
                    ImGuiStyle& style = ImGui::GetStyle();
                    style.ScrollbarSize = 3.f;
                    style.ScrollbarRounding = 12.f;
                    style.WindowBorderSize = 0.f;
                    style.WindowPadding = ImVec2(0, 0);

                    // Thực hiện các lệnh vẽ ở đây
                    pBackgroundDrawList->AddRectFilled(ImVec2(0.000f + p.x, 0.000f + p.y), ImVec2(600 + p.x, 305 + p.y), ImColor(9, 9, 9, 254), 10);

                            draw->AddRectFilled(ImVec2(pos.x + 0, pos.y + 0), ImVec2(pos.x + 600, pos.y + 305), ImColor(0, 0, 0, 255), 10.f,ImDrawFlags_RoundCornersBottomLeft | ImDrawFlags_RoundCornersTopLeft);

//màu nền tab bên trái
        draw->AddRectFilled(ImVec2(pos.x + 0, pos.y + 0), ImVec2(pos.x + 210, pos.y + 305), ImColor(28, 28, 30, 255), 10.f,ImDrawFlags_RoundCornersBottomLeft | ImDrawFlags_RoundCornersTopLeft);

//nền tiêu đề bên phải
        draw->AddRectFilled(ImVec2(pos.x + 210, pos.y + 0), ImVec2(pos.x + 601, pos.y + 35), ImColor(28, 28, 30, 255), 10.f,ImDrawFlags_RoundCornersBottomRight | ImDrawFlags_RoundCornersTopRight);

//line tiêu đề bên phải
        draw->AddLine(ImVec2(pos.x + 210, pos.y + 35), ImVec2(pos.x + 600, pos.y + 35), ImColor(43, 43, 46, 255));      

        draw->AddLine(ImVec2(pos.x + 210, pos.y + 0), ImVec2(pos.x + 210, pos.y +305), ImColor(43, 43, 46, 255));

//chấm tròn         
        draw->AddCircleFilled(ImVec2(pos.x + 20, pos.y + 20), 8, ImColor(250, 91, 75), 360);//red
        draw->AddCircleFilled(ImVec2(pos.x + 41, pos.y + 20), 8, ImColor(255, 191, 56), 360);//yellow
        draw->AddCircleFilled(ImVec2(pos.x + 62, pos.y + 20), 8, ImColor(108, 240, 83), 360);   //green



//thanh kẻ bên trên title
        draw->AddLine(ImVec2(pos.x + 0, pos.y + 42), ImVec2(pos.x + 210, pos.y + 42), ImColor(43, 43, 46, 255));   

        draw->AddText(fire, 16.5f, ImVec2(15.000f + pos.x, 53.000f + pos.y), ImColor(255, 0, 0, 255), " Flashlight By ShinAOV");    
        draw->AddText(NULL, 16.5f, ImVec2(48.000f + pos.x, 53.000f + pos.y), ImColor(255, 255, 255, 255), " "); 
    
//thang kẻ bên dưới title
        draw->AddLine(ImVec2(pos.x + 0, pos.y + 82), ImVec2(pos.x + 210, pos.y + 82), ImColor(43, 43, 46, 255));    

//line các chức năng
        draw->AddLine(ImVec2(pos.x + 15, pos.y + 265), ImVec2(pos.x + 195, pos.y + 265), ImColor(43, 43, 46, 255));     //thanh kẻ dưới các button

        //draw->AddLine(ImVec2(pos.x + 15, pos.y + 290), ImVec2(pos.x + 195, pos.y + 290), ImColor(43, 43, 46, 255));
        
ImGui::SetCursorPos({10, 90});
        ImGui::BeginGroup(); {



        if (ImGui::ButtonExes("      Main", tab_count != 0)) { tab_count = 0; active = true; }
        if (ImGui::ButtonExes("      ESP", tab_count != 1)) { tab_count = 1; active = true; }
        if (ImGui::ButtonExes("      Aimbot", tab_count != 2)) { tab_count = 2; active = true; }
        if (ImGui::ButtonExes("      Setting", tab_count != 3)) { tab_count = 3; active = true; }
    



        ImGui::Spacing(); ImGui::Spacing(); ImGui::Spacing();
        ImGui::Spacing(); ImGui::Spacing(); ImGui::Spacing();
        ImGui::Spacing(); ImGui::Spacing(); 


        draw->AddText(fire, 20.f, ImVec2(16.000f + pos.x, 275.491f + pos.y), ImColor(10, 131, 255, 255), "G");//địa cầu

ImGui::TextColored(ImColor(1, 255, 1, 255), "         ShinAOV");


        }ImGui::EndGroup(); 
// ================================================================================================================================ //


     
        //Tab icons

        draw->AddText(fire, 20.f, ImVec2(16.000f + pos.x, 100.491f + pos.y), ImColor(0, 255, 0, 255), "K");
        draw->AddText(fire, 20.f, ImVec2(16.000f + pos.x, 140.491f + pos.y), ImColor(255, 0, 0, 255), "A");
        draw->AddText(fire, 20.f, ImVec2(16.000f + pos.x, 180.491f + pos.y), ImColor(10, 131, 255, 255), "S");
        draw->AddText(fire, 20.f, ImVec2(16.000f + pos.x, 220.491f + pos.y), ImColor(10, 131, 255, 255), "D");
        






// ================================================================================================================================ //  
    
        //Close menu
        ImGui::SetCursorPos({565, 3.5});
        if (ImGui::Button("X", ImVec2(30, 30))) {

        MenDeal = false;


        }
  // ================================================================================================================================ //
           
        // Save settings
        ImGuiStyle* Style = &ImGui::GetStyle();
        Style->Colors[ImGuiCol_Button]                 = ImColor(28, 28, 30, 255);
        Style->Colors[ImGuiCol_ButtonHovered]          = ImColor(28, 28, 30, 255);
        Style->Colors[ImGuiCol_ButtonActive]           = ImColor(255, 255, 255, 200);




//Phiên bản app
NSString *safari_localizedShortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:NSSENCRYPT("CFBundleShortVersionString")];

std::string Version([safari_localizedShortVersion UTF8String]);

//tên của app
NSString *safari_displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:NSSENCRYPT("CFBundleDisplayName")];

std::string sName([safari_displayName UTF8String]);

        
        ImGui::SetCursorPos({223, 12});

ImGui::Text(ENCRYPT(">. %s || %s"), sName.c_str(), Version.c_str());

        
/*
        
        //tab 1
        switch (tab_count) {
        case 0:
        ImGui::SetCursorPos({220, 45});
        ImGui::BeginChild("Main", ImVec2(370, 300)); {
         ImGui::TextColored(ImColor(18, 140, 0), "#Ẩn tên phải bật ở sảnh, còn lại bật tắt được"); 

ImGui::Checkbox("Hack Map", &bHackMap);
ImGui::Checkbox("Unlock Skin", &unlockskin);  
ImGui::Checkbox("AntiHooK", &AntiHooK);
ImGui::Checkbox("Show Cooldown", &showcd);  
 ImGui::SliderInt(("Camera"), &CameraHeight, 0.0f, 15.0f);
    }
        ImGui::EndChild();  



			}
			
			  switch (tab_count) {
        case 1:
        ImGui::SetCursorPos({220, 45});
        ImGui::BeginChild("ESP", ImVec2(370, 300)); {
				ImGui::Checkbox(("Draw"), &ESPEnable);
                ImGui::SameLine();
                ImGui::Checkbox(("Invisible"), &IgnoreInvisible);
                 //ImGui::Checkbox(("Stream Mode"), &StreamerMode);
							ImGui::SameLine();
                ImGui::Checkbox(("Draw Lines"), &PlayerLine);

                ImGui::Checkbox(("Draw Health"), &PlayerHealth);
                ImGui::SameLine();
                ImGui::Checkbox(("Draw Icon"), &Drawicon);
                ImGui::SameLine();
                ImGui::Checkbox(("Draw Box"), &PlayerBox);
                ImGui::Checkbox(("Draw Distance"), &PlayerDistance);
                ImGui::SameLine();
                ImGui::Checkbox(("Draw Info"), &PlayerName);
                ImGui::SameLine();
								
                ImGui::Checkbox("Show Minimap", &showMinimap);
					}
        ImGui::EndChild();  



			}
switch (tab_count) {
    case 2:
    ImGui::SetCursorPos({220, 45});
    ImGui::BeginChild("Aimbot", ImVec2(370, 300), true, ImGuiWindowFlags_HorizontalScrollbar); 
    {
			ImGui::Checkbox(("Aimbot"), &AimSkill);
                if(AimSkill){
                ImGui::Text("Aim Mode:");
                ImGui::Text("Red is invisible, Green is visible");
							}
			    ImGui::EndChild();  
}//end tab3
        
        
switch (tab_count) {
            case 3:
            ImGui::SetCursorPos({220, 45});
            ImGui::BeginChild("Setting", ImVec2(370, 300)); {
							ImGui::RadioButton("Team Blue", &minimapType, 1); 
                ImGui::SameLine();
                ImGui::RadioButton("Team Red", &minimapType, 2);
                if (minimapType == 1) {
                minimapRotation = -0.6f;
                } else if (minimapType == 2) {
                minimapRotation = -180.0f;
                }
                ImGui::SliderFloat("Minimap X", &minimapPos.x, 0.0f, kWidth);
                ImGui::SliderFloat("Minimap Y", &minimapPos.y, 0.0f, kHeight);
                ImGui::SliderFloat("Minimap Rotation", &minimapRotation, -180.0f, 180.0f, "%.1f degrees");
                ImGui::SliderFloat("icon Scale", &iconScale, 0.1f, 5.0f);
                ImGui::SliderFloat("Minimap Scale", &minimapScale, 0.1f, 5.0f);
                if (ImGui::Button(("Save Setting"))) {
									 [saveSetting setBool:bHackMap forKey:@"bHackMap"];
                        [saveSetting setBool:ESPEnable forKey:@"ESPEnable"];
                        [saveSetting setBool:PlayerLine forKey:@"PlayerLine"];
                        [saveSetting setBool:PlayerBox forKey:@"PlayerBox"];
                        [saveSetting setBool:PlayerHealth forKey:@"PlayerHealth"];
                        [saveSetting setBool:PlayerName forKey:@"PlayerName"];
                        [saveSetting setBool:PlayerDistance forKey:@"PlayerDistance"];
                        [saveSetting setBool:PlayerAlert forKey:@"PlayerAlert"];
                        [saveSetting setBool:Drawicon forKey:@"Drawicon"];
                        [saveSetting setBool:ESPCount forKey:@"ESPCount"];
                        [saveSetting setBool:IgnoreInvisible forKey:@"IgnoreInvisible"];
												 [saveSetting setBool:showcd forKey:@"showcd"];
												  [saveSetting setBool:unlockskin forKey:@"unlockskin"];
                        [saveSetting setBool:AimSkill forKey:@"AimSkill"];
												[saveSetting setFloat:CameraHeight forKey:@"CameraHeight"];
                        NSArray *minimapPosArray = @[@(minimapPos.x), @(minimapPos.y)];
                        [saveSetting setObject:minimapPosArray forKey:@"minimapPos"];
                        [saveSetting setFloat:minimapRotation forKey:@"minimapRotation"];
                        [saveSetting setFloat:minimapScale forKey:@"minimapScale"];
                        [saveSetting setFloat:iconScale forKey:@"iconScale"];
                        [saveSetting setFloat:tablePosX forKey:@"tablePosX"];
                        [saveSetting setFloat:tablePosY forKey:@"tablePosY"];
                        [saveSetting setFloat:tableScale forKey:@"tableScale"];
                        [saveSetting synchronize];
                }
                ImGui::SameLine();
                if (ImGui::Button(oxorany("Use Backup"))) {
									bHackMap = [saveSetting boolForKey:@"bHackMap"];
                        ESPEnable = [saveSetting boolForKey:@"ESPEnable"];
                        PlayerLine = [saveSetting boolForKey:@"PlayerLine"];
                        PlayerBox = [saveSetting boolForKey:@"PlayerBox"];
                        PlayerHealth = [saveSetting boolForKey:@"PlayerHealth"];
                        PlayerName = [saveSetting boolForKey:@"PlayerName"];
                        PlayerDistance = [saveSetting boolForKey:@"PlayerDistance"];
                        PlayerAlert = [saveSetting boolForKey:@"PlayerAlert"];
                        Drawicon = [saveSetting boolForKey:@"Drawicon"];
                        ESPCount = [saveSetting boolForKey:@"ESPCount"];
                        IgnoreInvisible = [saveSetting boolForKey:@"IgnoreInvisible"];
												showcd = [saveSetting boolForKey:@"showcd"];
												unlockskin = [saveSetting boolForKey:@"unlockskin"];
                        AimSkill = [saveSetting boolForKey:@"AimSkill"];
												CameraHeight = [saveSetting floatForKey:@"CameraHeight"];
                        NSArray *minimapPosArray = [saveSetting objectForKey:@"minimapPos"];
                        minimapPos = ImVec2([minimapPosArray[0] floatValue], [minimapPosArray[1] floatValue]);
                        minimapRotation = [saveSetting floatForKey:@"minimapRotation"];
                        minimapScale = [saveSetting floatForKey:@"minimapScale"];
                        iconScale = [saveSetting floatForKey:@"iconScale"];
                        tablePosX = [saveSetting floatForKey:@"tablePosX"];
                        tablePosY = [saveSetting floatForKey:@"tablePosY"];
                        tableScale = [saveSetting floatForKey:@"tableScale"];
                }
                ImGui::SameLine(); 

                if (ImGui::Button(("Reset Setting"))) {
									bHackMap = true;
                        ESPEnable = true;
                        PlayerLine = false;
                        PlayerBox = false;
                        PlayerHealth = false;
                        PlayerName = false;
                        PlayerDistance = false;
                        PlayerAlert = false;
                        Drawicon = false;
                        ESPCount = false;
                        IgnoreInvisible = false;
												showcd = true;
												unlockskin = true;
                        AimSkill = false;
												CameraHeight = 2;
                        minimapPos = ImVec2(46.176f, 2.371f);
                        minimapRotation = -0.6f;
                        iconScale = 1.902f;
                        minimapScale = 1.262f;
											}

				ImGui::EndChild();
    





           }//end 
        
*/

				
                }
                ImGui::End();
            }
        }

        // Khởi tạo lại các giá trị style một lần
        ImDrawList* draw_list = ImGui::GetBackgroundDrawList();
        ImGuiStyle& style = ImGui::GetStyle();
        ImVec4* colors = style.Colors;

        style.WindowRounding = 10.000f;
        style.WindowTitleAlign = ImVec2(0.490f, 0.520f);
        style.ChildRounding = 6.000f;
        style.PopupRounding = 6.000f;
        style.FrameRounding = 6.000f;
        style.FrameBorderSize = 1.000f;
        style.GrabRounding = 12.000f;
        style.TabRounding = 7.000f;
        style.ButtonTextAlign = ImVec2(0.510f, 0.490f);
        style.Alpha = 0.9f;

        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}


- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size 
{

}

@end

