#
# Moose2cpp - parsing moose perl code and write c++ headers
#
#   (c) Klaus Ramstöck klaus@ramstoeck.name 2019
#
# You can use and distribute this software under the same conditions as perl
#

use 5.018001;
use ExtUtils::MakeMaker;
use File::Find ;
use Cwd ;

our @modules ;

sub wanted
    {
    push @modules, $File::Find::name
        if ( /\.p[ml]$/ ) ;
    push @modules, $File::Find::name
        if ( /\.t$/ ) ;
    }

our @manifest ;
sub UpdateManifest
    {
    push @manifest, glob '*.md' ;
    push @manifest, glob '*.pl' ;
    push @manifest, 'LICENSE' ;
    push @manifest, 'Makefile.PL' ;
    push @manifest, 'Changes' ;
    push @manifest, '.gitignore' ;
    push @manifest, 'doxy/.gitignore' ;
    push @manifest, 'doxy/Doxyfile' ;


    find ( sub { push @manifest, $File::Find::name if ( /\.p[lm]$/ ) ; },
            'lib', 'bin'
            );

    find ( sub { push @manifest, $File::Find::name if ( /\.t$/ ) ; },
            't'
            );


    open ( my $fh, ">", "MANIFEST.new")
        or die "cannot open MANIFEST.new: $!";
    print $fh join ("\n", sort { fc($a) cmp fc($b) } @manifest);
    print $fh "\n";
    close $fh ;
    my $ret = system ("diff MANIFEST MANIFEST.new") ;
    if ( $ret )
        {
        print "!!!! Manifest changed - review !!!!\n" ;
        }
    else
        {
        print "No changes to manifest\n" ;
        unlink "MANIFEST.new" ;
        }
    }

sub CritiqueModules
    {
    find(\&wanted, 'lib', 'bin');

    print STDERR "Run perlcritic on each module:\n";
    
    foreach my $m (@modules)
        {
        system("perlcritic --stern $m")       # --stern ./. --gentle 
            and print STDERR "ERROR in $m\n" ;
        }

    @modules = () ;
    find(\&wanted, 't' );

    print STDERR "Run perlcritic on each test:\n";
    
    foreach my $m (@modules)
        {
        system("perlcritic --theme tests $m")
            and print STDERR "ERROR in $m\n" ;
         }
    
    }

sub PrintInfo
    {
    print "Run some tests verbose:\n" ;
    print "make test TEST_VERBOSE=1 TEST_FILES='t/testInfoBites.t'\n" ;
    print "Run one test for debugging:\n" ;
    print "make testdb TEST_FILE=t/testInfoBites.t\n" ;
    }

WriteMakefile(
    NAME              => 'Moose2Cpp',
    VERSION_FROM      => 'lib/PPI/Transform/CPP.pm', 
    ABSTRACT_FROM     => 'lib/PPI/Transform/CPP.pm', 
    PREREQ_PM         => {
                            'Data::Dumper' => 2,
                            'Devel::StealthDebug' => 1,
                            'Getopt::Long' => 2,
                            'Moose' => 2, 
                            'PPI' => 1,
                            'Moose::Role' => 1,
                            'MooseX::ClassAttribute' => 0.2,
                            'Try::Tiny' => 0.28,
                         }, # e.g., Module::Name => 1.1
    AUTHOR            => 'Klaus Ramstöck <klaus@ramstoeck.name>',
    LICENSE           => 'perl',
);

CritiqueModules() ;

UpdateManifest() ;

PrintInfo() ;