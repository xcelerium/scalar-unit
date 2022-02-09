# model
1. Structure

     |__ src (source--*.cpp)
     |
     |__ include (header files -- *.h)
     |
     |__ gen  (generators for file genartion -- *.py)
     |
     |__ bindings (python bindings)
     |
     |__ bin (location for python binding dlls *.so)
     |
     |__ test (test files *.cpp)
     |
     |__ build (makefiles)


2. Build instructions
   i)   "make py" to run generators and update src and include files
   ii)  "make "+TEST_NAME to build run_TEST_NAME program using
         src/test_TEST_NAME.cpp 
   iii) "make bind" to make bindings

   or "make -f build/???.binding" for bindings
   or "make -f build/xyz.test" for building a test (generates run_xyz)
 
3. Running test program
   ./run_TEST_NAME (e.g. run_scalar)

   current tests
   enc
   su
   vu
   scalar
   vector

4. Running python tests
   python3 -i setup.py  (interactive sessions)
   python3 example.py (calls setup.py)
   pytest scalar.py	
   



