package PPI::Transform::CPP::Class ;

#
#
#

use strict ;
use warnings ;
use namespace::autoclean ;
use Devel::StealthDebug ENABLE => $ENV{dbg_source} ;

use Data::Dumper ;
use Moose ;
use Try::Tiny ;

use PPI::Transform::CPP::Symbol ;
use PPI::Transform::CPP::Method ;
use PPI::Transform::CPP::Member ;

extends 'PPI::Transform::CPP::Symbol' ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Constants
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# map important pragmas like strict to pseudo-includes
use constant module_map =>
    { 
    'strict'        => 'perl/strict' ,
    } ;

# ignore these use ... statements
use constant ignored_module_map =>
    {
    'warnings'      => 1 ,
    'utf8'          => 1 ,
    } ;

# treat these use ... statements special
use constant special_module_map =>
    { 
    'constant'      => 'add_constant' ,
    } ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'source_file' => (
    documentation   => 'source file',
    is              => 'rw',
    isa             => 'Str',
    default         => '' ,
) ;

has 'parents' => (
    documentation   => 'parent class(es)',
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    default         => sub { [] } , 
    traits          => ['Array'],
    handles => 
        {
        all_parents    => 'elements',
        add_parent     => 'push',
        count_parents  => 'count',
        },
) ;

# 
has 'includes' => (
    documentation   => '(pseudo) includes we reference',
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    default         => sub { [] } , 
    traits          => ['Array'],
    handles => 
        {
        all_includes    => 'elements',
        add_include     => 'push',
        count_includes  => 'count',
        },
) ;

# 
has 'members' => (
    documentation   => 'class/object member variables',
    is              => 'rw',
    isa             => 'ArrayRef[PPI::Transform::CPP::Member]',
    default         => sub { [] } , 
    traits          => ['Array'],
    handles => 
        {
        all_members    => 'elements',
        add_member     => 'push',
        count_members  => 'count',
        },
) ;

# 
has 'methods' => (
    documentation   => 'class/object methods',
    is              => 'rw',
    isa             => 'ArrayRef[PPI::Transform::CPP::Method]',
    default         => sub { [] } , 
    traits          => ['Array'],
    handles => 
        {
        all_methods    => 'elements',
        add_method     => 'push',
        count_methods  => 'count',
        },
) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------------------------------------------------------------------------
# add_constant - add constant member from node
#
# in    $node 
#
# ret  

sub add_constant
    {
    my ( $self, $node ) = @_ ;

    # $self -> _Dumper ( $node ) ;

    my $const_member = PPI::Transform::CPP::Member -> new_const_from_node ($node) ;
    $self -> add_member ( $const_member ) ;
    #print STDERR Dumper ($const_member) ;

    return ;
    }

# -----------------------------------------------------------------------------
# ignore_module - return true for use we ignore
#
# in    $module 
#
# ret   true/false  

sub ignore_module
    {
    my ( $self, $module ) = @_ ;

    return $self -> ignored_module_map -> {$module};
    }

# -----------------------------------------------------------------------------
# map_module2include - replace :: with / and prepend sys/ for pragmas
#
# in    $module module to map 
#
#

sub map_module2include
    {
    my ( $self, $module ) = @_ ;

    my $include = $self -> module_map -> {$module} || $module ;

    $include =~ s/\:\:/\//g ; # replace :: with /

    return "$include.h" ;
    }

# -----------------------------------------------------------------------------
# add_parent_from_node - handle extends 
#
# in    <node>  use node 
#
#
sub add_parent_from_node
    {
    my ( $self, $node ) = @_ ;

    # $self -> _Dumper ( $node ) ;

    for ( my $i=1; $i < $node -> elements; $i++ )
        {
        my $c = $node -> child ($i) ;
        my $t = ref $c ;
        #!dump($t)!
        if ( $t =~ /PPI..Token..Quote/ ) 
            {
            #!dump( $c->string )!
            $self -> add_parent ( $c -> string ) ;
            $self -> add_include ( $c -> string ) ;
            last ;
            }
        }

    return ;
    }

# -----------------------------------------------------------------------------
# add_role_from_node - handle  with ... ; 
#
# in    <node>  use node 
#
#
sub add_role_from_node
    {
    my ( $self, $node ) = @_ ;

    # $self -> _Dumper ( $node ) ;

    for ( my $i=1; $i < $node -> elements; $i++ )
        {
        my $c = $node -> child ($i) ;
        my $t = ref $c ;
        if ( $t =~ /PPI::Token::Quote/ ) 
            {
            $self -> add_parent ( $c -> string ) ;
            $self -> add_include ( $c -> string ) ;
            }
        }

    return ;
    }

# -----------------------------------------------------------------------------
# add_virtual_from_node - handle  requires ... ; 
#
# in    <node>  use node 
#
#
sub add_virtual_from_node
    {
    my ( $self, $node ) = @_ ;

    # $self -> _Dumper ( $node ) ;

    for ( my $i=1; $i < $node -> elements; $i++ )
        {
        #!dump($i)!
        my $c = $node -> child ($i) ;
        my $t = ref $c ;
        if ( $t =~ /PPI::Token::Quote/ ) 
            {
            #!dump($c->string)!
            my $m = PPI::Transform::CPP::Method -> new_virtual ( $c -> string ) ;
            $self -> add_method ( $m ) ;
            }
        }

    return ;
    }

# -----------------------------------------------------------------------------
# add_member_from_node - handle has .. ; 
#
# in    <node>  use node 
#
#

sub add_member_from_node
    {
    my ( $self, $node ) = @_ ;

    # $self -> _Dumper ( $node ) ;

    my $m = PPI::Transform::CPP::Member -> new_from_node ( $node ) ;
    $self -> add_member ( $m ) ;
    #print STDERR Dumper ($m) ;
    return $m;
    }

# -----------------------------------------------------------------------------
# add_static_member_from_node - handle class_has ... ;
#
# in    <node>  use node 
#
#
sub add_static_member_from_node
    {
    my ( $self, $node ) = @_ ;

    my $m = $self -> add_member_from_node ( $node ) ;
    $m -> is_static ( 1 ) ;

    return $m ;
    }


# -----------------------------------------------------------------------------
# add_include_node - handle use ... ; require ... etc.
#
# in    <node>  use node 
#
#

sub add_include_node
    {
    my ( $self, $node ) = @_ ;

    #!dump($node->module)!

    my $module      = $node -> module ;
    my $special     = $self -> special_module_map -> { $module } ;
    if ( $special )
        {
        $self -> $special ( $node ) ;
        }
    else
        {
        $self -> add_include ( $self -> map_module2include( $node -> module ) ) 
            if ( ! $self -> ignore_module ( $node -> module ) );
        }
    return ;
    }

# -----------------------------------------------------------------------------
# add_statement - handle has .. ; class_has ... ; around ... ; extends ... with ... ; 
#
# in    <node>  use node 
#
#
sub add_statement_node
    {
    my ( $self, $node ) = @_ ;

    my $what = $node -> child(0) -> literal ;

    #!dump($what)!
    if ( $what eq 'extends' )
        {
        $self -> add_parent_from_node($node) ;
        }
    elsif ( $what eq 'with' )
        {
        $self -> add_role_from_node($node) ;
        }
    elsif ( $what eq 'requires' )
        {
        $self -> add_virtual_from_node($node) ;
        }
    elsif ( $what eq 'has' )
        {
        $self -> add_member_from_node($node) ;            
        }
    elsif ( $what eq 'class_has' )
        {
        $self -> add_static_member_from_node($node) ;                        
        }
    else 
        {
        # print STDERR Dumper ( $node ) ; 
        }

    return ;
    }

# -----------------------------------------------------------------------------
# add_sub_node - handle sub ...;
#
# in    <node>  use node 
#
#

sub add_sub_node
    {
    my ( $self, $node ) = @_ ;

    my $method = PPI::Transform::CPP::Method -> new_from_node ( $node ) ;
    $self -> add_method ( $method ) ;
    return ;
    }

# -----------------------------------------------------------------------------
# write 
#
# in    $fh
#
#

sub write_class
    {
    my ( $self, $fh ) = @_ ;
    print $fh $self -> as_cpp ;
    return ;
    }

# -----------------------------------------------------------------------------
# as_cpp 
#
#
#

sub as_cpp
    {
    my ( $self ) = @_ ;

    my $ret = '/// @file '  . $self -> source_file . "\n" ;
    $ret   .= '/// @class ' . $self -> name . " short dummy brief info\n" ;

    $ret    .= "\n\n" ;

    my $name = $self -> name ;
    $name =~ s/\:\:/_/g ;

    foreach my $include ( $self -> all_includes )
        {
        $ret .= "#include \"$include\"\n" ;
        $ret =~ s/\:\:/_/g ;
        }

    $ret    .= "\n\n" ;

    my $parents = '' ;
    if ( $self -> count_parents )
        {
        $parents = ': public ' . join (', public ', $self -> all_parents ) ;
        $parents =~ s/\:\:/_/g ;
        }

    my $indent = 8 ;
    $ret .= "class $name $parents\n" ;
    $ret .= "    {\n " ;

    $ret .= "    private:\n " ;
    foreach my $member ( $self -> all_members )
        {
        $ret .= $member -> as_cpp ($indent) 
            if ( $member -> is_private );
        }
    $ret .= "\n" ;

    foreach my $method ( $self -> all_methods )
        {
        $ret .= $method -> as_cpp ($indent)
            if ( $method -> is_private );
        }

    $ret .= "\n\n    public:\n " ;
    foreach my $member ( $self -> all_members )
        {
        $ret .= $member -> as_cpp ($indent)
            if ( ! $member -> is_private );
        }
    $ret .= "\n" ;

    foreach my $method ( $self -> all_methods )
        {
        $ret .= $method -> as_cpp ($indent)
            if ( ! $method -> is_private );
        }

    $ret .= "    };\n " ;

    $ret    .= "\n\n" ;
    
    return $ret ;
    }

# --------------------------------------------------------------------------------------------------------------------
# is_role - perl convention is packages starting with _ are roles
#
# ret   true/false
#
sub is_role
    {
    my ( $self ) = @_ ; 

    return $self -> name =~ /^_/ ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1;


=head1 NAME


=head1 USAGE


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
