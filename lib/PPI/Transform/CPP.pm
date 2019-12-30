package PPI::Transform::CPP ;

use strict ;
use warnings ;
use utf8 ;
use namespace::autoclean ;
use Devel::StealthDebug ENABLE => $ENV{dbg_source} ;

use Data::Dumper ;
use Moose ;
use Try::Tiny ;
use PPI ;
use PPI::Dumper ;
use File::Temp qw/ tempfile /;

use PPI::Transform::CPP::Class ;


our $VERSION  = '0.5' ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has '_source_filename' => (
    documentation   => '',
    is              => 'rw',
    isa             => 'Str',
    default         => '',
) ;

has 'ppi' => (
    documentation   => 'perl "parser" ',
    is              => 'rw',
    isa             => 'PPI::Document',
    lazy            => 1,
    builder         => '_build_ppi',
) ;
sub _build_ppi
    {
    my $self = shift ;
    return PPI::Document -> new ( $self -> _source_filename ) ;
    }

has 'classes' => (
    documentation   => 'classes constructed so far',
    is              => 'rw',
    isa             => 'ArrayRef[PPI::Transform::CPP::Class]',
    default         => sub { [] } ,
    traits          => ['Array'],
    handles => 
        {
        all_classes    => 'elements',
        add_class      => 'push',
        count_classes  => 'count',
        },

) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------------------------------------------------------------------------
# write_classes - write classes to file 
#
# in    $fh file handle 
#
#
sub write_classes
    {
    my ($self, $fh) = @_ ;

    foreach my $c ( $self -> all_classes )
        {
        $c -> write_class ( $fh ) ;
        }
    return ;
    }

# -----------------------------------------------------------------------------
# package2class - transform PPI package to CPP Class
#
# in    <package>   a PPI::Statement::Package 
#
# ret   <class>     PPI::Transform::CPP::Class representing this package as cpp
#
sub package2class
    {
    my ($self, $package) = @_ ;
    my $class = PPI::Transform::CPP::Class -> new ( name => $package -> namespace ) ; 

    while ( 1 )
        {
        $package = $package -> next_sibling() ;
        last if ( ! $package ) ;
        last if ( 'PPI::Statement::Package' eq ref $package ) ;

        $class -> add_include_node ( $package )
            if ( 'PPI::Statement::Include' eq ref $package ) ;

        $class -> add_statement_node ( $package )
            if ( 'PPI::Statement' eq ref $package ) ;

        $class -> add_sub_node ( $package )
            if ( 'PPI::Statement::Sub' eq ref $package ) ;

        }

    return $class ;
    }


# -----------------------------------------------------------------------------
# transform_text - transform perl source
#
# in    $text - source text
#       [$out]  - output filehandle, no output if missing
#

sub transform_text
    {
    my ($self, $text, $out) = @_ ;

    my ($fh, $filename) = tempfile();
    print $fh $text ;
    close ($fh) ;

    $self -> transform ($filename, $out) ;
    unlink ($filename) ;

    return ;
    }


# -----------------------------------------------------------------------------
# transform - transform perl source from file
#
# in    $source - source fn
#       [$out]  - output filehandle, no output if missing
#

sub transform
    {
    my ($self, $source, $out) = @_ ;
    #!dump($source)!

    $self -> _source_filename( $source ) ;

    my $package     = $self -> ppi -> find_first('PPI::Statement::Package') ;
    # Dump the document
    if ( 0 )
        {
        my $dumper      = PPI::Dumper -> new( $self -> ppi ) ;
        $dumper -> print ( \*STDERR ) ;
        }
    die ("No package") if ( ! $package ) ;

    my $classes = $self -> classes ;

    while ( 1 )
        {
        my $class = $self -> package2class ( $package ) ;
        push @$classes, $class ;
        while ( 1 )
            {
            $package = $package -> next_sibling() ;
            last if ( ! $package ) ;
            last if ( 'PPI::Statement::Package' eq ref $package ) ;
            }
        last if ( ! $package ) ;
        }

    $self -> write_classes ( $out )
        if ( $out ) ;

    return ;
    }



__PACKAGE__ -> meta -> make_immutable ;

1;


=head1 NAME

Moose2Cpp - transform perl parse tree to cpp headers (to be processed by doxygen)


=head1 USAGE

see moose2cpp.pl


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
