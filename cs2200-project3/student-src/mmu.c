#include "mmu.h"
#include "pagesim.h"
#include "va_splitting.h"
#include "swapops.h"
#include "stats.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

/* The frame table pointer. You will set this up in system_init. */
fte_t *frame_table;

/**
 * --------------------------------- PROBLEM 2 --------------------------------------
 * Checkout PDF sections 4 for this problem
 * 
 * In this problem, you will initialize the frame_table pointer. The frame table will
 * be located at physical address 0 in our simulated memory. You should zero out the 
 * entries in the frame table, in case for any reason physical memory is not clean.
 * 
 * HINTS:
 *      - mem: Simulated physical memory already allocated for you.
 *      - PAGE_SIZE: The size of one page
 * ----------------------------------------------------------------------------------
 */
void system_init(void) {
    // TODO: initialize the frame_table pointer.
    frame_table = (fte_t *)mem;
    //clear entries - size of frame table = page size
    memset(frame_table, 0, PAGE_SIZE);
    frame_table->protected = 1;
}

/**
 * --------------------------------- PROBLEM 5 --------------------------------------
 * Checkout PDF section 6 for this problem
 * 
 * Takes an input virtual address and performs a memory operation.
 * 
 * @param addr virtual address to be translated
 * @param access 'r' if the access is a read, 'w' if a write
 * @param data If the access is a write, one byte of data to written to our memory.
 *             Otherwise NULL for read accesses.
 * 
 * HINTS:
 *      - Remember that not all the entry in the process's page table are mapped in. 
 *      Check what in the pte_t struct signals that the entry is mapped in memory.
 * ----------------------------------------------------------------------------------
 */
uint8_t mem_access(vaddr_t addr, char access, uint8_t data) {
    // TODO: translate virtual address to physical, then perform the specified operation
    vpn_t vpn = vaddr_vpn(addr);
    uint16_t offset = vaddr_offset(addr);
    pte_t *pte =  (pte_t*) (mem + (PTBR*PAGE_SIZE)) + vpn;
    if (!pte->valid) {
        page_fault(addr);
    }
    paddr_t paddr = (paddr_t) ((pte->pfn)*PAGE_SIZE + offset);
    frame_table[pte->pfn].referenced = 1;


    /* Either read or write the data to the physical address
       depending on 'rw' */
    stats.accesses += 1;
    if (access == 'r') {
        return mem[paddr];
    } else {
        //stats.writebacks += 1;
        pte->dirty = 1;
        mem[paddr] = data;
        return mem[paddr];
    }

    return 0;
}