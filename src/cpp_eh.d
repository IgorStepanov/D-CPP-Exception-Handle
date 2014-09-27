module cpp_eh;

import std.stdio;
import std.string;
import std.traits;

extern(C++, __d_eh)
{
    alias callback_t = void function(void *);
    interface Handler
    {
        //if return value != 0: re-throw exception
        alias handler_t = int function(void *, void *eptr);
        const(char)* mangleOf();
        void * getCtx();
        handler_t getHandler();
    };

    void catchException(callback_t dg, void *ctx, Handler *handlers);
}
class CPPException(T) : Throwable
{
    static if (is(T V : V*) || is(T == class) || is(T == interface))
    {
        this(void* ptr)
        {
            this.data = cast(T)ptr;
            super("cpp exception");
        }
        T data;
    }
    else
    {
        this(void* ptr)
        {
            this.data = cast(T*)ptr;
            super("cpp exception");
        }
        T* data;
    }
}

class CPPHandler(T) : Handler
{
    this()
    {
    }


    this(int function(CPPException!T) fn)
    {
        this.fn = fn;
    }

    this(int delegate(CPPException!T) dg)
    {
        this.dg = dg;
    }
    
    void setHandler(int function(CPPException!T) fn)
    {
        this.fn = fn;
    }
    
    void setHandler(int delegate(CPPException!T) dg)
    {
        this.dg = dg;
    }

    override
    extern (C++)
    const(char)* mangleOf()
    {
        static if (is(T == class) || is(T == interface) || is(T == struct))
        {
            string mangle = __mangleof__!(T).mangle ~ '\0';
            return mangle.ptr; //should be a C++ mangle
        }
        else
        {
            return T.mangleof.ptr; //should be a C++ mangle
        }
    }

    override
    extern (C++)
    void * getCtx()
    {
        return cast(void*)this;
    }
    
    override
    extern (C++)
    handler_t getHandler()
    {
        return &cppHandler;
    }
    
    extern(C++)
    static int cppHandler(void* ctx, void* ep)
    {
        CPPHandler handler = cast(CPPHandler)ctx;
        auto ex = new CPPException!T(ep);
        if (handler.dg)
            return handler.dg(ex);
        else
            return handler.fn(ex);
    }

    int delegate(CPPException!T) dg;
    int function(CPPException!T) fn;
}

void Try(alias DG, T...)(T args)
{
    callback_t dg = &DG;
    Handler[T.length + 1] handlers;
    foreach(key, val; args)
    {
        static if(is(T[key] FUNC: FUNC*) && is(FUNC ARGS == function) && ARGS.length == 1 && is(ARGS[0] : CPPException!TEX, TEX))
        {
            handlers[key] = new CPPHandler!(TEX)(args[key]);
        }
        else static if(is(T[key] FUNC == delegate) && is(FUNC ARGS == function) && ARGS.length == 1 && is(ARGS[0] : CPPException!TEX, TEX))
        {
            handlers[key] = new CPPHandler!(TEX)(args[key]);
        }
        else
        {
            static assert("wrong catch delegate type, "~T[key].stringof);
        }
    }
 
    handlers[T.length] = null;
    catchException(dg, null, handlers.ptr);
}

private struct __mangleof__(T)
{
    extern(C++) static void __probe__()
    {
        
    }
    
    static string computeMangle()
    {
        string m = __probe__.mangleof;
        m = m["_ZN12__mangleof__I".length .. $-"E9__probe__Ev".length];
        
        static if (is(T == class) || is(T == interface))
        {
            m = m[1 .. $]; //remove leading P
        }
        return m;
    }
    enum mangle = computeMangle();
}
