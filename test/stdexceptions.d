module stdexceptions;

extern(C++, std)
{
    interface exception
    {
        void __dtor(); //two virtual dtors
        void __dtor2();
        const(char)* what() const;
    }
}