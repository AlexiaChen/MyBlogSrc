---
title: CERT C++编码规范翻译（CTR）
date: 2017-07-19 14:30:46
tags:
    - CERT
    - C/C++
---

## 容器类

### CTR50-CPP. 保证容器的索引和迭代器在合法的范围内

严重程度： 高。 会导致任意内存地址的数据被覆盖，从而导致程序不正常终止。

这个主要内容没什么可以说明的。越界一定是开发人员的错。

#### 代码样例对比

``` cpp
#include <cstddef>
void insert_in_table(int *table, std::size_t tableSize, int pos,
int value) {
if (pos >= tableSize) {
// Handle error
return;
}
table[pos] = value;
}
```

以上的代码实现是需要在一个table的特定下标插入一个值。函数还有个下标检测的越界判断，看似合理。但是pos参数被声明了为int，int类型是默认有符号数，而tableSize的类型是无符号的std::size_t，这两个类型比较在某些极端情况下会失效。一旦pos被不小心赋值为负数，那么if判断失效，导致table访问越界。所以改成以下为好:

``` cpp
#include <cstddef>
void insert_in_table(int *table, std::size_t tableSize, std::size_t
pos, int value) {
if (pos >= tableSize) {
// Handle error
return;
}
table[pos] = value;
}
```
pos最好也声明为std:size_t，这样就可以防止负数被传入进函数了。

还可以用以下办法:

``` cpp
#include <cstddef>
#include <new>
void insert_in_table(int *table, std::size_t tableSize, std::size_t
pos, int value) {
// #1
if (pos >= tableSize) {
// Handle error
return;
}
table[pos] = value;
}
template <std::size_t N>
void insert_in_table(int (&table)[N], std::size_t pos, int value) {
// #2
insert_in_table(table, N, pos, value);
}
void f() {
// Exposition only
int table1[100];
int *table2 = new int[100];
insert_in_table(table1, 0, 0); // Calls #2
insert_in_table(table2, 0, 0); // Error, no matching func. call
insert_in_table(table1, 100, 0, 0); // Calls #1
insert_in_table(table2, 100, 0, 0); // Calls #1
delete [] table2;
}
```

以上代码是使用无类型模版的手段把数组越界检测提前到编译时。

#### 代码样列对比(std::vector)

``` cpp
#include <vector>
void insert_in_table(std::vector<int> &table, long long pos, int
value) {
if (pos >= table.size()) {
// Handle error
return;
}
table[pos] = value;
}
```
以上的代码与之前一个的代码样例中所反映的问题是一样的。long long类型的pos是有符号类型，比较可能失效，导致越界。应该改成:

``` cpp
#include <vector>
void insert_in_table(std::vector<int> &table, std::size_t pos, int
value) {
if (pos >= table.size()) {
// Handle error
return;
}
table[pos] = value;
}
```

其实还可以巧妙利用vector的at成员函数来访问特定下标，这个成员函数提供越界检测，越界会抛出std::out_of_range的异常：

``` cpp
#include <vector>
void insert_in_table(std::vector<int> &table, std::size_t pos, int
value) noexcept(false) {
table.at(pos) = value;
}
```

至于insert_in_table 之后声明有noexcept(false)，就是表明该函数可能抛出异常，遵循C++的Honor Exception Spec。 当然不写也可以，但是最好是写上。

#### 代码样例对比(iterators)

``` cpp
#include <iterator>
template <typename ForwardIterator>
void f_imp(ForwardIterator b, ForwardIterator e, int val,
std::forward_iterator_tag) {
do {
*b++ = val;
} while (b != e);
}
template <typename ForwardIterator>
void f(ForwardIterator b, ForwardIterator e, int val) {
typename std::iterator_traits<ForwardIterator>::iterator_category
cat;
f_imp(b, e, val, cat);
}
```

以上对于f_imp函数通过迭代器访问一个容器，参数e是end迭代器，假设e永远是传入正确的，但是也会造成迭代器解引用错误，因为一旦容器是空的，参数b就等于e。但是do while循环是先计算，后比较。这就引入问题了，所以得改成以下:

``` cpp
#include <iterator>
template <typename ForwardIterator>
void f_imp(ForwardIterator b, ForwardIterator e, int val,
std::forward_iterator_tag) {
while (b != e) {
*b++ = val;
}
}
template <typename ForwardIterator>
void f(ForwardIterator b, ForwardIterator e, int val) {
typename std::iterator_traits<ForwardIterator>::iterator_category
cat;
f_imp(b, e, val, cat);
}
```
先比较迭代器的合法性，再进行解引用b。

### CTR51-CPP. 使用合法的引用，指针，迭代器来引用容器的元素

严重等级：高。一旦持有一个不合法的引用并进行访问容器，那么就直接导致未定义行为。

迭代器就是指针的泛化。它允许通过统一的方式来访问不同的数据结构容器。

C++标准[container.requirements.general]有如下声明：

> Unless otherwise specified (either explicitly or by defining a function in terms of other
functions), invoking a container member function or passing a container as an argument
to a library function shall not invalidate iterators to, or change the values of, objects
within that container.

也就是说，C++标准是允许引用和指针无效化的，当你通过容器类提供的操作函数。举个例子，当你从容器中得到一个指向某元素的指针，然后erase了那个元素，然后又在删除元素的位置insert一个新的元素，就会导致现存的指针虽然合法，但是指向了不同的对象。所以任何操作都可能会使指针或引用无效化，要慎重对待。

以下列出容器的哪些操作会使引用，指针，迭代器无效化。

- std::queue  insert() emplace_front() emplace_back() emplace() push_front() push_back() erase() pop_back() resize() clear()

- std::forward_list erase_after() pop_front() resize() remove() unique() clear()

- std::list earse() pop_front() pop_back() clear() remove() remove_if() unique() 

- std::vector reserve() insert() emplace_back() emplace() push_back() erase() pop_back() resize() clear()

- std::set,std::multiset std::map std::multimap earse() clear()

- std::unordered_set std::unordered_multiset std::unordered_map std::unordered_multimap erase() clear() insert() emplace() rehash() reserve() 

- std::valarray resize()

#### 代码样例对比

``` cpp
#include <deque>
void f(const double *items, std::size_t count) {
std::deque<double> d;
auto pos = d.begin();
for (std::size_t i = 0; i < count; ++i, ++pos) {
d.insert(pos, items[i] + 41.0);
}
}
```
以上代码在第一次调用insert的时候pos迭代器失效了，所以就导致后续的循环导致未定义行为。可以通过插入后更新失效迭代器杜绝未定义行为:

``` cpp
#include <deque>
void f(const double *items, std::size_t count) {
std::deque<double> d;
auto pos = d.begin();
for (std::size_t i = 0; i < count; ++i, ++pos) {
pos = d.insert(pos, items[i] + 41.0);
}
}
```

还有一种通过泛型算法的方案来解决迭代器失效的问题:

``` cpp
#include <algorithm>
#include <deque>
#include <iterator>
void f(const double *items, std::size_t count) {
std::deque<double> d;
std::transform(items, items + count, std::inserter(d, d.begin()),
[](double d) { return d + 41.0; });
}
```

### CTR52-CPP. 保证库函数不溢出

严重程度: 高。buffer overflow会导致攻击者经过一定的构造条件执行任意的恶意代码

把数据拷贝到不足够放下数据的容器会导致buffer overflow，覆写不合法的内存区块。避免这样的问题，需要限制目标容器的size，最好与数据的size一样大。或者更大一点也可以。

在C语言时代，std::memcpy std::memmove std::memset都可能导致内存区块被覆盖，而且它们不检测内存区块的合法性。所以建议使用C++ STL中提供的std::copy std::fill std::transform等函数来操作,尽管使用C++ 的STL也可以同样导致buffer overflow。

#### 代码样例对比

``` cpp
#include <algorithm>
#include <vector>
void f(const std::vector<int> &src) {
std::vector<int> dest;
std::copy(src.begin(), src.end(), dest.begin());
// ...
}
```

虽然dest是动态数组会随着push append增加存储空间，但是上面代码使用了std::copy，该函数不会扩展dest的空间，所以在拷贝src中第一个元素的时候，dest就buffer overflow了。

所以就有了以下方案解决，初始化dest的时候就把它的存储空间扩大到与src一样：

``` cpp
#include <algorithm>
#include <vector>
void f(const std::vector<int> &src) {
// Initialize dest with src.size() default-inserted elements
std::vector<int> dest(src.size());
std::copy(src.begin(), src.end(), dest.begin());
// ...
}
```

当然，还有一个方案，就是用std::back_insetr_iterator作为目标参数。这个迭代器它会根据std::copy这个算法一个一个拷贝元素的时候，自动扩展复制目标容器，这就保证目标容器与源容器一样大。

``` cpp
#include <algorithm>
#include <iterator>
#include <vector>
void f(const std::vector<int> &src) {
std::vector<int> dest;
std::copy(src.begin(), src.end(), std::back_inserter(dest));
// ...
}
```

最简单的是用vector提供的拷贝构造函数:

``` cpp
#include <vector>
void f(const std::vector<int> &src) {
std::vector<int> dest(src);
// ...
}
```

#### 代码样例对比

``` cpp
#include <algorithm>
#include <vector>
void f() {
std::vector<int> v;
std::fill_n(v.begin(), 10, 0x42);
}
```

以上这个代码意图让填充10个0x42在vector中，但是vector默认没分配空间，这样直接填充就造成buffer overflow。改成以下方式：

``` cpp
#include <algorithm>
#include <vector>
void f1() {
std::vector<int> v(10);
std::fill_n(v.begin(), 10, 0x42);
}

/////////////////

void f2() {
std::vector<int> v(10, 0x42);
}
```

### CTR53-CPP. 使用合法的迭代器范围

严重程度： 高。造成buffer overflow，导致运行任意代码

当迭代器遍历一个容器的时候，迭代器必须处于一个合法范围，一个迭代器的范围是一对迭代器，其中一个指向第一个元素，另一个指向最后一个元素的后一位。这两个迭代器形成的范围，就是合法的迭代器范围。

一个合法的迭代器范围需要包含以下所有特征：

- 所有的迭代器必须指向同一个容器
- 迭代器指向容器的开始和结尾

一个空的迭代器范围也是合法的（开始迭代器和尾部迭代器相等）

使用两个迭代器分别指向不同的容器，会导致未定义行为。

#### 代码样例对比

``` cpp
#include <algorithm>
#include <iostream>
#include <vector>
void f(const std::vector<int> &c) {
std::for_each(c.end(), c.begin(), [](int i) { std::cout << i; });
}
```

以上代码看似正确了，但是for_each的第一参数需要是容器的begin迭代器，而它设成了end。整个迭代器反了。而且end迭代器指向的是最后一个元素的后一位，一旦解引用，立即造成未定义行为。应该改成以下正确的迭代顺序:

``` cpp
#include <algorithm>
#include <iostream>
#include <vector>
void f(const std::vector<int> &c) {
std::for_each(c.begin(), c.end(), [](int i) { std::cout << i; });
}
```

如果你非得需要反向迭代，那么可以这样：

``` cpp
#include <algorithm>
#include <iostream>
#include <vector>
void f(const std::vector<int> &c) {
std::for_each(c.rbegin(), c.rend(), [](int i) { std::cout << i; });
}
```

#### 代码样例对比

``` cpp
#include <algorithm>
#include <iostream>
#include <vector>
void f(const std::vector<int> &c) {
std::vector<int>::const_iterator e;
std::for_each(c.begin(), e, [](int i) { std::cout << i; });
}
```

以上代码明显这两个迭代器指向了不同的容器，但是由于STL的实现原因，编译器检测不出来这样的语义错误，没有任何的标准表明迭代器e会初始化为容器c的end()迭代器。这个知道原因后，就知道怎么改了，改成以上的代码样例对比就可以了，不作示范。

### CTR54-CPP. 没有指向相同容器的迭代器之间不要做减法

严重程度：中等。

这个与指针本质一样。如果指针指向不同的对象数组，它们之间也不能做减法。类似std:distance就是两个迭代器做减法，需要迭代器指向同一个容器。如果不这么做，那么会直接导致未定义行为。

#### 代码样例对比

``` cpp
#include <cstddef>
#include <iostream>
template <typename Ty>
bool in_range(const Ty *test, const Ty *r, size_t n) {
return 0 < (test - r) && (test - r) < (std::ptrdiff_t)n;
}
void f() {
double foo[10];
double *x = &foo[0];
double bar;
std::cout << std::boolalpha << in_range(&bar, x, 10);
}
```
以上代码意图测试指针test，是否在[r,r+n]这个迭代器范围内，然而test并没有指向这个合法的范围容器中，所以test与r相减导致未定义行为。

``` cpp
#include <iostream>
template <typename Ty>
bool in_range(const Ty *test, const Ty *r, size_t n) {
return test >= r && test < (r + n);
}
void f() {
double foo[10];
double *x = &foo[0];
double bar;
std::cout << std::boolalpha << in_range(&bar, x, 10);
}
```

以上代码试图整改，用比较运算符让test和r不必做减法，但是还是有问题的。因为C++标准有以下描述:

> If two operands p and q compare equal, p<=q and p>=q both yield true and p<q and
p>q both yield false. Otherwise, if a pointer p compares greater than a pointer q,
p>=q, p>q, q<=p, and q<p all yield true and p<=q, p<q, q>=p, and q>p all yield
false. Otherwise, the result of each of the operators is unspecified.

所以比较两个不指向同一个容器的指针会导致未指定行为(unspecified hebavior)。尽管与之前的代码有所改善,但是还是不会产生可移植性的代码，可能在其他的硬件平台上就会失败(x86以外的平台)。

``` cpp

```










