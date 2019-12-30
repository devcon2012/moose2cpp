 
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
            $self -> set_undocumented ( 0 ) ;
            $d .= $1 ;
            }
        elsif ( /^\#\s+(.+)/ )
            {
            $d .= " $1" ;
            }
        }
    $self -> doku ( $d ) ;

    my %optional ;
    my %type ;
    my $indent = 0 ;
    my %in_vars ;
    my $last ;
    foreach ( @$in )
        {
        my ($ws, $dmy, $opt1, $type, $name, $opt2, $ws2, $desc) 
            = /^\#(\s+(in\s+)?)(\[?)([\!\$\%\@\<]?)(\w+)\>?(\]?)(\s*)(.*)/ ;
        $dmy //= '' ;
        if ( $type )
            {           
            # 0 initial whitespace, possibly with 'in'
            # 1
            # 2 maybe [
            # 3 maybe one of !$%@<
            # 4 variable name
            # 5 maybe ]
            # 6 whitespace after variable
            # 7 variable desc
            $in_vars{$name}     = $desc || '' ;
            $type{$name}        = $type ;
            $optional{$name}    = 1 if ($opt1 && $opt2) ;
            $indent             = length($ws.$dmy.$opt1.$type.$name.$opt2.$ws) - 3 ;
            $last               = $name ;
            }
        else
            {
            die ("bad input $_") if ( ! $indent || ! $last ) ;
            $in_vars{$last}     .= $desc || '' ;
            }
        }

    $indent = 0 ; 
    $last = '';
    my %out_vars ;
    foreach ( @$out )
        {
        my ($ws, $dmy, $opt1, $type, $name, $opt2, $ws2, $desc) 
            = /^\#(\s+(out\s+)?)(\[?)([\!\$\%\@\<]?)(\w+)\>?(\]?)(\s*)(.*)/ ;
        if ( $type )
            {           
            $out_vars{$name}    = $desc || '' ;
            $type{$name}        = $type ;
            $optional{$name}    = 1 if ($opt1 && $opt2) ;
            $indent             = length($ws.$dmy.$opt1.$type.$name.$opt2.$ws) - 3 ;
            $last               = $name ;
            }
        else
            {
            die ("bad input $_") if ( ! $indent || ! $last ) ;
            $out_vars{$last}     .= $desc || '' ;
            }
        }

    my %ret_vars ;
    $last = undef ;
    foreach ( @$ret )
        {
        my ($wsl, $dmyl, $lst1, $list, $lst2, $wsl2, $ldesc) 
            = /^\#(\s+(ret\s+)?)(\()(\S+)(\))(\s*)(.*)/ ;

        my ($ws, $dmy, $type, $name, $ws2, $ndesc) 
            = /^\#(\s+(ret\s+)?)([\!\$\%\@\<]?)(\w+)\>?(\s+)(.*)/ ;

        my ($wsc, $cont) 
            = /^\#(\s+)(\S+.*)/ ;
        $dmy //= '' ;

        if ( $type && $name )
            {
            $ret_vars{'SCALAR'}  = $name ;
            $ret_vars{'TYPE'}    = $type ;
            $indent = length ( $ws.$dmy.$type.$name.$ws2 ) - 3 ;
            $self -> add_return_type_doku ( $ndesc ) ;
            $last = 'SCALAR' ;
            }
        elsif ( $list )
            {
            $ret_vars{'LIST'} = $list ;
            $indent = length ( $ws.$dmyl.$lst1.$list.$lst2.$wsl2 ) - 3 ;
            $self -> add_return_type_doku ( $ldesc ) ;
            $last = 'LIST' ;
            }
        else
            {
            if ( length($ws) > $indent && $last ) # continuation of previous line ?
                {
                $self -> add_return_type_doku ( " $cont" ) ;            
                }
            }
        #print STDERR Dumper (\%ret_vars) ;
        }

    if ( $ret_vars{'TYPE'} )
        {
        if ( $ret_vars{'LIST'} )
            {
            $self -> set_type ( $ret_vars{'TYPE'} );
            $self -> type ( $self -> type . '_OR_LIST' ) ;
            my $list = $ret_vars{'LIST'};
            my $d = " (list context returns $list)";
            $self -> add_return_type_doku ( $d ) ;
            }
        else
            {
            $self -> set_type ( $ret_vars{'TYPE'} ) ;
            }
        }
    elsif ( $ret_vars{'LIST'} )
        {
        $self -> type ( 'LIST' ) ;
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
            $arg -> is_optional ( 1 ) if (exists $optional{$n}) ;
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

    my $state = 'DESCP' ;
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
        next if ( /~~~~~~~~~~~~~~~~~/ ) ;
        $state = 'DESC'  if ( /^\#\s*\S+/ && ( $state eq 'DESCP')  ) ;
        $state = 'DESC2' if ( /^\#\s*$/ && ( $state eq 'DESC')  ) ;
        $state = 'IN'    if ( /^\#\s+in\s+[\<\[\!\$\%\@]/  && ( $state eq 'DESC2')  ) ;
        $state = 'OUT'   if ( /^\#\s+out\s+[\<\[\!\$\%\@]/ && ( $state eq 'IN' || $state eq 'DESC2')  ) ;
        $state = 'RET'   if ( /^\#\s+ret\s+[\<\(\[\!\$\%\@]/ ) ;
        push @{$h->{$state}}, $_ ;
        }
    #print STDERR Dumper ($h) ;
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
    my $alist = ( join ',',          @alist ) || '';
    my $dlist = ( join $tab . '///', @dlist ) || '';


    #$ret .= join ' ', @{$self -> plaintext_doku} ;

    my $doku = $self -> doku ;
    $ret .= $tab . "/// \@brief $doku\n" if ( $doku ) ;
    $ret .= $tab . "/// \@brief DOCUMENTATION MISSING\n" if ( $self -> is_undocumented ) ;


    $doku = $self -> return_type_doku ;
    $ret .= $tab . "/// \@return $doku\n"  if ( $doku ) ;

    $ret .= $tab . '///' . $dlist if ($dlist) ;
    $ret .= $tab . $self -> type . ' ' . $self -> name . "($alist);\n\n" ;

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
        last if ( $content =~ /~~~~~~~~~~~~/ ) ;
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
