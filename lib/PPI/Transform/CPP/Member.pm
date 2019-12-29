 
package PPI::Transform::CPP::Member ;

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

extends 'PPI::Transform::CPP::Variable' ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# 
has 'is_static' => (
    documentation   => '',
    is              => 'rw',
    isa             => 'Bool',
    default         => 0
) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# --------------------------------------------------------------------------------------------------------------------
# _map_moose_type - map moose isa to a type
#
# in    $isa        eg Maybe[Str], HashRef, ...
#
# ret   $type

sub _map_moose_type 
    {
    my ( $self, $isa ) = @_ ; 
    my $type = $isa ;

    $type =~ s/\[/_/g;
    $type =~ s/\]/_/g;
    $type =~ s/\:\:/_/g;
    return uc $type ;
    }

# --------------------------------------------------------------------------------------------------------------------
# as_cpp - render this as cpp + doxygen comments
#
#
#
sub as_cpp 
    {
    my ( $self, $indent ) = @_ ; 

    my $name    = $self -> name ;
    my $doku    = $self -> doku || '' ;
    $doku      .= '(UNDOCUMENTED)' if ( $self -> is_undocumented ) ;
    my $type    = $self -> type . ' ' ;
    my $const   = ( $self -> is_const  ? 'const '  : '' ) ;
    my $static  = ( $self -> is_static ? 'static ' : '' ) ;
    my $tab = ' ' x $indent ;

    my $ret = '' ; 
    $ret .= "$tab/// \@var $name $doku\n" if ( $doku ) ;
    $ret .= "$tab$static$type$const$name;\n" ;
    return $ret ;
    }


# -----------------------------------------------------------------------------
# new_from_node - class factory method
#
# in    <node>  use node 
#
#

sub new_from_node 
    {
    my ( $class, $node ) = @_ ; 

    my $cstr = '' ;
    my $c = $node -> previous_sibling ;
    while ( $c )
        {
        if ( ref $c eq 'PPI::Token::Comment' )
            {
            my $txt = $c -> {content} ;
            $txt =~ s/\#//;
            $txt =~ s/^\s+//;
            $txt =~ s/\n//g;
            $cstr = " $cstr" if ( $cstr && $txt ) ;
            $cstr = "$txt$cstr" if ( $txt ) ;
            $c = $c -> previous_sibling ;
            }
        else 
            {
            $c = undef ;
            }
        }

    my $name = $node -> child(2) -> string ;
    my $m = PPI::Transform::CPP::Member -> new (name => $name ) ;
    $m -> doku_add ($cstr) if ( $cstr ) ;

    my $l = $node -> find_first ( 'PPI::Structure::List' ) ;
    # print STDERR "LLL " . Dumper ($l) ;
    if ( $l )
        {
        my $e = $l -> find_first ( 'PPI::Statement::Expression' ) ;
        # print STDERR "EEE " . Dumper ($e) ;
        if ( $e )
            {
            my $cursor = $e -> child ( 0 ) ;
            while ( $cursor )
                {
                my $entry = $cursor -> literal ;
                #print STDERR "Entry $entry\n" ;
                $cursor = $cursor -> snext_sibling ; # must be =>
                $cursor = $cursor -> snext_sibling ;
                my $val = $cursor -> {content} ;

                $val = $cursor -> string 
                    if ( $cursor -> can('string') ) ;

                if ( 'documentation' eq $entry )
                    {
                    $m -> doku_add ( $val ) ;
                    }
                elsif ( 'is' eq $entry )
                    {
                    $m -> is_const ('ro' eq $val ? 1 : 0 ) ;
                    }
                elsif ( 'lazy' eq $entry )
                    {
                    $m -> doku_add ( ' (lazy) ' , 1) ;
                    }
                elsif ( 'builder' eq $entry )
                    {
                    $m -> doku_add ( " (build by $val) ", 1 ) ;
                    }
                elsif ( 'isa' eq $entry )
                    {
                    $m -> type ( $m -> _map_moose_type ( $val ) ) ;
                    }

                $cursor = $cursor -> snext_sibling 
                    if ($cursor) ; # must be ,

                $cursor = $cursor -> snext_sibling 
                    if ($cursor ) ;
                }
            }
        }
    #print STDERR "new_from_node " . Dumper ($m) ;
    return $m;
    }


__PACKAGE__ -> meta -> make_immutable ;

1;


=head1 NAME

PPI::Transform::CPP::Member - represent a class member

=head1 USAGE

my $m1 = PPI::Transform::CPP::Member -> new ( name => 'member_variable' ) ;

my $node = PPI::Transform::... ;
my $m2 = PPI::Transform::CPP::Member -> new_from_node ( $node ) ;
print "declared as class_has " if ( $m2 -> is_static ) ;
print "declared as private " if ( $m2 -> is_private ) ;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
