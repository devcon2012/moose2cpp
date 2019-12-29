#  test role doku
#
#
use strict ;
use warnings ;

use Test::More tests => 12 ;

use Try::Tiny ;
use Data::Dumper ;

BEGIN { use_ok('PPI::Transform::CPP') } ;

my $t ;

$t = PPI::Transform::CPP -> new ;
ok ( $t, 'CPP Transform created' ) ;

my $text = <<'END_TEXT';
package _SAMPLE ;
use strict ;

use Moose::Role ;

requires 'virtual_method' ;

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

ok ( $c -> name eq '_SAMPLE', 'class name ok' ) ;
ok ( $c -> is_role, 'class is a role' ) ;


my $func = $c -> methods ;
# print STDERR Dumper ($func) ;
ok ( 2 == scalar @$func, '2 methods' ) ;
    {
    my $f = $func -> [0] ;
    # print STDERR Dumper ($f) ;
    ok ( $f -> name eq 'virtual_method', '  name of virtual ok' ) ;
    ok ( $f -> is_undocumented, '  not documented' ) ;
    ok ( $f -> is_virtual,      '  virtual method' ) ;
    ok ( $f -> type eq 'void',  '  return void' ) ;
    my $args = $f -> arguments ;
    ok ( 0 == scalar @$args,    '  no arguments' ) ;
    }