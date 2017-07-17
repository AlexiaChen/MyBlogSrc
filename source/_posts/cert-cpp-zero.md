---
title: CERT C++编码规范翻译（DCL）
date: 2017-06-02 17:16:53
tags:
    - CERT
    - C/C++
---

# 声明

---

本文翻译自[CERT](http://www.cert.org/)(计算机安全应急响应组)提供的C++安全编码规范（2016版），与其他规范不一样的是，该规范侧重软件安全的编码规范。翻译不完全逐字段翻译，可能有简化删改。

# 正文

---

## 声明与初始化（DCL）

### DCL50-CPP 不要定义C风格的可变参函数

严重等级：高

- C风格的可变参函数的参数没有类型安全保证，也就是说，编译器不检查参数的类型是否匹配，如果类型不匹配这样会导致运行时出现未定义行为。这样的未定义行为可以让黑客很容易构造非法运行的代码（exploit）。

#### 不允许的代码样例
这个函数读取参数直到0才会终止循环，如果不以0终止参数，那么这个函数就会出现未定义行为。如果不小心传递成了其他非int类型的参数，那么编译阶段不会报错，运行时将出现未定义行为。
``` cpp
#include <cstdarg>

int add(int first, int second, ...)
{
    int r = first + second;
    va_list va;
    va_start(va,second);
    while(int v = va_arg(va, int))
    {
        r += v;
    }
    va_end(va);
    return r;
}

add(2,3,5,0); // print 10
add(2,3,5); //can be any number or even crash your PC
```

#### 允许的代码样例（递归包扩展）
``` cpp
#include <type_traits>

template <typename Arg, typename 
std::enable_if<std::is_integral<Arg>::value>::type * = nullptr>
int add(Arg f, Arg s)
{
    return f + s;
}

template <typename Arg, typename... Ts, typename
std::enable_if<std::is_integral<Arg>::value>::type * = nullptr>
int add(Arg f, Ts... tail)
{
    return f + add(tail...);
}

add<>(3,4,5); //print 12
add<>(3, 4, 5, 'c'); // compile error

```

以上的样例利用了std::enable_if来保证任何非整型的参数会导致ill-formed的程序。

#### 允许的代码样例（大括号初始化列表扩展）

``` cpp
template <typename Arg, typename... Ts, typename
std::enable_if<std::is_integral<Arg>::value>::type * = nullptr>
int add(Arg i, Arg j, Ts... all)
{
    int values[] = { i, j, all... };
    int r = 0;
    for (auto v : values)
    {
        r += v;
    }
    return r;
}

add<>(3,4,5); //print 12
add<>(3, 4, 5, 'c'); // compile error
```

### DCL51-CPP 不要声明或定义保留标识符

严重等级：低
- 避免与编译器的符号冲突

#### 代码样例对比（Header Guard）
``` cpp
//bad
#ifndef _MY_HEADER_H_
#define _MY_HEADER_H_

#endif // _MY_HEADER_H_

```

以上样例，大部分C++ 头文件是这样写法，自己写的头文件加前缀后缀下划线容易冲突

``` cpp
//good
#ifndef MY_HEADER_H
#define MY_HEADER_H

#endif // MY_HEADER_H

```



#### 代码样例对比（自定义字面量）
``` cpp
//bad
#include <cstddef>
unsigned int operator"" x(const char *, std::size_t);

```

``` cpp
//good
#include <cstddef>
unsigned int operator"" _x(const char *, std::size_t);

```



#### 代码样例对比（文件作用域对象）
``` cpp
//bad
#include <cstddef> // std::for size_t
static const std::size_t _max_limit = 1024;
std::size_t _limit = 100;
unsigned int get_value(unsigned int count) {
return count < _limit ? count : _limit;
}

```

``` cpp
//good
#include <cstddef> // for size_t
static const std::size_t max_limit = 1024;
std::size_t limit = 100;
unsigned int get_value(unsigned int count) {
return count < limit ? count : limit;
}
```

#### 代码样例对比（保留的宏）
``` cpp
//bad
#include <cinttypes> // for int_fast16_t
void f(std::int_fast16_t val) {
enum { MAX_SIZE = 80 };
// ...
}
}

```

``` cpp
//good
#include <cinttypes> // for std::int_fast16_t
void f(std::int_fast16_t val) {
enum { BufferSize = 80 };
// ...
}
}

```



### DCL52-CPP 不要用const或volatile限定一个引用类型

严重等级：低

- C++会阻止或忽略这样的限定，只有非引用类型的值才能这样限定。

#### 代码样例对比
``` cpp
//bad
#include <iostream>
void f(char c) {
char &const p = c; // plz instead of char const &p;  Or: const char &p;
p = 'p';
std::cout << c << std::endl;
}
```

以上代码，会导致未定义行为，在VS2013 VS2015下，这段代码编译时会有警告warning C4227: anachronism used : qualifiers on reference are ignored。运行结果会是p，const 没有产生任何期望的作用。

在Clang 3.9下，这段代码直接产生编译错误error: 'const' qualifier may not be applied to a reference

``` cpp
//good
#include <iostream>
void f(char c) {
const char &p = c;
p = 'p'; //产生期望结果，编译错误，及时发现
std::cout << c << std::endl;

```


### DCL53-CPP 不要写在语法上引起歧义的声明

严重等级：低

- 因为依赖编译器的起义规则来决定该声明的语义结果

#### 代码样例对比
``` cpp
//bad
#include <mutex>
static std::mutex m;
static int shared_resource;
void increment_by_42() {
std::unique_lock<std::mutex>(m);
shared_resource += 42;
}

```

以上样例是一个匿名的std::unique_lock对象，这样的语法歧义可能会被编译器解释成：
- 声明一个匿名std::unique_lock对象，并且调用自身的单参转化构造函数
- 声明了一个名为m的std::unique_lock对象，然后调用默认的构造函数构造

如果是情况2，那么m这个互斥量就永远不会被锁上了。

``` cpp
//good
#include <mutex>
static std::mutex m;
static int shared_resource;
void increment_by_42() {
std::unique_lock<std::mutex> lock(m); //一定要加上对象名字
shared_resource += 42;
}
```

#### 代码样例对比
``` cpp
#include <iostream>
struct Widget {
Widget() { std::cout << "Constructed" << std::endl; }
};
void f() {
Widget w(); // 有歧义
}

```
以上的代码本意是想声明一个类型为Widget局部变量w，然后执行它的默认构造函数。然而，这个声明有语法歧义，还可能是一个函数声明，这个函数是一个无参并且返回类型为Widget的函数。

所以，如果是第二种，那么程序根本就不会如你预想的输出Constructed文本。

``` cpp
#include <iostream>
struct Widget {
Widget() { std::cout << "Constructed" << std::endl; }
};
void f() {
Widget w1; // Elide the parentheses
Widget w2{}; // Use direct initialization
}

```
以上使用正确的初始化方法才能如预想工作。

#### 代码样例对比

``` cpp

#include <iostream>
struct Widget {
explicit Widget(int i) { std::cout << "Widget constructed" <<
std::endl; }
};
struct Gadget {
explicit Gadget(Widget wid) { std::cout << "Gadget constructed"
<< std::endl; }
};
void f() {
int i = 3;
Gadget g(Widget(i));// 该声明有歧义
std::cout << i << std::endl;
}
```
以上的声明有歧义，不会被解释为一个Gadget类型的对象g，而是被解释成函数g，返回类型为Gadget。

``` cpp

#include <iostream>
struct Widget {
explicit Widget(int i) {
std::cout << "Widget constructed" << std::endl;
}
};
struct Gadget {
explicit Gadget(Widget wid) {
std::cout << "Gadget constructed" << std::endl;
}
};
void f() {
int i = 3;
Gadget g1((Widget(i))); // Use extra parentheses
Gadget g2{Widget(i)}; // Use direct initialization
std::cout << i << std::endl;
}

```
以上的代码才会正确输出：

``` txt
Widget constructed
Gadget constructed
Widget constructed
Gadget constructed
3
```

### DCL54-CPP 在同一个作用域同时重载alloc和dealloc的函数

严重等级：低

- 比如，一个重载的alloc函数使用私有堆来创建它的分配，传递进去的指针的值被默认的dealloc函数返回可能会导致未定义行为。

#### 代码样例对比

``` cpp

#include <Windows.h>
#include <new>
void *operator new(std::size_t size) noexcept(false) {
// Private, expandable heap.
static HANDLE h = ::HeapCreate(0, 0, 0);
if (h) {
return ::HeapAlloc(h, 0, size);
}
throw std::bad_alloc();
}
// No corresponding global delete operator defined.
``` 

以上样例中，alloc函数是在全局作用域中重载的，然而，与之匹配的dealloc函数却没有声明，如果有一个对象是这个重载的alloc函数分配的，那么用默认的delete 删除对象的时候会导致未定义行为

``` cpp

#include <Windows.h>
#include <new>
class HeapAllocator {
static HANDLE h;
static bool init;
public:
static void *alloc(std::size_t size) noexcept(false) {
if (!init) {
h = ::HeapCreate(0, 0, 0); // Private, expandable heap.
init = true;
}
if (h) {
return ::HeapAlloc(h, 0, size);
}
throw std::bad_alloc();
}
static void dealloc(void *ptr) noexcept {
if (h) {
(void)::HeapFree(h, 0, ptr);
}
}
};
HANDLE HeapAllocator::h = nullptr;
bool HeapAllocator::init = false;
void *operator new(std::size_t size) noexcept(false) {
return HeapAllocator::alloc(size);
}
void operator delete(void *ptr) noexcept {
return HeapAllocator::dealloc(ptr);
}
```

#### 代码样例对比

``` cpp
#include <new>
extern "C++" void update_bookkeeping(void *allocated_ptr,
std::size_t size, bool alloc);
struct S {
void *operator new(std::size_t size) noexcept(false) {
void *ptr = ::operator new(size);
update_bookkeeping(ptr, size, true);
return ptr;
}
};
```

以上代码，operator new() 实在类作用域重载的，但是却没有与之匹配的在类作用域重载的delete，所以当然分配好的类S的对象，需要删除的时候，调用的是全局默认的delete函数，这样就会导致程序处于一个未确定状态（未定义行为）。

``` cpp
#include <new>
extern "C++" void update_bookkeeping(void *allocated_ptr,
std::size_t size, bool alloc);
struct S {
void *operator new(std::size_t size) noexcept(false) {
void *ptr = ::operator new(size);
update_bookkeeping(ptr, size, true);
return ptr;
}
//需要一个与之匹配的delete
void operator delete(void *ptr, std::size_t size) noexcept {
::operator delete(ptr);
update_bookkeeping(ptr, size, false);
}
};
```

### DCL55-CPP 当传递一个类对象需要跨边界的时候要避免信息泄露

严重等级：低

C++标准对于非union类的非静态数据成员的布局如下所述：

> Nonstatic data members of a (non-union) class with the same access control are
allocated so that later members have higher addresses within a class object. The order
of allocation of non-static data members with different access control is unspecified.
Implementation alignment requirements might cause two adjacent members not to be
allocated immediately after each other; so might requirements for space for managing
virtual functions and virtual base classes.

还有，关于类位域（bit-fields）的声明如下：

> Allocation of bit-fields within a class object is implementation-defined. Alignment of bitfields is implementation-defined. Bit-fields are packed into some addressable allocation
unit.

因此 padding bits可能出现在类对象实例中的任何内存地址上，这就导致其中可能包含一些敏感信息。

#### 代码样例对比

``` cpp
//bad
#include <cstddef>
struct test {
int a;
char b;
int c;
};
// Safely copy bytes to user space
extern int copy_to_user(void *dest, void *src, std::size_t size);
void do_stuff(void *usr_buf) {
test arg{1, 2, 3};
copy_to_user(usr_buf, &arg, sizeof(arg));
}
```

如果以上代码运行在操作系统的内核空间，它把数据arg拷贝到用户空间，然而，这个test类型的对象可能有padding-bits（内存对齐），比如，为了保证类数据成员的对齐，这个padding-bits可能包含敏感信息，然后就导致这些信息从内核空间随着拷贝泄露到用户空间了。

``` cpp

#include <cstddef>
struct test {
int a;
char b;
int c;
};
// Safely copy bytes to user space
extern int copy_to_user(void *dest, void *src, std::size_t size);
void do_stuff(void *usr_buf) {
test arg{};
arg.a = 1;
arg.b = 2; // 关键在这里
arg.c = 3;
copy_to_user(usr_buf, &arg, sizeof(arg));
}

```

以上这段代码倒是在使用前用初始化保证了arg对象的字段都初始化为0了，用memset也可以达到同样效果。但是编译器对arg.b = 2 这个赋值的实现是自由的，也就是说，各个厂商的编译器实现可能不一样。可能有些编译器仅仅只是把最低8位赋值为2，高24位（padding-bits）没有变化，最后就导致高位字节随着拷贝泄漏到用户空间了。

其实可以给出以下两种方案解决这个信息泄露问题

``` cpp
#include <cstddef>
#include <cstring>
struct test {
int a;
char b;
int c;
};
// Safely copy bytes to user space.
extern int copy_to_user(void *dest, void *src, std::size_t size);
void do_stuff(void *usr_buf) {
test arg{1, 2, 3};
// May be larger than strictly needed.
unsigned char buf[sizeof(arg)];
std::size_t offset = 0;
std::memcpy(buf + offset, &arg.a, sizeof(arg.a));
offset += sizeof(arg.a);
std::memcpy(buf + offset, &arg.b, sizeof(arg.b));
offset += sizeof(arg.b);
std::memcpy(buf + offset, &arg.c, sizeof(arg.c));
offset += sizeof(arg.c);
copy_to_user(usr_buf, buf, offset /* size of info copied */);
}
```

以上这段代码就保证了未初始化的padding-bits不会被拷贝到用户空间去。

``` cpp
#include <cstddef>
struct test {
int a;
char b;
char padding_1, padding_2, padding_3;
int c;
test(int a, char b, int c) : a(a), b(b),
padding_1(0), padding_2(0), padding_3(0),
c(c) {}
};
// Ensure c is the next byte after the last padding byte.
static_assert(offsetof(test, c) == offsetof(test, padding_3) + 1,
"Object contains intermediate padding");
// Ensure there is no trailing padding.
static_assert(sizeof(test) == offsetof(test, c) + sizeof(int),
"Object contains trailing padding");
// Safely copy bytes to user space.
extern int copy_to_user(void *dest, void *src, std::size_t size);
void do_stuff(void *usr_buf) {
test arg{1, 2, 3};
copy_to_user(usr_buf, &arg, sizeof(arg));
}
```

以上代码是通过显式声明padding-bits，但是这个方案不具有可移植性，因为依赖目标内存的架构与实现。以上代码是限定于x86-32的平台。

#### 代码样例对比

``` cpp

#include <cstddef>
class base {
public:
virtual ~base() = default;
};
class test : public virtual base {
alignas(32) double h;
char i;
unsigned j : 80;
protected:
unsigned k;
unsigned l : 4;
unsigned short m : 3;
public:
char n;
double o;
test(double h, char i, unsigned j, unsigned k, unsigned l,
unsigned short m, char n, double o) :
h(h), i(i), j(j), k(k), l(l), m(m), n(n), o(o) {}
virtual void foo();
};
// Safely copy bytes to user space.
extern int copy_to_user(void *dest, void *src, std::size_t size);
void do_stuff(void *usr_buf) {
test arg{0.0, 1, 2, 3, 4, 5, 6, 7.0};
copy_to_user(usr_buf, &arg, sizeof(arg));
}
```

以上代码可能还是会把padding-bits泄露到用户空间中，因为padding-bits是implementation-defined，所以对象内存布局在各个编译器下不一样。可能出现以下的情况：

- 为了对齐产生的padding-bits在虚函数表之后，或者在虚基类的数据之后。之后才是各种数据成员

- padding-bits可能在各个拥有不同访问控制权限的数据成员之间

- 可能编译器会在类的实例中开辟出一个专门存放padding-bits的数组，这个数组位置也是implementation-defined

以下给出解决方案：

``` cpp
#include <cstddef>
#include <cstring>
class base {
public:
virtual ~base() = default;
};
class test : public virtual base {
alignas(32) double h;
char i;
unsigned j : 80;
protected:
unsigned k;
unsigned l : 4;
unsigned short m : 3;
public:
char n;
double o;
test(double h, char i, unsigned j, unsigned k, unsigned l,
unsigned short m, char n, double o) :
h(h), i(i), j(j), k(k), l(l), m(m), n(n), o(o) {}
virtual void foo();
bool serialize(unsigned char *buffer, std::size_t &size) {
if (size < sizeof(test)) {
return false;
}
std::size_t offset = 0;
std::memcpy(buffer + offset, &h, sizeof(h));
offset += sizeof(h);
std::memcpy(buffer + offset, &i, sizeof(i));
offset += sizeof(i);
// Only sizeof(unsigned) bits are valid, so the following is
// not narrowing.
unsigned loc_j = j;
std::memcpy(buffer + offset, &loc_j, sizeof(loc_j));
offset += sizeof(loc_j);
std::memcpy(buffer + offset, &k, sizeof(k));
offset += sizeof(k);
unsigned char loc_l = l & 0b1111;
std::memcpy(buffer + offset, &loc_l, sizeof(loc_l));
offset += sizeof(loc_l);
unsigned short loc_m = m & 0b111;
std::memcpy(buffer + offset, &loc_m, sizeof(loc_m));
offset += sizeof(loc_m);
std::memcpy(buffer + offset, &n, sizeof(n));
offset += sizeof(n);
std::memcpy(buffer + offset, &o, sizeof(o));
offset += sizeof(o);
size -= offset;
return true;
}
};
// Safely copy bytes to user space.
extern int copy_to_user(void *dest, void *src, size_t size);
void do_stuff(void *usr_buf) {
test arg{0.0, 1, 2, 3, 4, 5, 6, 7.0};
// May be larger than strictly needed, will be updated by
// calling serialize() to the size of the buffer remaining.
std::size_t size = sizeof(arg);
unsigned char buf[sizeof(arg)];
if (arg.serialize(buf, size)) {
copy_to_user(usr_buf, buf, sizeof(test) - size);
} else {
// Handle error
}
}
```

以上代码就手工上保证没有初始化的padding-bits不会泄漏到用户空间了。


### DCL56-CPP 静态对象的初始化期间避免循环初始化

严重等级：低

- 可能导致未指定行为（unspecified behavior）
- 可能导致死锁

####  代码样例对比

``` cpp
#include <stdexcept>
int fact(int i) noexcept(false) {
if (i < 0) {
// Negative factorials are undefined.
throw std::domain_error("i must be >= 0");
}
static const int cache[] = {
fact(0), fact(1), fact(2), fact(3), fact(4), fact(5),
fact(6), fact(7), fact(8), fact(9), fact(10), fact(11),
fact(12), fact(13), fact(14), fact(15), fact(16)
};
if (i < (sizeof(cache) / sizeof(int))) {
return cache[i];
}
return i > 0 ? i * fact(i - 1) : 1;
}
```

以上的代码本意是想用cache的思想实现一个高效的求阶乘的函数，但是静态数组cache的初始化包含了递归，这个行为是未定义的，即使这个递归是有边界的。

从实现上看，VS2015和GCC 6.1.0 中，这个静态数组的初始化在线程安全的方式下可能死锁。而且还不一定能算出正确结果。

下面给出解决方案

``` cpp
#include <stdexcept>
int fact(int i) noexcept(false) {
if (i < 0) {
// Negative factorials are undefined.
throw std::domain_error("i must be >= 0");
}
// Use the lazy-initialized cache.
static int cache[17];
if (i < (sizeof(cache) / sizeof(int))) {
if (0 == cache[i]) {
cache[i] = i > 0 ? i * fact(i - 1) : 1;
}
return cache[i];
}
return i > 0 ? i * fact(i - 1) : 1;
}
```

上面代码使用了懒初始化的方式，本质上是把静态初始化变成赋值了。完全可以计算出正确结果。

#### 代码样例对比

``` cpp
// file.h
#ifndef FILE_H
#define FILE_H
class Car {
int numWheels;
public:
Car() : numWheels(4) {}
explicit Car(int numWheels) : numWheels(numWheels) {}
int get_num_wheels() const { return numWheels; }
};
#endif // FILE_H
// file1.cpp
#include "file.h"
#include <iostream>
extern Car c;
int numWheels = c.get_num_wheels();
int main() {
std::cout << numWheels << std::endl; // 不一定输出6
}
// file2.cpp
#include "file.h"
Car get_default_car() { return Car(6); }
Car c = get_default_car();
```
file1.cpp中numWheels的值依赖于c的初始化，然而，c被定义在了不同的翻译单元中（file2.cpp），所以对于c，没有任何保证c通过get_default_car()初始化是在numWheels = c.get_num_wheels()之前，专业上这叫“静态初始化顺序失效”，导致的结果也是未指定的。

从实现细节上说，打印到标准输出流上的值依赖于翻译单元的链接顺序，比如，在Clang 3.8.0（x86 Linux）下，clang++
file1.cpp file2.cpp && ./a.out  这组命令会输出0， clang++ file2.cpp
file1.cpp && ./a.out 才会输出所期望的结果6。

下面给出解决办法

``` cpp
// file.h
#ifndef FILE_H
#define FILE_H
class Car {
int numWheels;
public:
Car() : numWheels(4) {}
explicit Car(int numWheels) : numWheels(numWheels) {}
int get_num_wheels() const { return numWheels; }
};
#endif // FILE_H
// file1.cpp
#include "file.h"
#include <iostream>
int &get_num_wheels() {
extern Car c;
static int numWheels = c.get_num_wheels();
return numWheels;
}
int main() {
std::cout << get_num_wheels() << std::endl; //一定是6
}
// file2.cpp
#include "file.h"
Car get_default_car() { return Car(6); }
Car c = get_default_car();
```

以上代码是用“construct on first use”的idiom来解决静态初始化顺序的问题的，file.h和file2.cpp的代码都没有变，只有静态的numWheels被移到了函数体内，结果就是numWheels的初始化会发生在它声明的时候，全局对象c在main函数执行之前就初始化完毕，所以最终结果一定是6。

### DCL57-CPP 不要让异常逃离析构函数和dealloc函数的范围

严重等级：低

通过抛出异常的方式终止析构函数,operator delete 和 operator delete []会触发未定义行为。

在C++标准中， [basic.stc.dynamic.deallocation], paragraph 3 [ISO/IEC 14882-
2014]有如下声明：

> If a deallocation function terminates by throwing an exception, the behavior is undefined.

所以在这些情况下，函数就必须声明为noexcept的，因为从一个函数抛出异常本来就不会有well-defined的行为，C++ 标准[except.spec]有如下声明：

> A deallocation function with no explicit exception-specification is treated as if it were
specified with noexcept(true).

C++标准中，[class.dtor]部份有以下声明：

> A declaration of a destructor that does not have an exception-specification is implicitly
considered to have the same exception-specification as an implicit declaration.

#### 代码样例对比

``` cpp
#include <stdexcept>
class S {
bool has_error() const;
public:
~S() noexcept(false) {
// Normal processing
if (has_error()) {
throw std::logic_error("Something bad");
}
}
};
```

以上代码会触发未定义行为，因为类析构函数没有满足隐式保证noexcept，所以还是可能抛出异常。

``` cpp
#include <exception>
#include <stdexcept>
class S {
bool has_error() const;
public:
~S() noexcept(false) {
// Normal processing
if (has_error() && !std::uncaught_exception()) {
throw std::logic_error("Something bad");
}
}
};
```

以上代码在析构函数中使用了std::uncaught_exception()，通过避免异常扩展的方式解决了终止问题。但是还是会导致一些重要资源的泄露。

再举个例子，比如以下代码存在于第三方库中，用户不能修改：

``` cpp
// Assume that this class is provided by a 3rd party and it is not
//something
// that can be modified by the user.
class Bad {
~Bad() noexcept(false);
};
```

为了安全的使用Bad类，SomeClass的析构函数意图catch Bad类可能抛出的异常来阻止扩散。

``` cpp
class SomeClass {
Bad bad_member;
public:
~SomeClass()
{
    try {
        // ...
    } catch(...) {
        // Handle the exception thrown from the Bad destructor.
    }
}

};
```
但是在C++ 标准中[except.handle]声明如下：

> The currently handled exception is rethrown if control reaches the end of a handler of
the function-try-block of a constructor or destructor.

根据标准的说法，也就是在构造函数或析构函数中当控制流抵达catch块尾部的时候，异常还是会被重新抛出。结果还是不可避免的会被抛出异常。

下面给出一个解决方案：

``` cpp
class SomeClass {
Bad bad_member;
public:
~SomeClass()
{
    try {
        // ...
    } catch(...) {
        // Catch exceptions thrown from noncompliant destructors of
        // member objects or base class subobjects.
        // NOTE: Flowing off the end of a destructor function-try-block
        // causes the caught exception to be implicitly rethrown, but
        // an explicit return statement will prevent that from
        // happening.
        return;
    }
}

};
```

上面的代码使用显式的return语句阻止了控制流到达了catch块的尾部，这样做必然可以捕捉bad_member销毁时候所抛出的异常了，而且这么用法可以捕捉其他任何异常，异常也不会重新在SomeClass的析构函数中被重新抛出导致被终止的问题了。

#### 代码样例对比

``` cpp
#include <stdexcept>
bool perform_dealloc(void *);
void operator delete(void *ptr) noexcept(false) {
if (perform_dealloc(ptr)) {
throw std::logic_error("Something bad");
}
}
```

经过了之前的分析，可以很简单的看出上面的代码，全局dealloc函数必然会导致未定义行为。需要改成下面这样。

``` cpp
#include <cstdlib>
#include <stdexcept>
bool perform_dealloc(void *);
void log_failure(const char *);
void operator delete(void *ptr) noexcept(true) {
if (perform_dealloc(ptr)) {
log_failure("Deallocation of pointer failed");
std::exit(1); // Fail, but still call destructors
}
}
```
上面的代码通过不抛出异常，直接结束程序，而且也会正确调用析构函数。

### DCL58-CPP. 不要修改标准名字空间

严重等级：高

C++ 标准[namespace.std]规定了：

> The behavior of a C++ program is undefined if it adds declarations or definitions to
namespace std or to a namespace within namespace std unless otherwise
specified. A program may add a template specialization for any standard library
template to namespace std only if the declaration depends on a user-defined type
and the specialization meets the standard library requirements for the original
template and is not explicitly prohibited.

> The behavior of a C++ program is undefined if it declares
an explicit specialization of any member function of a standard library class
template, or
 an explicit specialization of any member function template of a standard library class
or class template, or
 an explicit or partial specialization of any member class template of a standard
library class or class template.

除了要限制对std名字空间的扩展，C++标准[namespace.posix]还规定限制对posix名字空间的扩展:

> The behavior of a C++ program is undefined if it adds declarations or definitions to
namespace posix or to a namespace within namespace posix unless otherwise
specified. The namespace posix is reserved for use by ISO/IEC 9945 and other POSIX
standards.

### DCL59-CPP 不要在头文件中定义一个未命名的名字空间

严重等级：中

C++标准[namespace.unnamed]对此作出描述:

> An unnamed-namespace-definition behaves as if it were replaced by:
inline namespace unique { /* empty body */ }
using namespace unique ;
namespace unique { namespace-body }
where inline appears if and only if it appears in the unnamed-namespace-definition,
all occurrences of unique in a translation unit are replaced by the same identifier, and
this identifier differs from all other identifiers in the entire program.

因为定义在头文件中的未命名名字空间，可能通过#include 插入到任何.cpp文件中（任何翻译单元），会导致对未命名的名字空间在不同的翻译单元有自己的实例名字，所以可能导致奇怪的结果。

### DCL60-CPP 遵循只有一个定义的原则

严重等级：高

正经的C++项目一般都会把程序分割成多个翻译单元，然后通过链接器把多个翻译单元链接在一起成为一个可执行文件。为了支持这一种模型，C++限制已命名的对象定义，通过在跨所有翻译单元中只有一个定义来保证。这种模型叫one-definition rule(ODR)。 而且也在C++标准 [basic.def.odr] 中描述了：

> Every program shall contain exactly one definition of every non-inline function or variable
that is odr-used in that program; no diagnostic required. The definition can appear
explicitly in the program, it can be found in the standard or a user-defined library, or
(when appropriate) it is implicitly defined. An inline function shall be defined in every
translation unit in which it is odr-used.

当然，多个翻译单元通常会包含多种声明，因为大部分是通过#include头文件被插入到翻译单元中的。在头文件中的这些声明也有可能也含有定义了。比如类和函数模板的定义。这些也在C++标准中描述了：

> There can be more than one definition of a class type, enumeration type, inline function
with external linkage, class template, non-static function template, static data member of
a class template, member function of a class template, or template specialization for
which some template parameters are not specified in a program provided that each
definition appears in a different translation unit, and provided the definitions satisfy the
following requirements. Given such an entity named D defined in more than one
translation unit....
If the definitions of D satisfy all these requirements, then the program shall behave as if
there were a single definition of D. If the definitions of D do not satisfy these
requirements, then the behavior is undefined.

#### 代码样例对比

``` cpp
// a.cpp
struct S {
int a;
};
// b.cpp
class S {
public:
int a;
};
```

以上代码在两个不同的翻译单元中定义了一个相同的类，struct本质上也是类。而且这两个类都有一个非静态数据成员a。所以以上代码违反了ODR，并且会导致未定义行为。

下面给出解决方案：

``` cpp
// S.h
struct S {
int a;
};
// a.cpp
#include "S.h"
// b.cpp
#include "S.h"
```

以上代码就不会存在问题了，其实解决这种类似的问题依赖于编程者的意图，如果编程者需要在同样的类定义在不同的翻译单元中可见，那么就可以定义在头文件中，并且通过include插入。就像以上代码的做法。

如果由于ODR原则导致了符号名字的冲突，那么可以通过名字空间来保证类是唯一的：

``` cpp
// a.cpp
namespace {
struct S {
int a;
};
}
// b.cpp
namespace {
class S {
public:
int a;
};
}
```

#### 代码样例对比（Visual Studio）

``` cpp

// s.h
struct S {
char c;
int a;
};
void init_s(S &s);
// s.cpp
#include "s.h"
void init_s(S &s); {
s.c = 'a';
s.a = 12;
}
// a.cpp
#pragma pack(push, 1)
#include "s.h"
#pragma pack(pop)
void f() {
S s;
init_s(s);
}
```

以上的代码通过#include把一个类定义插入到了不同的翻译单元中，然而，其中一个翻译单元（a.cpp）通过implementation-defined的#pragma指令来实现了结构体成员对齐，所以导致了两个翻译单元（s.cpp a.cpp）S的定义具有了不同的二进制布局，这就违反了ODR原则，导致了未定义行为。

要解决这个问题比较简单，把#pragma指令移除就可以了：

``` cpp
// s.h
struct S {
char c;
int a;
};
void init_s(S &s);
// s.cpp
#include "s.h"
void init_s(S &s); {
s.c = 'a';
s.a = 12;
}
// a.cpp
#include "s.h"
void f() {
S s;
init_s(s);
}
```

#### 代码样例对比

``` cpp
const int n = 42;
int g(const int &lhs, const int &rhs);
inline int f(int k) {
return g(k, n);
}
```

以上代码也违反了ODR，但是一下子难以看出来，下面来逐个分析：

常量对象n有个内部链接，但是被函数f()依赖了，函数f()具有外部链接。因为函数f()被声明为了一个inline，所以f函数的定义在所有翻译单元中都是唯一的（在所有翻译单元中f的二进制布局都一样）。然而，对象n在每个翻译单元中都会具有一个唯一的实例（在所有翻译单元中n的实例不一样），所以由于n的不同导致了函数f违反了ODR。

下面的代码解决了该问题:

``` cpp
const int n = 42;
int g(int lhs, int rhs); // 把常引用消除
inline int f(int k) {
return g(k, n);
}
```
或者像下面这样修改，

``` cpp
enum Constants {
N = 42
};
int g(const int &lhs, const int &rhs);
inline int f(int k) {
return g(k, N);
}
```
把常量N改为命名的enum类型，所以N在不同的翻译单元中布局都一样了，这样就不会影响函数f，它们具有同样的链接。不违反ODR。





