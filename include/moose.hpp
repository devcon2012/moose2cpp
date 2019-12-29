/*
 * moose.hpp - definitions to make doxygen work on transformed perl moose sources
 *
 */

class SCALAR
    {
    public:
        SCALAR () ;
        ~SCALAR () ;

    } ;

class ARRAY
    {
    public:
        ARRAY () ;
        ~ARRAY () ;

    } ;

class HASH
    {
    public:
        HASH () ;
        ~HASH () ;
    } ;

typedef SCALAR * SCALARREF ;
typedef ARRAY * ARRAYREF ;
typedef HASH * HASHREF ;
        
