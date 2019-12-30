#  test method doku
#
#
use strict ;
use warnings ;

use Test::More tests => 41 ;

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
#
# fasel - sample method documentation, next line starts with 'in' to try confuse parser
#   in several lines with links to wiki [[test]] and CRM ebos#123456
#
# in    $a    this is the first argument
#       !c    bool example
#             continued in this line
#       [@d]  array example
#       [<e>]   object example
#
# out   %b    will be changed and receive output
#
# ret   %x    return example hashref
#
sub fasel
    {
    my ($self, $a, $b, $c, $d, $e) = @_ ;
    }

# --------------------------------------------------------------------------------------------------------------------
#
# fasel2 - return list
#
# ret   ($x)    list of only one scalar
#
sub fasel2
    {
    my ($self) = @_ ;
    }

# --------------------------------------------------------------------------------------------------------------------
#
# fasel3 - return scalar or list
#
# ret   (!x)    list of only one scalar (wantarray)
#        <x>     scalar only if scalar context
#
sub fasel3
    {
    my ($self) = @_ ;
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
ok ( 3 == scalar @$func, '3 methods' ) ;
    {
    my $f = $func -> [0] ;
    ok ( $f -> name eq 'fasel',    '  name ok' ) ;
    ok ( ! $f -> is_undocumented,  '  is documented' ) ;
    ok ( $f -> type eq 'HASHREF',  '  return HASHREF' ) ;

    my $args = $f -> arguments ;
    ok ( 5 == scalar @$args,    '  five arguments apart from $self' ) ;
        {
        my $a = $args -> [0] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'a',       '    argument name ok:a' ) ;
        ok ( $a->type eq 'SCALAR',  '      argument type SCALAR' ) ;
        ok ( $a->is_const,          '      argument is const' ) ;
        ok ( ! $a->is_undocumented, '      argument documented' ) ;
        ok ( ! $a->is_optional,      '      argument not optional' ) ;
        }

        {
        my $a = $args -> [1] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'b',       '    argument name ok:b' ) ;
        ok ( $a->type eq 'HASHREF', '      argument type HASHREF' ) ;
        ok ( ! $a->is_const,        '      argument is not const' ) ;
        ok ( ! $a->is_undocumented, '      argument documented' ) ;
        ok ( ! $a->is_optional,      '      argument not optional' ) ;
        }

        {
        my $a = $args -> [2] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'c',        '    argument name ok:c' ) ;
        ok ( $a->type eq 'BOOLEAN',  '      argument type BOOLEAN' ) ;
        ok (   $a->is_const,         '      argument is const' ) ;
        ok ( ! $a->is_undocumented,  '      argument documented' ) ;
        ok ( ! $a->is_optional,      '      argument not optional' ) ;
        }

        {
        my $a = $args -> [3] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'd',        '    argument name ok:d' ) ;
        ok ( $a->type eq 'ARRAYREF', '      argument type ARRAYREF' ) ;
        ok (   $a->is_const,         '      argument is const' ) ;
        ok ( ! $a->is_undocumented,  '      argument documented' ) ;
        ok (   $a->is_optional,      '      argument optional' ) ;
        }

        {
        my $a = $args -> [4] ;
        #print STDERR Dumper ($a) ;
        ok ( $a->name eq 'e',        '    argument name ok:e' ) ;
        ok ( $a->type eq 'OBJECT',   '      argument type OBJECT' ) ;
        ok (   $a->is_const,         '      argument is const' ) ;
        ok ( ! $a->is_undocumented,  '      argument documented' ) ;
        ok (   $a->is_optional,      '      argument optional' ) ;
        }

    }

    {
    my $f = $func -> [1] ;
    #print STDERR Dumper ($f) ;
    ok ( $f -> name eq 'fasel2',    '  f2 name ok' ) ;
    ok ( ! $f -> is_undocumented,   '    is documented' ) ;
    ok ( $f -> type eq 'LIST',      '    return LIST' ) ;
    }

    {
    my $f = $func -> [2] ;
    #print STDERR Dumper ($f) ;
    ok ( $f -> name eq 'fasel3',    '  f3 name ok' ) ;
    ok ( ! $f -> is_undocumented,   '    is documented' ) ;
    ok ( $f -> type eq 'OBJECT_OR_LIST',  '    return OBJECT_OR_LIST' ) ;
    }    