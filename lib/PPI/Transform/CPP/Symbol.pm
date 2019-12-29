package PPI::Transform::CPP::Symbol ;

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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# 
has 'name' => (
    documentation   => '',
    is              => 'rw',
    isa             => 'Str',
    default         => ''
) ;

# 
has 'is_undocumented' => (
    documentation   => 'predicate if doku missing, set to false as docu is added',
    is              => 'rw',
    writer          => 'set_undocumented',
    isa             => 'Bool',
    default         => 1
) ;

# 
has 'doku' => (
    documentation   => 'collected documentation for this symbol',
    is              => 'rw',
    isa             => 'Str',
    default         => ''
) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# --------------------------------------------------------------------------------------------------------------------
# doku_add -add doku for this symbol
#
# in $txt           Docu text to add
#    [$is_auto]     if true, symbol is not set to documented
#

sub doku_add
    {
    my ( $self, $txt, $is_auto) = @_ ;
    my $d = $self -> doku ;
    $d .= ' ' if ( $d ) ;
    $self -> set_undocumented ( 0 ) if ( ! $is_auto );
    #!dump($d, $txt, $is_auto)!
    return $self -> doku ( $d . $txt ) ;
    }

# --------------------------------------------------------------------------------------------------------------------
# is_private - perl convention is names starting with _ are private
#
# ret   true/false
#
sub is_private 
    {
    my ( $self ) = @_ ; 

    return $self -> name =~ /^_/ ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1;


=head1 NAME

PPI::Transform::CPP::Symbol - base class for all symbols

=head1 USAGE

my $s = PPI::Transform::CPP::Symbol -> new ( name => 'symbol_name' ) ;
$s -> doku_add ( 'This is the doku for this symbol' ) ;
print "symbol not documented!!" if ( $self -> is_undocumented ) ;
print "symbol not exported" if ( $self -> is_private ) ;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
