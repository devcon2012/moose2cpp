package  PPI::Transform::CPP::_Comment2Doxy ;

use strict ;
use warnings ;

use Devel::StealthDebug ENABLE => $ENV{dbg_source} ;

use Moose::Role ;

# -----------------------------------------------------------------------------
# comment2doxy - transform plain text comment to doxygen
#
#
sub comment2doxy
    {

    } 



1;

=pod

Perl comment example:

# -----------------------------------------------------------------------------
# function_name - one line description
#   more on this function
#
# in    $scalar     scalar beispiel
#                   explained in all detail
#       %hashref    hash beispiel
#       @arrayref   array beispiel
#
# out   %hashref    non-const hash bespiel
#
# ret   true/false  predicate whether this worked or not

transformed to:

/**
# function_name - one line dscription
#   more on this function
#
# @param scalar   scalar beispiel
# @param hashref  hash beispiel (non-const hash bespiel)
# @param arrayref array beispiel
# @return 

BOOL function_name (SCALAR const scalar, HASH &hashref, ARRAY const arrayref) ;

=cut

 