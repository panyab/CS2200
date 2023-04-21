#include "mmu.h"
#include "pagesim.h"
#include "swapops.h"
#include "stats.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

/**
 * --------------------------------- PROBLEM 6 --------------------------------------
 * Checkout PDF section 7 for this problem
 * 
 * Page fault handler.
 * 
 * When the CPU encounters an invalid address mapping in a page table, it invokes the 
 * OS via this handler. Your job is to put a mapping in place so that the translation 
 * can succeed.
 * 
 * @param addr virtual address in the page that needs to be mapped into main memory.
 * 
 * HINTS:
 *      - You will need to use the global variable current_process when
 *      altering the frame table entry.
 *      - Use swap_exists() and swap_read() to update the data in the 
 *      frame as it is mapped in.
 * ----------------------------------------------------------------------------------
 */
void page_fault(vaddr_t addr) {
   // TODO: Get a new frame, then correctly update the page table and frame table
   stats.page_faults += 1;
   vpn_t vpn = vaddr_vpn(addr);
   pte_t *pte =  (pte_t*) (mem + (PTBR*PAGE_SIZE)) + vpn;
   pfn_t newpfn = free_frame();

   pte->pfn = newpfn;
   pte->valid = 1;
   pte->dirty = 0;

   frame_table[newpfn].protected = 0;
   frame_table[newpfn].mapped = 1; 
   frame_table[newpfn].referenced = 1;
   frame_table[newpfn].vpn = vpn;
   frame_table[newpfn].process = current_process;

   paddr_t *new_frame = (paddr_t*) (mem + (PAGE_SIZE * newpfn));
   if(swap_exists(pte)) {
      swap_read(pte, new_frame);
   } else {
      memset(new_frame, 0, PAGE_SIZE);
   }
   
}

#pragma GCC diagnostic pop
