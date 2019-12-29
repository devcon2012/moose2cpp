package sample_class ;

use strict ;
use warnings ;
use Moose;

extends 'sample_baseclass' ;

# 
has '_intern' => (
    documentation   => 'id from InfoGopher',
    is              => 'rw',
    isa             => 'Int',
    default         => -1 
) ;

# 
class_has '_class_private' => (
    documentation   => 'id from InfoGopher',
    is              => 'rw',
    isa             => 'Int',
    default         => -1 
) ;

class_has '_class_pub' => (
    documentation   => 'id from InfoGopher',
    is              => 'ro',
    isa             => 'Str',
    default         => -1 
) ;

# 
has 'id' => (
    documentation   => 'id from InfoGopher',
    is              => 'rw',
    isa             => 'Maybe[Str]',
    default         => 'XYZ'
) ;

around 'id' => sub 
    {
    my ($orig, $self, $newid) = @_ ;
    shift; shift ;

    #!dump($newid)!
    $self -> info_bites -> source_id ( $newid ) ;

    return $self->$orig(@_);
    };

sub _intern_sub 
    {
    my $self = shift ;
    }

sub BUILD 
    {
    my $self = shift ;

    my $uri = $self -> uri ;
    if ( '/' eq substr($uri, -1) )
        {
        $self -> uri ("$uri") ;
        }
    else
        {
        $self -> uri ("$uri/") ;
        }
    return;
    }

# --------------------------------------------------------------------------------------------------------------------
# 
# sample - example sub documentation
#   this has many lines
#
# in    $a      scalar example
#       %b      hash example
#               very complicated, doku has more lines
#       @c      array example
#
# out   %b      this is not const
#
# ret   $key            returns $key in scalar context
#                       which holds the key value
#       ($key, $val)    returns also value in list context

sub sample
    {
    my ($self, $a, $b, $c) = @_ ;
    }


__PACKAGE__ -> meta -> make_immutable ;

1;

