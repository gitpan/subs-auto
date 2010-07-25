/* This file is part of the subs::auto Perl module.
 * See http://search.cpan.org/dist/subs-auto/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = subs::auto      PACKAGE = subs::auto

PROTOTYPES: ENABLE

void
_delete_sub(SV *fqn)
PREINIT:
 GV *gv;
PPCODE:
 gv = gv_fetchsv(fqn, 0, 0);
 if (gv) {
  CV *cv = GvCV(gv);
  GvCV(gv) = NULL;
  SvREFCNT_dec(cv);
 }
 XSRETURN(0);
