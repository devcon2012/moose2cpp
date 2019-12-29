 
package PPI::Transform::CPP::Method ;

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

use PPI::Transform::CPP::Variable ;
extends 'PPI::Transform::CPP::Variable' ;
with 'PPI::Transform::CPP::_Comment2Doxy' ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'plaintext_doku' => (
    documentation   => 'ecos style plaintext doku',
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    default         => sub { [] } , 
) ;

has 'return_type_doku' => (
    documentation   => 'method_return_type',
    is              => 'rw',
    isa             => 'Str',
    default         => '' , 
) ;

has 'is_virtual' => (
    documentation   => 'predicate for virtual methods',
    is              => 'ro',
    isa             => 'Bool',
    default         => 0 , 
) ;

has 'arguments' => (
    documentation   => 'ecos style plaintext doku',
    is              => 'rw',
    isa             => 'ArrayRef[PPI::Transform::CPP::Variable]',
    default         => sub { [] } , 
    traits          => ['Array'],
    handles => 
        {
        all_arguments    => 'elements',
        add_argument     => 'push',
        count_arguments  => 'count',
        },
) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#

# --------------------------------------------------------------------------------------------------------------------
# add_return_type_doku - combine plaintext_doku and arguments
#
# in $txt           Docu text to add
#    [$is_auto]     if true, symbol is not set to documented
#
#
sub add_return_type_doku
    {
    my ( $self, $doku, $is_auto) = @_ ;
    my $d = $self -> return_type_doku ;
    $d .= ' ' if ( $d ) ;
    $self -> set_undocumented ( 0 ) if ( ! $is_auto );
    return $self -> return_type_doku( $d . $doku );
    }


# --------------------------------------------------------------------------------------------------------------------
# _consolidate_arguments - combine plaintext_doku and arguments
#
#
#
sub _consolidate_arguments 
    {
    my ( $self ) = @_ ; 
    my ( $description, $in, $out, $ret ) = $self -> parse_plaintext_doku ;

    my $name = $self -> name ;
    my $d = '' ;
    foreach ( @$description )
        {
        if ( /^#\s+\Q$name\E\s*\-(.+)/ )
            {
            $d .= $1 ;
            }
        elsif ( /^\#\s+(.+)/ )
            {
            $d .= " $1" ;
            }
        }
    $self -> doku ( $d ) ;

    my %type ;
    my $indent = 0 ;
    my %in_vars ;
    my $last ;
    foreach ( @$in )
        {
        if ( /^#(\s+in\s+)(.)([^\s+]+)(\s*)(.*)/ )
            {
            $in_vars{$3} = $5 || '' ;
            $type{$3} = $2 ;
            $indent = length ($1) + length ($2) + length ($3) + length ($4) - 3 ;
            $last = $3 ;
            }
        elsif ( /^#(\s+)(.)([^\s+]+)(\s+)(.+)/ )
            {
            die ("bad in $_") if ( ! $indent ) ;
            if ( length($1) > $indent ) # continuation of previous line ?
                {
                $in_vars{$last} .= " $2$3$4$5" ;            
                }
            else
                {
                $in_vars{$3} = $5 || '' ;
                $type{$3} = $2 ;
                $indent = length ($1) + length ($2) + length ($3) + length ($4) - 3 ;
                $last = $3 ;
                }
            }
        }

    $indent = 0 ;
    my %out_vars ;
    foreach ( @$out )
        {
        if ( /^#(\s+out\s+)(.)([^\s+]+)(\s*)(.*)/ )
            {
            $out_vars{$3} = $5 || '' ;
            $type{$3} = $2 ;
            $indent = length ($1) + length ($2) + length ($3) + length ($4) - 3 ;
            $last = $3 ;
            }
        elsif ( /^#(\s+)(.)([^\s+]+)(\s+)(.+)/ )
            {
            die ("bad out $_") if ( ! $indent ) ;
            if ( length($1) > $indent ) # continuation of previous line ?
                {
                $out_vars{$last} = " $2$3$4$5" ;            
                }
            else
                {
                $out_vars{$3} = $5 || '' ;
                $type{$3} = $2 ;
                $indent = length ($1) + length ($2) + length ($3) - 3 ;
                $last = $2 ;
                }
            }
        }

    my %ret_vars ;
    foreach ( @$ret )
        {
        if ( /^#(\s+ret\s+)(\(?)(.)([^\s\(]+)(\)?)(\s+)(.+)/ )
            {
            print STDERR "A: >$1-$2-$3-$4-$5-$6-$7<\n";
            if ($2) # list case
                {
                print STDERR "A, initial list\n" ;
                $ret_vars{'LIST'} = $4 ;
                $indent = length ($1) + length ($2) + length ($3) + length ($4) + length ($5) + length ($6) - 3 ;
                my $d = "list context returns $2$3$4$5$6 $7";
                $self -> add_return_type_doku ( $d ) ;
                $last = 'LIST' ;
                }
            else
                {
                print STDERR "A, initial scalar\n" ;
                $ret_vars{'SCALAR'} = $4 ;
                $ret_vars{'TYPE'} = $3 ;
                $indent = length ($1) + length ($2) + length ($3) + length ($4) + length ($5) + length ($6) - 3 ;
                $self -> add_return_type_doku ( $7 ) ;
                $last = 'SCALAR' ;
                }
            }
        elsif  ( /^#(\s+)(\(?)(.)([^\s\(]+)(\)?)(\s+)(.+)/ )
            {
            print STDERR "B: >$1-$2-$3-$4-$5-$6-$7<\n";
            if ( length($1) > $indent ) # continuation of previous line ?
                {
                print STDERR "B, continuation\n" ;
                $self -> add_return_type_doku ( " $2$3$4$5$6$7" ) ;            
                }
            elsif ($2) # list case
                {
                print STDERR "B, list\n" ;
                $ret_vars{'LIST'} = $4 ;
                $indent = length ($1) + length ($2) + length ($3) + length ($4) + length ($5) + length ($6) - 3 ;
                my $d = "list context returns $2$3$4$5$6 $7";
                $self -> add_return_type_doku ( $d ) ;
                $last = 'LIST' ;
                }
            else
                {
                print STDERR "B, scalar\n" ;
                $ret_vars{'SCALAR'} = $4 ;
                $ret_vars{'TYPE'} = $3 ;
                $indent = length ($1) + length ($2) + length ($3) + length ($4) + length ($5) + length ($6) - 3 ;
                $self -> add_return_type_doku ( $7 ) ;
                $last = 'SCALAR' ;
                }
            }
        print STDERR Dumper (\%ret_vars) ;
        }

    if ( $ret_vars{'TYPE'} )
        {
        if ( $ret_vars{'LIST'} )
            {
            $self -> set_type ( $ret_vars{'TYPE'} );
            $self -> type ( $self -> type . '_OR_LIST' ) ;
            }
        else
            {
            $self -> set_type ( $ret_vars{'TYPE'} ) ;
            }
        }
    elsif ( $ret_vars{'LIST'} )
        {
        $self -> set_type ( 'LIST' ) ;
        }
    else
        {
        $self -> type ( 'void' ) ;
        }

    if ( $self -> count_arguments )
        {
        # found a my ( $self, ...) = @_ ;
        foreach my $arg ( $self -> all_arguments )
            {
            my $n = $arg -> name ;
            $arg -> set_type ( $type{$n} ) ;
            $arg -> is_const ( 0 ) if (exists $out_vars{$n}) ;
            $arg -> doku_add ( $in_vars{$n} ) if (exists $in_vars{$n}) ;
            $arg -> doku_add ( $out_vars{$n} ) if (exists $out_vars{$n}) ;
            }
        }
    else
        {
        #
        }

    return ;
    }


# ---------------------------------------------------------------------------------------------------------------------
# parse_plaintext_doku - combine plaintext_doku and arguments
#
#
#
sub parse_plaintext_doku 
    {
    my ( $self ) = @_ ; 
    my $plain = $self -> plaintext_doku ;
    my ( @description, @in, @out, @ret ) ;

    my $state = 'DESC' ;
    my $h = { 
            DESC => \@description,
            IN   => \@in,
            OUT  => \@out,
            RET  => \@ret,
            }; 

    foreach ( @$plain )
        {
        next if ( ! $_ ) ;
        next if ( /-----------------/ ) ;
        $state = 'IN'  if ( /^\#\s+in\s+/  ) ;
        $state = 'OUT' if ( /^\#\s+out\s+/ ) ;
        $state = 'RET' if ( /^\#\s+ret\s+/ ) ;
        push @{$h->{$state}}, $_ ;
        }

    return ( \@description, \@in, \@out, \@ret ) ; 
    }


# --------------------------------------------------------------------------------------------------------------------
# as_cpp - 
#
# in    $indent - indent level
#
# ret $cpp - method declaration as cpp

sub as_cpp 
    {
    my ( $self, $indent) = @_ ; 

    my $tab     = ' ' x $indent ;
    my $ret     = '' ;
    my $name    = $self -> name ; 
    if ( $self -> is_virtual )
        {
        return "${tab}virtual void ${name}() = 0;";
        }

    my (@alist, @dlist) ;
    foreach my $arg ( $self -> all_arguments )
        {
        push @alist, $arg -> as_cpp ;
        push @dlist, ' @var ' . $arg->name . ' ' . $arg -> doku . "\n" ;
        }
    my $alist = (join ',',   @alist) || '';
    my $dlist = ( join $tab . '///', @dlist) || '';


    $ret .= join '', @{$self -> plaintext_doku} ;

    my $doku = $self -> doku ;
    $ret .= $tab . "/// \@brief $doku\n" if ( $doku ) ;
    $ret .= $tab . "/// \@brief DOCUMENTATION MISSING\n" if ( $self -> is_undocumented ) ;


    $doku = $self -> return_type_doku ;
    $ret .= $tab . "/// \@return $doku\n"  if ( $doku ) ;

    $ret .= $tab . '///' . $dlist . "\n" ;
    $ret .= $tab . $self -> type . ' ' . $self -> name . "($alist);\n" ;

    return $ret ;
    }
# --------------------------------------------------------------------------------------------------------------------
# new_virtual - class factory method for virtual methods
#
# in    <node>  use node 
#
#
sub new_virtual 
    {
    my ( $class, $name ) = @_ ; 
    my $m = __PACKAGE__ -> new ( name => $name, is_virtual => 1, type => 'void') ;
    return $m ;
    }
# --------------------------------------------------------------------------------------------------------------------
# new_from_node - class factory method
#
# in    <node>  use node 
#
#
sub new_from_node 
    {
    my ( $class, $node ) = @_ ; 

    my $method = PPI::Transform::CPP::Method -> new ;

    $method -> name ( $node -> name ) ;

    my $cursor = $node -> previous_sibling  ;
    my $type = ref $cursor ;
    my @doku ;

    while ( $type eq 'PPI::Token::Whitespace' || 
            $type eq 'PPI::Token::Comment' )
        {
        my $content = $cursor -> content ;
        push @doku, $content ;
        $cursor = $cursor -> previous_sibling ;
        $type = ref $cursor ;
        }

    # save plaintext doku in proper order 
        {
        my $doku = $method -> plaintext_doku ;
        for( my $i = @doku; $i>0; $i--)
            {
            push @$doku, $doku[$i] ;
            }
        }

    my $variables = $node      -> find_first('PPI::Statement::Variable') ;
    $variables    = $variables -> find_first('PPI::Structure::List') ;
    if ( $variables )
        {
        $variables    = ($variables -> children)[0] ;

        my @symbols ;
        while ( 1 )
            {
            if ( 'PPI::Token::Symbol' eq ref $variables )
                {
                push @symbols, $variables -> symbol ;
                }
            $variables = $variables -> next_sibling ;
            last if ( ! $variables ) ;
            }
        my $ml = $node -> find_first('PPI::Statement::Variable') -> find_first('PPI::Statement::Expression');
        for (my $m = $ml -> child(0);
                $m;
                $m = $m -> next_sibling ) 
            {
            if ( 'PPI::Token::Symbol' eq ref $m
                && '$self' ne $m -> content )
                {
                my ($name) = $m -> content =~ /^.(.+)/ ;
                $method -> add_argument ( PPI::Transform::CPP::Variable -> new ( name => $name ) ) ;
                }
            }
        }
    $method -> _consolidate_arguments() ;
    return $method ;
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
