#include <cstring>
#include <cassert>
#include <cxxabi.h>
#include <typeinfo>
#include <stdexcept>
#include "unwind-cxx.h"
typedef void (*callback_t)(void*);

namespace
{
    bool findTypeInfo(const char * h_mangle, const std::type_info *base, const std::type_info **ret);
}
namespace __d_eh
{
    class Handler
    {
    public:
        typedef int (*handler_t)(void *, void *eptr);
        virtual char const* mangleOf() = 0;
        virtual void * getCtx() = 0;
        virtual handler_t getHandler() = 0;
    };

    void catchException(callback_t dg, void *ctx, Handler **handlers)
    {
        using namespace __cxxabiv1;
        using namespace std;
        try
        {
                dg(ctx);
        }
        catch(...)
        {
            __cxa_eh_globals *global = __cxa_get_globals();
            __cxa_exception *ex = global->caughtExceptions;
            
            type_info *eti = ex->exceptionType;
            void *p = ex->adjustedPtr;
            const char *e_mangle = eti->name();
            while(*handlers)
            {
                const type_info *dst_ti = NULL;
                const char * handler_mangle = (*handlers)->mangleOf();
                if (!handler_mangle)
                {
                    char buff[2049];
                    size_t len = sizeof(buff) - 1;
                    int status = 0;
                    Handler *h = *handlers;
                    p = __cxa_demangle(e_mangle, buff, &len, &status);
                    if (!status)
                        buff[len] = '\0';
                    else
                        buff[0] = '\0';
                    int r = h->getHandler()(h->getCtx(), &buff[0]); //catch All
                    if (r)
                        throw;
                    return;
                }
                else if (findTypeInfo(handler_mangle, eti, &dst_ti))
                {
                    if (*eti != *dst_ti) //do cast
                    {
                        const __class_type_info *sti = dynamic_cast<const __class_type_info*>(eti);
                        const __class_type_info *dti = dynamic_cast<const __class_type_info*>(dst_ti);
                        assert(sti);
                        assert(dti);
                        bool ret = eti->__do_upcast(dti, &p);
                        assert(ret);
                    }
                    Handler *h = *handlers;
                    int r = h->getHandler()(h->getCtx(), p);
                    if (r)
                        throw;
                    return;
                }
                handlers++;
            }
            throw;
            
        }
    }
    
}
namespace
{
    bool findTypeInfo(const char * h_mangle, const std::type_info *base, const std::type_info **ret)
    {
        using namespace __cxxabiv1;
        using namespace std;
        if (!std::strcmp(h_mangle, base->name()))
        {
            *ret = base; //exact match
            return true;
        }
        
        const __si_class_type_info *scti = dynamic_cast<const __si_class_type_info*>(base);
        const __vmi_class_type_info *vmcti = dynamic_cast<const __vmi_class_type_info*>(base);
        
        if (scti)
        {
            return findTypeInfo(h_mangle, scti->__base_type, ret);
        }
        else if (vmcti)
        {
            unsigned base_count = vmcti->__base_count;
            const __base_class_type_info *bcti = &vmcti->__base_info[0];
            int match_count = 0;
            for (unsigned i = 0; i < base_count; i++)
            {
                bool r = findTypeInfo(h_mangle, bcti->__base_type, ret);
                if (r)
                {
                    *ret = bcti->__base_type;
                    return true;
                }
                bcti++;
            }
        }
        return false;;
    }
}

