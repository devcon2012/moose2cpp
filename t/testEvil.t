#  test pathological cases
#
#
use strict ;
use warnings ;

use Test::More tests => 15 ;

use Try::Tiny ;
use Data::Dumper ;

BEGIN { use_ok('PPI::Transform::CPP') } ;

my $t ;

$t = PPI::Transform::CPP -> new ;
ok ( $t, 'CPP Transform created' ) ;

my $text = <<'END_TEXT';
package SAMPLE ;
use strict ;

use Moose ;
extends 'SAMPLE_PARENT' ;


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
    }

1 ;
END_TEXT

$t -> transform_text ( $text ) ;
ok ( $t, 'perl transformed' ) ;
ok ( 1 == $t -> count_classes, 'created one class' ) ;
my $c = $t -> classes -> [0] ;

ok ( $c -> name eq 'SAMPLE', 'class name ok' ) ;


my $func = $c -> methods ;
#print STDERR Dumper ($func) ;
ok ( 1 == scalar @$func, '1 method' ) ;
    {
    my $f = $func -> [0] ;
    ok ( $f -> name eq 'package2class',    '  name ok' ) ;
    ok ( ! $f -> is_undocumented,  '  is documented' ) ;
    ok ( $f -> type eq 'OBJECT',  '  return HASHREF' ) ;

    my $args = $f -> arguments ;
    ok ( 1 == scalar @$args,    '  five arguments apart from $self' ) ;
        {
        my $a = $args -> [0] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'package',       '    argument name ok:a' ) ;
        ok ( $a->type eq 'OBJECT',  '      argument type SCALAR' ) ;
        ok ( $a->is_const,          '      argument is const' ) ;
        ok ( ! $a->is_undocumented, '      argument documented' ) ;
        ok ( ! $a->is_optional,      '      argument not optional' ) ;
        }
    }
