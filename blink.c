/*============================================================================*
 *
 * UPDI Programmer for ATMega32U
 *
 * ==========================================================================
 *   Wiring:
 * ----------------------
 *
 * Pinout:
 *                       ┌─────────┐
 *                      ─┤ 1    28 ├─
 *                          ....
 *                      ─┤ ?     ? ├─
 *                      ─┤ ?     ? ├─
 *                       └─────────┘
 *
 *----------------------------------------------------------------------------*/

#include <util/delay.h>

#include <avr/io.h>
#include <avr/interrupt.h>


int main()
{
    PORTD.DIRSET = PIN7_bm;
    for( ;; ) {
        PORTD.OUTSET = PIN7_bm;
        _delay_ms(500);
        PORTD.OUTCLR = PIN7_bm;
        _delay_ms(500);
    }
    return 0;
}

