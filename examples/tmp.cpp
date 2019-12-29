
/** @file sample.pm

*/

/** @class sample



@section sample_USED_MODULES USED_MODULES
<ul>
<li>Moose</li>
<li>sampleModule</li>
<li>sample_role</li>
</ul>

*/

class sample: public {

public:
/** @fn void BUILD()
<p>Undocumented Function</p>

@htmlonly
<div id='codesection-BUILD' class='dynheader closed' style='cursor:pointer;' onclick='return toggleVisibility(this)'>
<img id='codesection-BUILD-trigger' src='closed.png' style='display:inline'><b>Code:</b>
</div>
<div id='codesection-BUILD-summary' class='dyncontent' style='display:block;font-size:small;'>click to view</div>
<div id='codesection-BUILD-content' class='dyncontent' style='display: none;'>
@endhtmlonly
@code
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

@endcode
@htmlonly
</div>
@endhtmlonly
*/
void BUILD();

/** @fn void id()
<b>Method Modifier: <i>around</i></b>
<p>Undocumented Function</p>

@htmlonly
<div id='codesection-id' class='dynheader closed' style='cursor:pointer;' onclick='return toggleVisibility(this)'>
<img id='codesection-id-trigger' src='closed.png' style='display:inline'><b>Code:</b>
</div>
<div id='codesection-id-summary' class='dyncontent' style='display:block;font-size:small;'>click to view</div>
<div id='codesection-id-content' class='dyncontent' style='display: none;'>
@endhtmlonly
@code
around 'id' => sub 
    {
    my ($orig, $self, $newid) = @_ ;
    shift; shift ;

    #!dump($newid)!
    $self -> info_bites -> source_id ( $newid ) ;

    return $self->$orig(@_);
    };

@endcode
@htmlonly
</div>
@endhtmlonly
*/
void id();

/** @fn void sample()
<p>Undocumented Function</p>

@htmlonly
<div id='codesection-sample' class='dynheader closed' style='cursor:pointer;' onclick='return toggleVisibility(this)'>
<img id='codesection-sample-trigger' src='closed.png' style='display:inline'><b>Code:</b>
</div>
<div id='codesection-sample-summary' class='dyncontent' style='display:block;font-size:small;'>click to view</div>
<div id='codesection-sample-content' class='dyncontent' style='display: none;'>
@endhtmlonly
@code
sub sample
    {
    my ($self, $a, $b $c) = @_ ;
    }

@endcode
@htmlonly
</div>
@endhtmlonly
*/
void sample();

private:
};
