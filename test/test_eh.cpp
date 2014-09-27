
#include <stdexcept>

//test function
void throwEx(void *)
{
    throw std::logic_error("Catch me, if you can");
}