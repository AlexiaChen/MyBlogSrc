---
title: C++最佳实践
date: 2017-02-22 08:58:23
tags:
    - C/C++
    - 软件工程
---

> 该篇文章是我自己的经验总结，不可能100%适合读者，当然相关的C++工程实践书籍类似《Effective C++》，《More Effective C++》，《Modern Effective C++》，《Learning C++ Best Practices》 《Google C++ Coding Style》等等可能都有类似描述,我这篇文章可能也是从以上的书籍文章汲取了一些。

# 工欲善其事必先利其器

---

现在软件工程越来越发达，C++的标准也一直在改进更新，这门在大众来看的“古老”语言也在慢慢变得更加像现代编程语言一样了，现代软件工程持续交付，持续集成等工具概念层出不穷，这里我想推荐些工具给读者改进优化项目开发流程

- [Cmake](https://cmake.org/)，最好的C++跨平台构建工具，没有之一，automake，qmake在它面前黯然失色。

- [Travis CI](http://travis-ci.org/), 这个是持续集成工具，能在Github上很好的工作。

- [CppCheck](http://cppcheck.sourceforge.net/), C/C++ 静态分析工具，免费的，能查出很多类型缺陷，内存泄漏和资源泄漏。当然还有很多语言的静态分析工具，如果有兴趣，请看[这里](https://en.wikipedia.org/wiki/List_of_tools_for_static_code_analysis)

另外，在个人项目和公司项目中，C++编译器，无论在g++，MSVC，或者clang上，请把警告级别调整到最高。MSVC我是调整到W4级别，g++上，由于本人不熟悉g++的警告类型，那么请开-Wall -Wextra警告并严格观察，另外g++上还可以开-Weffc++选项，编译器会按照《Effective C++》的实践规范来检查代码的隐患。这些都是很重要，编译器的警告很[重要](https://www.zhihu.com/question/29155164)！！要好好利用静态类型语言带来的优点。最后把警告尽量消除到0 warnings为止！ 最后的最后，用C++的静态分析工具检查一遍所有的源码，选择性的消除工具报告出来的缺陷。这样你会发现，后期的软件的运行时的BUG会少很多，特别是不明不白的crash。

# 正文

---

#### 基本C++命名规范

- 类名用驼峰命名法: MyClass
- 类的成员函数和变量名开头单词用小写：myMethod
- 常量全用大写：const double PI = 3.1415926

另外C++标准库和Boost采用另一种规范，如果你的代码与标准库和Boost混合写契合度很高，推荐用以下的规范：

- 宏名称单词全用大写，单词之间用下划线隔开： INT_MAX
- 模版参数使用驼峰命名法： InputInterator
- 其他所有变量和函数名，类名全用小写单词加下划线隔开：make_shared,unordered_map,dynamic_cast

#### 区分私有成员变量

- 在私有成员变量前面加入m_前缀, m代表“member”： m_height

当然，个别一些习惯，是在私有成员变量后加下划线后缀： object_

#### 区分函数参数

- 在函数参数名加入t_前缀： t_height

当然，代码最重要的还是要与CodeBase一致，最终看公司的规范，这里只是一个样例，t可以认为是“the”的缩写。这只是区分函数参数与局部变量的一种策略。

#### 任何命名不能是下划线开头

如果你这么做，那么可能会与编译器的扩展关键字造成冲突。如果好奇，那么请看stackoverflow的这个[讨论](http://stackoverflow.com/questions/228783/what-are-the-rules-about-using-an-underscore-in-a-c-identifier)。

#### 一个良好的样例

``` cpp
class MyClass
{
public:
  MyClass(int t_data, int t_attr)
    : m_data(t_data),m_attr(t_attr)
  {
  }

  int getData() const
  {
    return m_data;
  }

  int attribute() const
  {
      return m_attr;
  }

private:
  int m_data;
  int m_attr;
};
```

#### 空指针的表示请用nullptr

C++ 11 中的空指针是一个特定的值，用以代替0或NULL。 如果好奇，请看知乎的[讨论](https://www.zhihu.com/question/55936870), 不然值会有二义性。另外，知乎上还有[讨论2](https://www.zhihu.com/question/22203461)。

#### 注释

优先使用//来注释代码块，不要使用/**/

#### 不要在头文件中使用using namespace

这会导致using的名字空间污染范围扩散，因为使用了这个头文件的源文件都隐式使用这个名字空间了，这将来容易造成名字空间的冲突，该错误查找困难。不利于后来开发人员维护。

#### 头文件守护

这个想必很多人已经习惯了，不过如果不这样做的危害还是要说一下，这样可以防止头文件被重复包含多次而造成的问题,也能解决意外包含其他工程头文件的冲突。

``` cpp
#ifndef MYPROJECT_MYCLASS_HPP
#define MYPROJECT_MYCLASS_HPP

namespace MyProject {
  class MyClass {
  };
}

#endif
```

#### 代码块一定要用{}

如果不这么做，可能会导致一些语义错误。

``` cpp
// Bad Idea
// 这么做虽然没错，能按照预想运行，但是会给后来人员造成迷惑
for (int i = 0; i < 15; ++i)
  std::cout << i << std::endl;

// Bad Idea
// 这就有错了，std::cout没在循环内，变量i也不是循环内的，与预想不一致
int sum = 0;
for (int i = 0; i < 15; ++i)
  ++sum;
  std::cout << i << std::endl;


// Good Idea
// 这个语义就完全正确了。
int sum = 0;
for (int i = 0; i < 15; ++i) {
  ++sum;
  std::cout << i << std::endl;
}
```

#### 限制代码列的字符数

一般推荐是80-100个字符之间，我自己是80。一般IDE和文本编辑器都可以强制限制。

``` cpp
// Bad Idea
// 难阅读
if (x && y && myFunctionThatReturnsBool() && caseNumber3 && (15 > 12 || 2 < 3)) {
}

// Good Idea
// 逻辑思路跟得上了，容易阅读
if (x && y && myFunctionThatReturnsBool()
    && caseNumber3
    && (15 > 12 || 2 < 3)) {
}
```

#### 使用""包含本地头文件

<> 是保留给标准库和系统库头文件的，自己写的本地头文件#include "MyHeader.h"

#### 初始化成员变量

最好用初始化成员列表来初始化。

``` cpp
// Bad Idea
class MyClass
{
public:
  MyClass(int t_value)
  {
    m_value = t_value; //这是赋值，而不是初始化
  }

private:
  int m_value;
};


// Good Idea
// C++ 初始化成员列表是C++语言特有的，这样写代码更加清晰干净，
// 而且还有潜在的性能提升，因为初始化和赋值不是一个概念。
// 《Effective C++》也提到过
class MyClass
{
public:
  MyClass(int t_value)
    : m_value(t_value)
  {
  }

private:
  int m_value;
};
```
好奇请戳知乎的[讨论](https://www.zhihu.com/question/37345224)。

当然，在C++ 11中，你可以考虑总是给成员变量一个默认值，

``` cpp
// ... //
private:
  int m_value = 0;
// ... //
```

使用大括号初始化,因为它在编译时不允许数据收窄。

``` cpp
// Best Idea

// ... //
private:
  int m_value{ 0 }; // allowed
  unsigned m_value_2 { -1 }; // compile-time error, narrowing from signed to unsigned.
// ... //
```

优先使用大括号初始化，除非有原因的特殊要求不那么做。

#### 总是使用名字空间

在C语言时代，很多库的开发者，为了防止函数符号链接时冲突，就在函数名加入库名称的前缀，比如OpenCV的函数都是cv_xxxx。当然，这是历史原因，如果是采用C++ 编译器，就应该使用namespace防止符号冲突，采用boost库的方式。

#### 使用标准库提供的正确的整型类型

在C++中，最好不要出现int类型，最好是intxxx_t , uintxxx_t。 表示大小请使用std::size_t。

可以看这里的[参考](http://www.cplusplus.com/reference/cstdint/)，这样提高可移植性，因为在不同类型的平台上，这些类型会typedef到特定类型上去。

注意： signed char 保证至少 8 位，int 保证至少 16 位，long 保证至少 32 位，long long 保证至少 64 位。

如果还不明白，去看stackoverflow的[讨论](http://stackoverflow.com/questions/13398630/why-are-c-int-and-long-types-both-4-bytes)

#### Tab和空格不要混合使用

这个绝对禁止，应该从编辑器和IDE里面更改设置，比如让Tab等于4个空格。至于设置Tab等于多少个空格合理，这个是个人喜好问题，不然就是Emacs和Vim之争了。

#### 不要害怕模版

这个，我对于C++的模版元编程不熟悉，就不做过多讨论了。模版可以说是另外一种语言，另一种“函数式”语言。它是图灵完备(Turing-Complete)的。

感兴趣可以在网络上看到各种玩法：
- [玩模板元编程走火入魔是一种怎样的体验](https://www.zhihu.com/question/46612915)
- [C++ 模板元编程的应用有哪些，意义是什么](https://www.zhihu.com/question/21656266)
- [模板元编程和泛函编程都是函数式编程吗](https://www.zhihu.com/question/39637015)
- [如何正确的学习C++的模板和模板元编程](https://www.zhihu.com/question/23463256)
- [怎么样才算是精通 C++](https://www.zhihu.com/question/19794858)

#### 慎用操作符重载

