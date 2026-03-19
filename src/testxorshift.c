/*- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ---------------------*/

#include "xorshift.h"
#include <stdio.h>

/*- LOCAL VARIABLES --------------------------------------------------------*/

static unsigned char all_ok = 1;
static unsigned char seen[256];

/*- GLOBVAL FUNCTIONS ------------------------------------------------------*/

int main(void)
{
    short i;
    short count;

    printf("XorShift Tests\n");

    /* Test 1: Range - all 256 values */
    printf("Test Range...");
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
        printf("OK\n");
    }
	else
	{
        printf("FAIL (%d/256)\n", count);
        all_ok = 0;
    }

    /* Test 2: Period - 255 unique values */
    printf("Test Period...");
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
        printf("OK\n");
    }
	else
	{
        printf("FAIL (%d/255)\n", count);
        all_ok = 0;
    }

	printf("RESULT: %s\n", all_ok ? "SUCCESS" : "FAILURE");

    if (all_ok)
    {
        FILE * f = fopen("obj/xorshift.ok", "w");
        
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

    return all_ok ? 0 : 3;
}

/*--------------------------------------------------------------------------*/
