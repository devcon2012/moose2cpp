#  test method doku
#
#
use strict ;
use warnings ;

use Test::More tests => 18 ;

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

# --------------------------------------------------------------------------------------------------------------------
# fasel - sample method documentation
#   in several lines with links to wiki [[test]] and CRM ebos#123456
#
# in    $a  this is the first argument
#
# out   %b  will be changed and receive output
#
sub fasel
    {
    my ($self, $a, $b) = @_ ;
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
    ok ( $f -> name eq 'fasel', '  name ok' ) ;
    ok ( $f -> is_undocumented, '  not documented' ) ;
    ok ( $f -> type eq 'void',  '  return void' ) ;
    my $args = $f -> arguments ;
    ok ( 2 == scalar @$args,    '  one argument apart from $self' ) ;
        {
        my $a = $args -> [0] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'a',       '    argument name ok:a' ) ;
        ok ( $a->type eq 'SCALAR',  '      argument type SCALAR' ) ;
        ok ( $a->is_const,          '      argument is const' ) ;
        ok ( ! $a->is_undocumented, '      argument documented' ) ;
        }

        {
        my $a = $args -> [1] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'b',       '    argument name ok:b' ) ;
        ok ( $a->type eq 'HASHREF', '      argument type HASHREF' ) ;
        ok ( ! $a->is_const,        '      argument is not const' ) ;
        ok ( ! $a->is_undocumented,   '    argument documented' ) ;
        }
    }