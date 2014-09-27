import core.stdc.stdio;
import cpp_eh;
import stdexceptions;

extern(C++) void throwEx(void *);

void main()
{
    /*
    code like ...
    try
    {
        throwEx();
    }
    catch(std.exception val)
    {
        printf("exception: '%s'\n", val.what());
    }
    
    may be rewritten as
    */
    
    Try!(throwEx)(
        (CPPException!int ex)
        {
            printf("exception: '%d'\n", *ex.data);
            return 0;
        },
        (CPPException!(stdexceptions.std.exception) ex)
        {
            printf("exception: '%s'\n", ex.data.what());
            return 0;
        }
    );
}
 
