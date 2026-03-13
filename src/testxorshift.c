/*- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ---------------------*/

#include "xorshift.h"
#include <conio.h>
#include <stdio.h>

/*- LOCAL VARIABLES --------------------------------------------------------*/

static unsigned char all_ok = 1;
static unsigned char seen[256];

/*- GLOBVAL FUNCTIONS ------------------------------------------------------*/

void main(void)
{
    short i;
    short count;

    clrscr();
    printf("XorShift Tests\n");

    /* Test 1: Range - all 256 values */
    printf("\nTest Range...");
    for (i = 0; i < 256; ++i)
	{
        seen[i] = 0;
    }

    for (i = 0; i < 256; ++i)
	{
        zXShSeed = (unsigned char)i;
        xsh_next();
        seen[zXShSeed] = 1;
    }

    count = 0;
    for (i = 0; i < 256; ++i)
	{
        if (seen[i])
			++count;
    }

    if (count == 256)
	{
        printf("OK");
    }
	else
	{
        printf("FAIL (%d/256)", count);
        all_ok = 0;
    }

    /* Test 2: Period - 255 unique values */
    printf("\nTest Period...");
    for (i = 0; i < 256; ++i)
	{
        seen[i] = 0;
    }

    zXShSeed = 1;
    count = 0;

    for (i = 0; i < 256; ++i)
	{
        if (seen[zXShSeed])
			break;
		
        seen[zXShSeed] = 1;
        ++count;
        xsh_next();
    }

    if (count == 255)
	{
        printf("OK");
    }
	else
	{
        printf("FAIL (%d/255)", count);
        all_ok = 0;
    }

	printf("\nRESULT: %s\n", all_ok ? "SUCCESS" : "FAILURE");

    if (all_ok)
    {
        FILE *f = fopen("obj/xorshift.ok", "w");

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
