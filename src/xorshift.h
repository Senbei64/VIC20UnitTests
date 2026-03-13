/*- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ---------------------*/

#ifndef XORSHIFT_H
#define XORSHIFT_H

/*- GLOBAL ZERO PAGE VARIABLES ---------------------------------------------*/

extern unsigned char zXShSeed;
#pragma zpsym("zXShSeed")

/*- GLOBAL FUNCTIONS -------------------------------------------------------*/

unsigned char xsh_next(void);

#endif /* XORSHIFT_H */
/*--------------------------------------------------------------------------*/
