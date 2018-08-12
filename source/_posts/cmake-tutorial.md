---
title: 简短的CMake教程
date: 2018-08-12 17:39:00
tags: 
 - C/C++
 - CMake              
---

## 前言
---

主要最近的换工作，完全在Linux下开发，虽然以前都接触过CMake，不过体系也是零散的，遂做了一个简短的CMake教程，以供后续快速入门。

另外，好久也没有写文章了，这份工作还是有一定的技术性，之前的那家公司是开发/维护，大部分工作都是维护，没有什么写文章的激情。

所以，今天是硬凑一篇文章。

## 正文
---

#### CMake

CMake是跨平台的元构建系统，也就是说，它不实际产生构建行为，它只是生成给其他构建系统使用的文件，比如Makefile，MSBuild的solution file。

CMake根据读取名为CMakeLists.txt的文件，然后生成平台特定的构建文件，但是一个很大的问题是，CMake官方提供的教程特别复杂，对于新手的个坑，很难快速入门。

这个教程会通过例子来学习怎么用CMake。以下我们提供几个C++源代码供例子使用：

- main.cpp
- vector.h
- vector.cpp
- array.h
- array.cpp

那么描述构建的CMakeLists.txt内容会是以下:

```cmake
cmake_minimum_required(VERSION 2.8)
project(pjc-lab5)

set(CMAKE_CXX_FLAGS "-std=c++14 -Wall ${CMAKE_CXX_FLAGS}")

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

add_executable(vector-test
    array.cpp
    vector.cpp
    main.cpp
)
```
以上代码很简单，但是第一个问题是，它是不可移植的，因为它没有任何逻辑判断就设置了GCC/Clang的特定编译参数。

第二个问题是，它全局改变了include的搜索路径。

CMake也要有好的书写习惯，采用更加现代的方式来写CMake文件:

```cmake
cmake_minimum_required(VERSION 3.5)
project(pjc-lab5 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)


add_executable(vector-test
    array.cpp
    vector.cpp
    main.cpp
)
```
注意了，以上代码有几点改变了：

- 强制要求了CMake的版本不得小于3.5，因为要使用CMake的一些新功能
- 直接指定该工程为C++工程。这样可以减少CMake查找tool chain的时间，它就不会去查找其他编译器了，也不会检查其他编译器是否正常了。
- 直接采用可跨平台的方式来指定采用的C++标准为C++ 14
- 打开CMAKE_CXX_STANDARD_REQUIRED开关，如果C++ 14标准不被支持，CMake会直接终止构建过程。反之，会采用老的标准来构建
- CMAKE_CXX_EXTENSIONS开关是告诉CMake采用更加通用的编译参数，比如这个开关打开，传递给GCC的参数就会是-std=c++14 而不是-std=gnu++14

然后在构建过程中，你会发现没有警告，因为CMake不会设定编译器的警告级别，需要你根据不同平台来指定相应的编译器警告参数:

```cmake
if ( CMAKE_CXX_COMPILER_ID MATCHES "Clang|AppleClang|GNU" )
    target_compile_options( vector-test PRIVATE -Wall -Wextra -Wunreachable-code -Wpedantic)
endif()
if ( CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
    target_compile_options( vector-test PRIVATE -Wweak-vtables -Wexit-time-destructors -Wglobal-constructors -Wmissing-noreturn )
endif()
if ( CMAKE_CXX_COMPILER_ID MATCHES "MSVC" )
    target_compile_options( vector-test PRIVATE /W4 /w44265 /w44061 /w44062 )
endif()
```

如果就采用上述的CMake文件，那么它生成的工程文件并不好，没有预期，你会发现如果生成VS的solution，你打开工程，你会发现没有包含头文件（vector.h array.h）。因为CMake不理解C++语言，它只是构建工具。

所以CMake文件中要改变下:
```cmake
add_executable(vector-test
    array.cpp
    vector.cpp
    main.cpp
    array.h
    vector.h
)
```

当然，也可以通过CMake的source_group命令给文件归类:

```cmake
source_group("Tests" FILES main.cpp)
source_group("Implementation" FILES array.cpp vector.cpp)
```

这样VS工程下就可以看到对C++源文件分类的文件夹图标了。

#### Tests

CMake是一堆工具的集合，所以它有一个test runner，叫[CTest](https://cmake.org/cmake/help/latest/manual/ctest.1.html)。

要使用它，你需要显式指定它：
```cmake
add_test(NAME test-name COMMAND how-to-run-it)
```
测试返回0表示成功，返回其他值表示失败。

还可以自定义，通过[set_tests_properties](https://cmake.org/cmake/help/latest/command/set_tests_properties.html?highlight=set_tests_properties)来设置其[相关属性](https://cmake.org/cmake/help/v3.11/manual/cmake-properties.7.html#test-properties)。

对于我们的例子工程，我们仅仅是运行bin文件，并不做额外检查:

```cmake
include(CTest)
add_test(NAME plain-run COMMAND $<TARGET_FILE:vector-test>)
```
COMMAND后面的表达式是[generator-expression](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html)。

最后，我们的CMakeLists.txt的内容会是:

```cmake
cmake_minimum_required(VERSION 3.5)
project(pjc-lab5 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)


add_executable(vector-test
    array.cpp
    vector.cpp
    main.cpp
    array.h
    vector.h
)

source_group("Tests" FILES main.cpp)
source_group("Implementation" FILES array.cpp vector.cpp)


if ( CMAKE_CXX_COMPILER_ID MATCHES "Clang|AppleClang|GNU" )
    target_compile_options( vector-test PRIVATE -Wall -Wextra -Wunreachable-code -Wpedantic)
endif()
if ( CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
    target_compile_options( vector-test PRIVATE -Wweak-vtables -Wexit-time-destructors -Wglobal-constructors -Wmissing-noreturn )
endif()
if ( CMAKE_CXX_COMPILER_ID MATCHES "MSVC" )
    target_compile_options( vector-test PRIVATE /W4 /w44265 /w44061 /w44062 )
endif()

include(CTest)
add_test(NAME plain-run COMMAND $<TARGET_FILE:vector-test>)
```

#### libraries

之前的教程都是很简单的例子，但是现实中的项目往往要拆分模块，链接外部的第三方库或者链接工程内的库。

这部分不再多说，可以参考JetBrain的CLion提供的一个简明的[CMake教程](https://www.jetbrains.com/help/clion/quick-cmake-tutorial.html)。

里面记录如何包含链接外部的library。