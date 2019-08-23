// Constants used in the MMU and needed in other modules

// Flags in each page table entry
localparam MMU_PTE_P=  12'h001;         // Page is present
localparam MMU_PTE_W=  12'h002;         // Page is writeable
localparam MMU_PTE_U=  12'h004;         // Page available in user & kernel mode
localparam MMU_PTE_A=  12'h020;         // Page has been accessed
localparam MMU_PTE_D=  12'h040;		// Page is dirty

// Commands accepted by the MMU
localparam MMU_READ=    4'h0;           // Read from a virtual address
localparam MMU_WRITE=   4'h1;           // Write to a virtual address
localparam MMU_SPAG=    4'h2;           // Enable or disable paging
localparam MMU_PDIR=    4'h3;           // Set the page directory address

// Errors returned by the MMU
localparam MMU_NOERR=   4'h0;           // No error
localparam MMU_FWPAGE=  4'h1;           // Page fault on write
localparam MMU_FRPAGE=  4'h2;           // Page fault on read
localparam MMU_BADCMD=  4'h3;           // Unrecognised command
localparam MMU_BADPDIR= 4'h3;		// Invalid page directory address
