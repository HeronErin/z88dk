;
;	CPC Maths Routines
;
;	August 2003 **_|warp6|_** <kbaccam /at/ free.fr>
;
;	$Id: log10.asm,v 1.4 2016-06-22 19:50:49 dom Exp $
;

        SECTION smc_fp
        INCLUDE "cpcmath.inc"

        PUBLIC  log10
        PUBLIC  log10c

        EXTERN  get_para

log10:
        call    get_para
log10c:
        FPCALL  (CPCFP_FLO_LOG10)
        ret
