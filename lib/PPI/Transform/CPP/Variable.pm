package PPI::Transform::CPP::Variable ;

#
#
#

use strict ;
use warnings ;
use namespace::autoclean ;
use Devel::StealthDebug ENABLE => $ENV{dbg_source} ;

use Data::Dumper ;
use Moose ;
use Try::Tiny ;

extends 'PPI::Transform::CPP::Symbol' ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# 
has 'type' => (
    documentation   => 'variable type, derived from isa (members) or !$%@ (method arguments)',
    is              => 'rw',
    isa             => 'Str',
    default         => ''
) ;
 
# 
has 'is_const' => (
    documentation   => 'derived from is ->ro (members) or listed in out (method arguments)',
    is              => 'rw',
    isa             => 'Bool',
    default         => 1
) ;

# 
has 'is_optional' => (
    documentation   => 'set true for [] denoted method arguments',
    is              => 'rw',
    isa             => 'Bool',
    default         => 0,
) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# --------------------------------------------------------------------------------------------------------------------
# as_cpp - render variable as cpp
#
#
#
sub as_cpp 
    {
    my ( $self ) = @_ ; 
    my $ret = '' ;

    my $type = $self -> type ;
    if ( $self -> is_const )
        {
        $ret .= "const $type " . $self -> name  ;
        }
    else
        {
        $ret .= "$type & " . $self -> name  ;
        }
    if ( $self -> is_optional )
        {
        $ret .= ' = "default" ' ;
        }
    return $ret ;
    }

# --------------------------------------------------------------------------------------------------------------------
# set_type - set variable type from singe character
#
# in    $type   '$', '%' or the like ...
#
sub set_type 
    {
    my ( $self, $type ) = @_ ; 

    $type //= '' ;
    if ( $type eq '$' )
        {
        $self -> type ( 'SCALAR' );
        }
    elsif ( $type eq '%')
        {
        $self -> type ( 'HASHREF' );
        }
    elsif ( $type eq '@')
        {
        $self -> type ( 'ARRAYREF' );
        }
    elsif ( $type eq '<')
        {
        $self -> type ( 'OBJECT' );
        }
    elsif ( $type eq '!')
        {
        $self -> type ( 'BOOLEAN' );
        }
    else
        {
        $self -> type ( 'UNKNOWN' );
        }

    return ;
    }


__PACKAGE__ -> meta -> make_immutable ;

1;


=head1 NAME


=head1 USAGE


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
