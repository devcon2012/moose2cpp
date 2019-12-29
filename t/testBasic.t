#  test basic translate
#
#
use strict ;
use warnings ;

use Test::More tests => 34 ;

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

has '_bla' => 
    (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    builder => '_bla_builder',
    );

class_has 'bla' => 
    (
    is => 'ro',
    isa => 'Int',
    );

sub fasel
    {
    my ($self, $a) = @_ ;
    }
1 ;
END_TEXT

$t -> transform_text ( $text ) ;
ok ( $t, 'perl transformed' ) ;
ok ( 1 == $t -> count_classes, 'created one class' ) ;
my $c = $t -> classes -> [0] ;

ok ( $c -> name eq 'SAMPLE', 'class name ok' ) ;

my $p = $c -> parents ;
# print STDERR Dumper ($p) ;
ok ( 1 == scalar @$p, '1 parent' ) ;
ok ( 'SAMPLE_PARENT' eq $p -> [0], '  parent name ok' ) ;

my $inc = $c -> includes ;
# print STDERR Dumper ($inc) ;
ok ( 3 == scalar @$inc, '3 includes' ) ;
ok ( 'SAMPLE_PARENT' eq $inc -> [2], '  parent include ok' ) ;

my $var = $c -> members ;
# print STDERR Dumper ($var) ;
ok ( 2 == scalar @$var, '2 members' ) ;
    {
    my $v = $var -> [0] ;
    ok (   $v -> name eq '_bla',   '1 _bla:  name ok' ) ;
    ok (   $v -> type eq 'STR',    '  type ok' ) ;
    ok (   $v -> is_private,       '  private' ) ;
    ok (   $v -> is_undocumented,  '  not documented' ) ;
    ok ( ! $v -> is_static,        '  not static' ) ;
    ok ( ! $v -> is_const,         '  not const' ) ;
    like ( $v -> doku, qr/lazy/,         '  lazyness documented') ;
    like ( $v -> doku, qr/_bla_builder/, '  builder documented') ;
    }
    {
    my $v = $var -> [1] ;
    ok (   $v -> name eq 'bla',    '1 bla:  name ok' ) ;
    ok (   $v -> type eq 'INT',    '  type ok' ) ;
    ok ( ! $v -> is_private,       '  not private' ) ;
    ok (   $v -> is_undocumented,  '  not documented' ) ;
    ok (   $v -> is_static,        '  is static' ) ;
    ok (   $v -> is_const,         '  is const' ) ;
    unlike ( $v -> doku, qr/lazy/,         '  no lazyness documented') ;
    unlike ( $v -> doku, qr/_bla_builder/, '  no builder documented') ;
    }

my $func = $c -> methods ;
#print STDERR Dumper ($func) ;
ok ( 1 == scalar @$func, '1 method' ) ;
    {
    my $f = $func -> [0] ;
    ok ( $f -> name eq 'fasel', '  name ok' ) ;
    ok ( $f -> is_undocumented, '  not documented' ) ;
    ok ( $f -> type eq 'void',  '  return void' ) ;
    my $args = $f -> arguments ;
    ok ( 1 == scalar @$args,    '  one argument apart from $self' ) ;
    my $a = $args -> [0] ;
    ok ( $a->name eq 'a',       '    argument name ok' ) ;
    ok ( $a->type eq 'UNKNOWN', '    argument type unknown' ) ;
    ok ( $a->is_undocumented,   '    argument undocumented' ) ;
    }
