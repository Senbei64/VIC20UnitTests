/*- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ---------------------*/

#include "physics.h"
#include <conio.h>
#include <stdio.h>

/*- MACROS -----------------------------------------------------------------*/

#define ACC(x, y) ((unsigned short)x << 8 | (y & 0xFF)) & 0xFFFF
#define RESET()   zPhyVelX = 0; zPhyVelY = 0
#define SHOW(msg) printf(msg); print_vel(); printf("\n")

/*- LOCAL VARIABLES --------------------------------------------------------*/

static unsigned char all_ok = 1;

/*- LOCAL FUNCTIONS --------------------------------------------------------*/

static void print_vel(void)
{
	printf("(%02X.%02X,%02X.%02X)",
		zPhyVelX >> 8 & 0xFF,
		zPhyVelX & 0xFF,
		zPhyVelY >> 8 & 0xFF,
		zPhyVelY & 0xFF);
}

static void check(const char *label, short exp_x, short exp_y)
{
	printf("%s ", label);
	print_vel();

	if (zPhyVelX == exp_x && zPhyVelY == exp_y)
	{
		printf("  OK\n");
	}
	else
	{
		printf("  FAIL\n");
		all_ok = 0;
	}
}

/*- GLOBVAL FUNCTIONS ------------------------------------------------------*/

void main(void)
{
    short i;

	clrscr();
    printf("Physics Tests\n");

	RESET();
	phy_add_acc(ACC(0x00, 0x00));      /* (0,0) */
	check("T1 +(0,0)        ", 0x0000, 0x0000);

	RESET();
	phy_add_acc(ACC(0x40, 0x00));      /* (+0.5, 0) */
	check("T2 +(.5,0)       ", 0x0080, 0x0000);

	RESET();
	phy_add_acc(ACC(0x00, 0xC0));      /* (0, -0.5) */
	check("T3 +(0,-.5)      ", 0x0000, (short)0xFF80);

	RESET();
	phy_add_acc(ACC(0x40, 0x00));      /* +0.5 */
	phy_add_acc(ACC(0xC0, 0x00));      /* -0.5 */
	check("T4 +(.5,-.5)     ", 0x0000, 0x0000);

	RESET();
	for (i = 0; i < 128; ++i)
		phy_add_acc(ACC(0x01, 0x00));  /* 1/128 × 128 = +1.0 */
	check("T5 +(1/128 x128) ", 0x0100, 0x0000);

	RESET();
	phy_add_acc(ACC(0x7F, 0x00));      /* max positive */
	phy_add_acc(ACC(0x01, 0x00));      /* epsilon */
	check("T6 max+epsilon   ", 0x0100, 0x0000);

    RESET();
    for (i = 0; i < 128; ++i)
        phy_add_acc(ACC(0xFF, 0x00));
    check("T7 -(1/128 x128) ", 0xFF00, 0x0000);

    RESET();
    for (i = 0; i < 128; ++i)
        phy_add_acc(ACC(0x01, 0x00));
    for (i = 0; i < 128; ++i)
        phy_add_acc(ACC(0xFF, 0x00));
    check("T8 +1/128 -1/128 ", 0x0000, 0x0000);

    RESET();
    phy_add_acc(ACC(0xC0, 0x40));
    phy_add_acc(ACC(0x40, 0xC0));
    check("T9 -0.5 +0.5     ", 0x0000, 0x0000);

    RESET();
    phy_add_acc(ACC(0x7F, 0x00));
    phy_add_acc(ACC(0x01, 0x00));
    check("T10 carry frac   ", 0x0100, 0x0000);

    RESET();
    phy_add_acc(ACC(0x40, 0xC0));
    phy_add_acc(ACC(0x40, 0xC0));
    check("T11 XY mix       ", 0x0100, 0xFF00);

	printf("\nRESULT: %s\n", all_ok ? "SUCCESS" : "FAILURE");
	
	if (all_ok)
	{
		FILE *f = fopen("obj/physics.ok", "w");
		
		if (!f)
		{
			printf("file open error\n");
		}
		else
		{
			fprintf(f, "all tests passed\n");
			fclose(f);
		}
	}
	
	cgetc();
}

/*--------------------------------------------------------------------------*/
