#!/usr/bin/perl

#
# ABSTRACT: convert a perl/moose source to hpp for doxygen
# PODNAME: moose2cpp
# 

use strict ;
use warnings ;

use FindBin;
use lib "$FindBin::Bin/../blib/lib";

use File::Find ;
use File::Basename ;
use File::Path qw( make_path );

use Try::Tiny ;
use Getopt::Long ;
use Pod::Usage;
use Data::Dumper ;

use PPI::Transform::CPP ;


our ( $opt_verbose, $opt_help, $opt_basedir, $opt_out ) =
    ( undef,        undef,     'doxy'      , '' ) ;

our %options = 
        (
        'help|h'            => \$opt_help,
        'out|o=s'           => \$opt_out,
        'verbose|v'         => \$opt_verbose,
        ) ;

sub logger
    {
    my ($msg) = @_ ;
    print STDERR "$msg\n" if ( $opt_verbose ) ;
    return ;
    }

GetOptions( %options ) or pod2usage(2) ;

pod2usage(1) if ($opt_help);
#pod2usage(2) unless (@ARGV); # need a topic

my $file_or_dir = shift ;
my @filenames ;

if ( -d $file_or_dir )
    {

    logger("transform modules in $file_or_dir") ;

    find( 
        sub 
            { 
            push @filenames, $File::Find::name if ( /\.pm$/ ) ; 
            } ,
        $file_or_dir
        ) ;
    }

if ( -f $file_or_dir )
    {
    logger("transform $file_or_dir") ;
    push @filenames, $file_or_dir ;
    }

if ( ! scalar @filenames )
    {
    die "No such file/dir: $file_or_dir" ;
    }

if ( ! -d $opt_basedir )
    {
    make_path ( $opt_basedir ) 
        or die "Cannot create dir $opt_basedir: $!" ;
    }

foreach my $file_name ( @filenames )
    {
    my $outfn = $opt_basedir . '/' . $file_name ;
    $outfn =~ s/\.pm$/\.hpp/ ;

    my $outdir = dirname ( $outfn ) ;
    if ( ! -d $outdir )
        {
        make_path ( $outdir ) 
            or die "Cannot create dir $outdir: $!" ;    
        }

    logger("working on $file_name -> $outfn ") ;

    my $outfh;
    if ( $opt_out && ( $opt_out ne '-' ) )
        {
        open ( $outfh, ">>", $opt_out )
            or die ("Cannot open $opt_out to append: $!") ;
        }
    else
        {
        open ( $outfh, ">", $outfn )
            or die ("Cannot open $outfh to write: $!") ;
        }

    my $xout = \*STDOUT ;
    $xout = $outfh if ( $opt_out ne '-') ;

    my $t = PPI::Transform::CPP -> new ;
    try 
        {
        $t -> transform ( $file_name, $xout ) ;
        }
    catch
        {
        print STDERR "ERROR in $file_name: \n" ;
        print STDERR Dumper($_) ;
        } ;

    close ( $outfh ) if ( $outfh ) ;
    }

my $default_doxy = "$opt_basedir/Doxyfile" ;
if ( -f $default_doxy )
    {
    logger("Running doxygen in $opt_basedir") ;
    system("cd '$opt_basedir' ; doxygen Doxyfile") ;
    }
else
    {
    logger("No $default_doxy") ;
    }

logger("End.") ;
