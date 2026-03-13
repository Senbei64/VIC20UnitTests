/*- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ---------------------*/

#ifndef PHISICS_H
#define PHISICS_H

/*- GLOBAL ZERO PAGE VARIABLES ---------------------------------------------*/

/* Velocity vector */
extern short zPhyVelX;
#pragma zpsym("zPhyVelX")
extern short zPhyVelY;
#pragma zpsym("zPhyVelY")

/*- GLOBAL FUNCTIONS -------------------------------------------------------*/

/* Add passed acceleration vector to velocity */
void phy_add_acc(unsigned short acc);

#endif /* PHISICS_H */
/*--------------------------------------------------------------------------*/
