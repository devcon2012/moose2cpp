#  test member doku
#
#
use strict ;
use warnings ;

use Test::More tests => 33 ;

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
    documentation => 'PRIVATEBLADOKU',
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    builder => '_bla_builder',
    );

class_has 'bla' => 
    (
    documentation => 'PUBLICBLADOKU',
    is => 'ro',
    isa => 'Int',
    );

# docu in comment
# in two lines
has 'morebla' => 
    (
    is => 'rw',
    isa => 'Maybe[Bla::Fasel]',
    );

1 ;
END_TEXT

$t -> transform_text ( $text ) ;
ok ( $t, 'perl transformed' ) ;
ok ( 1 == $t -> count_classes, 'created one class' ) ;
my $c = $t -> classes -> [0] ;

ok ( $c -> name eq 'SAMPLE', 'class name ok' ) ;

my $var = $c -> members ;
# print STDERR Dumper ($var) ;
ok ( 3 == scalar @$var, '3 members' ) ;

    {
    my $v = $var -> [0] ;
    ok (   $v -> name eq '_bla',   '1 _bla:  name ok' ) ;
    ok (   $v -> type eq 'STR',    '  type ok' ) ;
    ok (   $v -> is_private,       '  private' ) ;
    ok ( ! $v -> is_undocumented,  '  documented' ) ;
    ok ( ! $v -> is_static,        '  not static' ) ;
    ok ( ! $v -> is_const,         '  not const' ) ;
    like ( $v -> doku, qr/TEBLADO/,      '  documented text') ;
    like ( $v -> doku, qr/lazy/,         '  lazyness documented') ;
    like ( $v -> doku, qr/_bla_builder/, '  builder documented') ;
    }

    {
    my $v = $var -> [1] ;
    ok (   $v -> name eq 'bla',    '2 bla:  name ok' ) ;
    ok (   $v -> type eq 'INT',    '  type ok' ) ;
    ok ( ! $v -> is_private,       '  not private' ) ;
    ok ( ! $v -> is_undocumented,  '  documented' ) ;
    ok (   $v -> is_static,        '  is static' ) ;
    ok (   $v -> is_const,         '  is const' ) ;
    like ( $v -> doku, qr/ICBLADO/,        '  documented text') ;
    unlike ( $v -> doku, qr/lazy/,         '  no lazyness documented') ;
    unlike ( $v -> doku, qr/_bla_builder/, '  no builder documented') ;
    }

    {
    my $v = $var -> [2] ;
    # print STDERR Dumper ($v) ;
    ok (   $v -> name eq 'morebla', '3 bla:  name ok' ) ;
    ok (   $v -> type eq 'MAYBE_BLA_FASEL_',     '  type ok' ) ;
    ok ( ! $v -> is_private,        '  not private' ) ;
    ok ( ! $v -> is_undocumented,   '  documented' ) ;
    ok ( ! $v -> is_static,         '  is static' ) ;
    ok ( ! $v -> is_const,          '  is const' ) ;
    like ( $v -> doku, qr/in comm/,        '  documented text') ;
    unlike ( $v -> doku, qr/lazy/,         '  no lazyness documented') ;
    unlike ( $v -> doku, qr/_bla_builder/, '  no builder documented') ;
    }

