all:
	g++ -g -c ./src/cpp_eh_impl.cpp -Iinclude
	dmd -c ./src/cpp_eh.d
test: all
	g++ -c ./test/test_eh.cpp
	dmd -Isrc ./test/test_eh2.d ./test/stdexceptions.d test_eh.o cpp_eh_impl.o cpp_eh.o -L-lstdc++
clean:
	rm -f *.o
	rm -f test_eh2
