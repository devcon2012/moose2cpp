#!/usr/bin/perl

#
# ABSTRACT: convert a perl/moose source to hpp for doxygen
# PODNAME: moose2cpp
# 

use strict ;
use warnings ;

use FindBin;
use lib "$FindBin::Bin/../blib/lib";

use Try::Tiny ;
use Getopt::Long ;
use Pod::Usage;
use Data::Dumper ;

use PPI::Transform::CPP ;

 
our ( $opt_verbose, $opt_help ) =
    ( undef,        undef     ) ;

our %options = 
        (
        'verbose|v'         => \$opt_verbose,
        'help|h'            => \$opt_help
        ) ;

GetOptions( %options ) or pod2usage(2) ;

pod2usage(1) if ($opt_help);
#pod2usage(2) unless (@ARGV); # need a topic

my $file_name = shift ;

my $t = PPI::Transform::CPP -> new ;
try 
    {
    $t -> transform ( $file_name, \*STDOUT ) ;
    }
catch
    {
    print "ERROR: \n" ;
    print STDERR Dumper($_) ;
    }
