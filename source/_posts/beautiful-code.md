---
title: 如何写出优美的代码
date: 2016-08-28 09:27:30
tags:
     - 重构
     - 软件工程
---


# 前言
***

程序员是一个巨大多样的群体，可能论代码风格每个人有不同的理解，每个人对编写优雅简洁的代码的欣赏风格可能也不同。虽然每个人的个性和风格是有差异的，但是对于优美的代码同时也有普遍的共性和。优美的代码也是具有普适性的。

因为这样，所以才有很多经验老道的工程师写了有关于代码编写风格规范的书籍。比如，[《API Design for C++》](https://book.douban.com/subject/24869855/),[《编写可读代码的艺术》](https://book.douban.com/subject/10797189/), [《重构:改善既有代码的设计》](https://book.douban.com/subject/4262627/)等。

# 正文

***

那么什么样的代码算优美简洁呢？什么样的代码丑陋混乱呢？我的个人理解是：

### **1. 函数尽可能小**

什么意思呢？这里的“小”是有多种意义的，首先，函数的功能要小，意思就是函数不能负责很多功能，只做好一件事即可，也就是[单一职责原则](https://en.wikipedia.org/wiki/Single_responsibility_principle)。功能小的其中一个表象就是，函数的输入参数少，如果参数一旦多，它的功能就会越来越模糊，对函数外部的状态依赖会越来越大，同时也不利于维护。我的设计是，函数参数尽量不要超过5个，超过5个那么就该考虑是不是设计有问题了。如果功能比较单一的话，那么给函数命名也会更加轻松，试想一下，如果一个函数的功能庞大臃肿，同时做好几件事，那么你该如何命名？你会不知道该怎么较好的命名，语义意图都不明确。代码可读性也将降低。

还有一种“小”的意义是，函数的实现要小，表象就是，实现函数的代码函数要尽可能少，尽量保持在一个屏幕内放下。如果函数的实现是几百上千行，那么阅读代码的人还需要拖动屏幕滚轮，造成不必要的思绪断点形成上下文的开销，这个开销是很大的，因为程序员必须想起上一个屏幕页面的代码是干了什么，与这个页面的屏幕的思路连接起来，这样的思路就不是“所见即得”的。所以这也是为什么各大主流通用程序语言会引入[lambda表达式](https://en.wikipedia.org/wiki/Lambda_expression)（当然了，还有各种变种，什么java的匿名类，javascript的匿名函数等等）这种特性。这样的好处就是，语言的表达能力增强了，同时也让程序员查看函数实现不需要所谓的“跳转到定义”，避免了思维不连续的开销。当然也不能滥用，否则会造成javascript中的call back hell（回调地狱）。


### **2. 避免使用全局变量，多使用局部变量**

这是很多书籍上都提过并强调的一点。如果过多使用全局变量，那么整个程序的状态信息传递会相当复杂，整个程序的状态将混沌不堪。就像电线缠绕在一起的样子。对于局部变量的使用就是，声明局部变量的时候，应该离使用它们的地方越近，原因与第一点的上下文开销是一样的。这样语义衔接更好。如果你使用的是C语言，那么请使用支持[C99](https://en.wikipedia.org/wiki/C99)的编译器，[C89](https://en.wikipedia.org/wiki/C89)的标准局部变量只能声明在函数开头。你看，语言的标准也在不断进步并解决问题。对了，提醒一点，MSVC编译器是不支持C99的，所以直接用它的C++编译器。：)

### **3. 使用简单语义明确的变量名和函数名**

这点不用说了，变量名取a，b，c的可以拖出去斩了。:P 
值得提到的一点就是，对于在循环内无实际意义的迭代变量可以使用i，j，k。因为这些变量名已经是业界共识了，不会影响可读性，即使在BAT或者Google这样的大公司也可以放心使用。还有一点原因就是，即使加上了更有意义的名字，对可读性也不会带来提升，有些时候甚至还会模糊作者的意图。比如你循环遍历一个数组的时候：

``` c
for(int i = 0; i < len; ++i){
    /* to do something*/
    array[i] = 0;
}
```

即使你把i变为看似更有意义的名字index:

``` c
for(int index = 0; index < len; ++index){
    /* to do something*/
    array[index] = 0;
}
```

这样可读性也不会带来多大的提升，在更复杂的场景下，还会让其他阅读代码的人搞不清意图。

### **4. 避免过多的嵌套**

看看这些嵌套过深的代码，只有天知道这坨东西在干什么。注：下面这段代码截取自公司的一个项目。

``` java
public class ClearData implements IJob {

	private static transient final Logger logger = LoggerFactory.getLogger(ClearData.class);

	@Override
	public void execute(Properties params) {
		clearFolder();
	}

	public static final String[] modes = new String[] { "babj", "gefs", "cwao", "ecmf" };

	public static void clearFolder() {

		Date now = new Date();

		File root = new File(Config.GetString("folder_target"));

		// 循环各产品模式
		for (int i = 0; i < modes.length; i++) {

			File mode = new File(Converter.CombinePath(root.getPath(), modes[i]));

			logger.info("清理文件夹：" + mode.getName());

			File[] products = mode.listFiles();

			// 循环各产品
			for (int j = 0; j < products.length; j++) {

				// 如果当前是日志文件，准备清理
				if (products[j].isFile() && products[j].getName().endsWith("log")) {
					// 日志文件，需清理

					logger.info(" 清理文件：    " + products[j].getName());

					Date time = Converter.String2Date(products[j].getName().split("\\.")[0], "yyyyMMddHH");

					if (time != null && (now.getTime() - time.getTime()) > utils.Constants.ticks_day * Config.GetInteger("remain_days")) {
						// 删除当前日志文件
						products[j].delete();
					}
				} else if (products[j].isDirectory()) {

					logger.info("清理文件夹：    " + products[j].getName());

					// 如果当前是目录，则是子产品类型
					File[] subItems = products[j].listFiles();

					// 循环个子产品
					for (int k = 0; k < subItems.length; k++) {

						if (subItems[k].isDirectory()) {

							logger.info("清理文件夹：        " + subItems[k].getName());

							File[] ens = subItems[k].listFiles();

							// 循环各模式
							for (int x = 0; x < ens.length; x++) {

								if (ens[x].isDirectory()) {
									logger.info("清理文件夹：            " + ens[x].getName());

									File[] dates = ens[x].listFiles();

									// 循环各日期文件夹
									for (int y = 0; y < dates.length; y++) {

										File date = dates[y];

										if (date.isDirectory()) {

											logger.info("清理文件夹：                " + date.getName());

											Date _date = Converter.String2Date(date.getName(), "yyyyMMddHH");

											if (_date != null && (now.getTime() - _date.getTime()) > utils.Constants.ticks_day * Config.GetInteger("remain_days")) {
												// 删除当前日志文件
												logger.info("清理文件夹：                过期删除.");
												deleteDir(date);
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	public static boolean deleteDir(File dir) {
		
        if (dir.isDirectory()) {
        	
            File[] children = dir.listFiles();
            
            for (int i=0; i<children.length; i++) {
                boolean success = deleteDir(children[i]);
                if (!success) {
                    return false;
                }
            }
        }
        
        // 目录此时为空，可以删除
        return dir.delete();
    }
}
```
知道了吧？ 影响代码可读性的书写反而需要用更多的注释来弥补。一个书写优美简洁的代码应该是“自解释”的，就是不需要写注释，程序员一眼就能明白大概是在干什么的。如果注释越来越多，那么维护性会越来越差，因为维护代码的同时还需要维护注释。但很显然，实际情况中，保持代码和注释的一致性非常难。你看看小公司的那些老古董项目，有一些注释都与代码意图完全不一样了，天知道是什么年代的注释。留着还会把人带歪路上呢，删了吧，也不好，谁知道留着这段注释你将来想干啥。 代码的[<font color="red">熵</font>](http://baike.baidu.com/item/%E7%86%B5/19190273#viewPageContent)是越来越高的，代码的腐烂也是时时刻刻。

上面只说到了过多嵌套的坏处，那么如何避免这类现象呢？其实万变不离其宗，与第一点本质一样。

方法就是，把这些大量的循环或嵌套抽象成语义更明确的函数或方法把它提取出去调用，过多的嵌套就说明函数代码块的实现太复杂了，也表现了实现者的思路不清晰，当然也可能最终是公司加班赶项目进度的原因造成这样的结果。:)

<font color="red">注意一点</font>，不要为了<font color="red">避免嵌套</font>在循环中用break，continue 投机取巧（这里其实是暗指一些看似谦虚其实自以为是的工程师），好吧，即使这样的写法带来一定程度的避免过多嵌套，但是同时它也带来了更多的坏处，具体情况王垠的文章[《编程的智慧》](http://www.yinwang.org/blog-cn/2015/11/21/programming-philosophy)有讨论。我还可以举出一些讨论:

- [Are `break` and `continue` bad programming practices?](http://programmers.stackexchange.com/questions/58237/are-break-and-continue-bad-programming-practices)

- [Why it is a bad practice to use break/continue labels in OOP (e.g. Java, C#)](http://stackoverflow.com/questions/11133127/why-it-is-a-bad-practice-to-use-break-continue-labels-in-oop-e-g-java-c)

- [Why is continue inside a loop a bad idea?](http://stackoverflow.com/questions/4913981/why-is-continue-inside-a-loop-a-bad-idea)

当然，这个问题大家仁者见仁智者见智了。我自己的感觉就是，如果在循环中用continue跳过一个条件，我大脑中还要反转这个条件才知道程序真正做的事，因为continue是跳过，意图是不处理，那么此事是意义不大的。那么我大脑中还要反转这个条件去查看程序关注的需要处理的代码块。这造成了思维短时间内的条件反转，影响直观性。所以，为何不直接关注需要处理的代码块呢？如果这造成了所谓的多了一层嵌套，那么为何不改善设计，采取之前提到的做法，把代码块抽象成更有意义的函数来避免嵌套过深呢？

# 优雅简洁的代码实例

***

如果说，我工作以来阅读过最漂亮的代码实现，那么应该就是[C++ STL](https://en.wikipedia.org/wiki/Standard_Template_Library)的[SGI实现](http://www.sgi.com/tech/stl/)了。这正是完美的工业级别的代码设计，我心中最完美的C++ coding style。有很多编译器的产商附带的STL基本就是参照SGI的实现。MSVC的不是，MSVC其中小部分买的是PJ STL实现，PJ STL的实现基本没法看。

下面就是SGI STL vector容器的实现,仔细看看，是不是函数很小，基本的循环迭代嵌套也尽量消除了。函数的语义功能已经被抽象得很薄了，所以根本不用写注释来说明作者的意图。完美的“自解释”代码。:)
``` c++
/*
 *
 * Copyright (c) 1994
 * Hewlett-Packard Company
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  Hewlett-Packard Company makes no
 * representations about the suitability of this software for any
 * purpose.  It is provided "as is" without express or implied warranty.
 *
 *
 * Copyright (c) 1996
 * Silicon Graphics Computer Systems, Inc.
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  Silicon Graphics makes no
 * representations about the suitability of this software for any
 * purpose.  It is provided "as is" without express or implied warranty.
 */

/* NOTE: This is an internal header file, included by other STL headers.
 *   You should not attempt to use it directly.
 */

#ifndef __SGI_STL_INTERNAL_VECTOR_H
#define __SGI_STL_INTERNAL_VECTOR_H

__STL_BEGIN_NAMESPACE 

#if defined(__sgi) && !defined(__GNUC__) && (_MIPS_SIM != _MIPS_SIM_ABI32)
#pragma set woff 1174
#endif

template <class T, class Alloc = alloc>
class vector {
public:
  typedef T value_type;
  typedef value_type* pointer;
  typedef const value_type* const_pointer;
  typedef value_type* iterator;
  typedef const value_type* const_iterator;
  typedef value_type& reference;
  typedef const value_type& const_reference;
  typedef size_t size_type;
  typedef ptrdiff_t difference_type;

#ifdef __STL_CLASS_PARTIAL_SPECIALIZATION
  typedef reverse_iterator<const_iterator> const_reverse_iterator;
  typedef reverse_iterator<iterator> reverse_iterator;
#else /* __STL_CLASS_PARTIAL_SPECIALIZATION */
  typedef reverse_iterator<const_iterator, value_type, const_reference, 
                           difference_type>  const_reverse_iterator;
  typedef reverse_iterator<iterator, value_type, reference, difference_type>
          reverse_iterator;
#endif /* __STL_CLASS_PARTIAL_SPECIALIZATION */
protected:
  typedef simple_alloc<value_type, Alloc> data_allocator;
  iterator start;
  iterator finish;
  iterator end_of_storage;
  void insert_aux(iterator position, const T& x);
  void deallocate() {
    if (start) data_allocator::deallocate(start, end_of_storage - start);
  }

  void fill_initialize(size_type n, const T& value) {
    start = allocate_and_fill(n, value);
    finish = start + n;
    end_of_storage = finish;
  }
public:
  iterator begin() { return start; }
  const_iterator begin() const { return start; }
  iterator end() { return finish; }
  const_iterator end() const { return finish; }
  reverse_iterator rbegin() { return reverse_iterator(end()); }
  const_reverse_iterator rbegin() const { 
    return const_reverse_iterator(end()); 
  }
  reverse_iterator rend() { return reverse_iterator(begin()); }
  const_reverse_iterator rend() const { 
    return const_reverse_iterator(begin()); 
  }
  size_type size() const { return size_type(end() - begin()); }
  size_type max_size() const { return size_type(-1) / sizeof(T); }
  size_type capacity() const { return size_type(end_of_storage - begin()); }
  bool empty() const { return begin() == end(); }
  reference operator[](size_type n) { return *(begin() + n); }
  const_reference operator[](size_type n) const { return *(begin() + n); }

  vector() : start(0), finish(0), end_of_storage(0) {}
  vector(size_type n, const T& value) { fill_initialize(n, value); }
  vector(int n, const T& value) { fill_initialize(n, value); }
  vector(long n, const T& value) { fill_initialize(n, value); }
  explicit vector(size_type n) { fill_initialize(n, T()); }

  vector(const vector<T, Alloc>& x) {
    start = allocate_and_copy(x.end() - x.begin(), x.begin(), x.end());
    finish = start + (x.end() - x.begin());
    end_of_storage = finish;
  }
#ifdef __STL_MEMBER_TEMPLATES
  template <class InputIterator>
  vector(InputIterator first, InputIterator last) :
    start(0), finish(0), end_of_storage(0)
  {
    range_initialize(first, last, iterator_category(first));
  }
#else /* __STL_MEMBER_TEMPLATES */
  vector(const_iterator first, const_iterator last) {
    size_type n = 0;
    distance(first, last, n);
    start = allocate_and_copy(n, first, last);
    finish = start + n;
    end_of_storage = finish;
  }
#endif /* __STL_MEMBER_TEMPLATES */
  ~vector() { 
    destroy(start, finish);
    deallocate();
  }
  vector<T, Alloc>& operator=(const vector<T, Alloc>& x);
  void reserve(size_type n) {
    if (capacity() < n) {
      const size_type old_size = size();
      iterator tmp = allocate_and_copy(n, start, finish);
      destroy(start, finish);
      deallocate();
      start = tmp;
      finish = tmp + old_size;
      end_of_storage = start + n;
    }
  }
  reference front() { return *begin(); }
  const_reference front() const { return *begin(); }
  reference back() { return *(end() - 1); }
  const_reference back() const { return *(end() - 1); }
  void push_back(const T& x) {
    if (finish != end_of_storage) {
      construct(finish, x);
      ++finish;
    }
    else
      insert_aux(end(), x);
  }
  void swap(vector<T, Alloc>& x) {
    __STD::swap(start, x.start);
    __STD::swap(finish, x.finish);
    __STD::swap(end_of_storage, x.end_of_storage);
  }
  iterator insert(iterator position, const T& x) {
    size_type n = position - begin();
    if (finish != end_of_storage && position == end()) {
      construct(finish, x);
      ++finish;
    }
    else
      insert_aux(position, x);
    return begin() + n;
  }
  iterator insert(iterator position) { return insert(position, T()); }
#ifdef __STL_MEMBER_TEMPLATES
  template <class InputIterator>
  void insert(iterator position, InputIterator first, InputIterator last) {
    range_insert(position, first, last, iterator_category(first));
  }
#else /* __STL_MEMBER_TEMPLATES */
  void insert(iterator position,
              const_iterator first, const_iterator last);
#endif /* __STL_MEMBER_TEMPLATES */

  void insert (iterator pos, size_type n, const T& x);
  void insert (iterator pos, int n, const T& x) {
    insert(pos, (size_type) n, x);
  }
  void insert (iterator pos, long n, const T& x) {
    insert(pos, (size_type) n, x);
  }

  void pop_back() {
    --finish;
    destroy(finish);
  }
  iterator erase(iterator position) {
    if (position + 1 != end())
      copy(position + 1, finish, position);
    --finish;
    destroy(finish);
    return position;
  }
  iterator erase(iterator first, iterator last) {
    iterator i = copy(last, finish, first);
    destroy(i, finish);
    finish = finish - (last - first);
    return first;
  }
  void resize(size_type new_size, const T& x) {
    if (new_size < size()) 
      erase(begin() + new_size, end());
    else
      insert(end(), new_size - size(), x);
  }
  void resize(size_type new_size) { resize(new_size, T()); }
  void clear() { erase(begin(), end()); }

protected:
  iterator allocate_and_fill(size_type n, const T& x) {
    iterator result = data_allocator::allocate(n);
    __STL_TRY {
      uninitialized_fill_n(result, n, x);
      return result;
    }
    __STL_UNWIND(data_allocator::deallocate(result, n));
  }

#ifdef __STL_MEMBER_TEMPLATES
  template <class ForwardIterator>
  iterator allocate_and_copy(size_type n,
                             ForwardIterator first, ForwardIterator last) {
    iterator result = data_allocator::allocate(n);
    __STL_TRY {
      uninitialized_copy(first, last, result);
      return result;
    }
    __STL_UNWIND(data_allocator::deallocate(result, n));
  }
#else /* __STL_MEMBER_TEMPLATES */
  iterator allocate_and_copy(size_type n,
                             const_iterator first, const_iterator last) {
    iterator result = data_allocator::allocate(n);
    __STL_TRY {
      uninitialized_copy(first, last, result);
      return result;
    }
    __STL_UNWIND(data_allocator::deallocate(result, n));
  }
#endif /* __STL_MEMBER_TEMPLATES */


#ifdef __STL_MEMBER_TEMPLATES
  template <class InputIterator>
  void range_initialize(InputIterator first, InputIterator last,
                        input_iterator_tag) {
    for ( ; first != last; ++first)
      push_back(*first);
  }

  // This function is only called by the constructor.  We have to worry
  //  about resource leaks, but not about maintaining invariants.
  template <class ForwardIterator>
  void range_initialize(ForwardIterator first, ForwardIterator last,
                        forward_iterator_tag) {
    size_type n = 0;
    distance(first, last, n);
    start = allocate_and_copy(n, first, last);
    finish = start + n;
    end_of_storage = finish;
  }

  template <class InputIterator>
  void range_insert(iterator pos,
                    InputIterator first, InputIterator last,
                    input_iterator_tag);

  template <class ForwardIterator>
  void range_insert(iterator pos,
                    ForwardIterator first, ForwardIterator last,
                    forward_iterator_tag);

#endif /* __STL_MEMBER_TEMPLATES */
};

template <class T, class Alloc>
inline bool operator==(const vector<T, Alloc>& x, const vector<T, Alloc>& y) {
  return x.size() == y.size() && equal(x.begin(), x.end(), y.begin());
}

template <class T, class Alloc>
inline bool operator<(const vector<T, Alloc>& x, const vector<T, Alloc>& y) {
  return lexicographical_compare(x.begin(), x.end(), y.begin(), y.end());
}

#ifdef __STL_FUNCTION_TMPL_PARTIAL_ORDER

template <class T, class Alloc>
inline void swap(vector<T, Alloc>& x, vector<T, Alloc>& y) {
  x.swap(y);
}

#endif /* __STL_FUNCTION_TMPL_PARTIAL_ORDER */

template <class T, class Alloc>
vector<T, Alloc>& vector<T, Alloc>::operator=(const vector<T, Alloc>& x) {
  if (&x != this) {
    if (x.size() > capacity()) {
      iterator tmp = allocate_and_copy(x.end() - x.begin(),
                                       x.begin(), x.end());
      destroy(start, finish);
      deallocate();
      start = tmp;
      end_of_storage = start + (x.end() - x.begin());
    }
    else if (size() >= x.size()) {
      iterator i = copy(x.begin(), x.end(), begin());
      destroy(i, finish);
    }
    else {
      copy(x.begin(), x.begin() + size(), start);
      uninitialized_copy(x.begin() + size(), x.end(), finish);
    }
    finish = start + x.size();
  }
  return *this;
}

template <class T, class Alloc>
void vector<T, Alloc>::insert_aux(iterator position, const T& x) {
  if (finish != end_of_storage) {
    construct(finish, *(finish - 1));
    ++finish;
    T x_copy = x;
    copy_backward(position, finish - 2, finish - 1);
    *position = x_copy;
  }
  else {
    const size_type old_size = size();
    const size_type len = old_size != 0 ? 2 * old_size : 1;
    iterator new_start = data_allocator::allocate(len);
    iterator new_finish = new_start;
    __STL_TRY {
      new_finish = uninitialized_copy(start, position, new_start);
      construct(new_finish, x);
      ++new_finish;
      new_finish = uninitialized_copy(position, finish, new_finish);
    }

#       ifdef  __STL_USE_EXCEPTIONS 
    catch(...) {
      destroy(new_start, new_finish); 
      data_allocator::deallocate(new_start, len);
      throw;
    }
#       endif /* __STL_USE_EXCEPTIONS */
    destroy(begin(), end());
    deallocate();
    start = new_start;
    finish = new_finish;
    end_of_storage = new_start + len;
  }
}

template <class T, class Alloc>
void vector<T, Alloc>::insert(iterator position, size_type n, const T& x) {
  if (n != 0) {
    if (size_type(end_of_storage - finish) >= n) {
      T x_copy = x;
      const size_type elems_after = finish - position;
      iterator old_finish = finish;
      if (elems_after > n) {
        uninitialized_copy(finish - n, finish, finish);
        finish += n;
        copy_backward(position, old_finish - n, old_finish);
        fill(position, position + n, x_copy);
      }
      else {
        uninitialized_fill_n(finish, n - elems_after, x_copy);
        finish += n - elems_after;
        uninitialized_copy(position, old_finish, finish);
        finish += elems_after;
        fill(position, old_finish, x_copy);
      }
    }
    else {
      const size_type old_size = size();        
      const size_type len = old_size + max(old_size, n);
      iterator new_start = data_allocator::allocate(len);
      iterator new_finish = new_start;
      __STL_TRY {
        new_finish = uninitialized_copy(start, position, new_start);
        new_finish = uninitialized_fill_n(new_finish, n, x);
        new_finish = uninitialized_copy(position, finish, new_finish);
      }
#         ifdef  __STL_USE_EXCEPTIONS 
      catch(...) {
        destroy(new_start, new_finish);
        data_allocator::deallocate(new_start, len);
        throw;
      }
#         endif /* __STL_USE_EXCEPTIONS */
      destroy(start, finish);
      deallocate();
      start = new_start;
      finish = new_finish;
      end_of_storage = new_start + len;
    }
  }
}

#ifdef __STL_MEMBER_TEMPLATES

template <class T, class Alloc> template <class InputIterator>
void vector<T, Alloc>::range_insert(iterator pos,
                                    InputIterator first, InputIterator last,
                                    input_iterator_tag) {
  for ( ; first != last; ++first) {
    pos = insert(pos, *first);
    ++pos;
  }
}

template <class T, class Alloc> template <class ForwardIterator>
void vector<T, Alloc>::range_insert(iterator position,
                                    ForwardIterator first,
                                    ForwardIterator last,
                                    forward_iterator_tag) {
  if (first != last) {
    size_type n = 0;
    distance(first, last, n);
    if (size_type(end_of_storage - finish) >= n) {
      const size_type elems_after = finish - position;
      iterator old_finish = finish;
      if (elems_after > n) {
        uninitialized_copy(finish - n, finish, finish);
        finish += n;
        copy_backward(position, old_finish - n, old_finish);
        copy(first, last, position);
      }
      else {
        ForwardIterator mid = first;
        advance(mid, elems_after);
        uninitialized_copy(mid, last, finish);
        finish += n - elems_after;
        uninitialized_copy(position, old_finish, finish);
        finish += elems_after;
        copy(first, mid, position);
      }
    }
    else {
      const size_type old_size = size();
      const size_type len = old_size + max(old_size, n);
      iterator new_start = data_allocator::allocate(len);
      iterator new_finish = new_start;
      __STL_TRY {
        new_finish = uninitialized_copy(start, position, new_start);
        new_finish = uninitialized_copy(first, last, new_finish);
        new_finish = uninitialized_copy(position, finish, new_finish);
      }
#         ifdef __STL_USE_EXCEPTIONS
      catch(...) {
        destroy(new_start, new_finish);
        data_allocator::deallocate(new_start, len);
        throw;
      }
#         endif /* __STL_USE_EXCEPTIONS */
      destroy(start, finish);
      deallocate();
      start = new_start;
      finish = new_finish;
      end_of_storage = new_start + len;
    }
  }
}

#else /* __STL_MEMBER_TEMPLATES */

template <class T, class Alloc>
void vector<T, Alloc>::insert(iterator position, 
                              const_iterator first, 
                              const_iterator last) {
  if (first != last) {
    size_type n = 0;
    distance(first, last, n);
    if (size_type(end_of_storage - finish) >= n) {
      const size_type elems_after = finish - position;
      iterator old_finish = finish;
      if (elems_after > n) {
        uninitialized_copy(finish - n, finish, finish);
        finish += n;
        copy_backward(position, old_finish - n, old_finish);
        copy(first, last, position);
      }
      else {
        uninitialized_copy(first + elems_after, last, finish);
        finish += n - elems_after;
        uninitialized_copy(position, old_finish, finish);
        finish += elems_after;
        copy(first, first + elems_after, position);
      }
    }
    else {
      const size_type old_size = size();
      const size_type len = old_size + max(old_size, n);
      iterator new_start = data_allocator::allocate(len);
      iterator new_finish = new_start;
      __STL_TRY {
        new_finish = uninitialized_copy(start, position, new_start);
        new_finish = uninitialized_copy(first, last, new_finish);
        new_finish = uninitialized_copy(position, finish, new_finish);
      }
#         ifdef __STL_USE_EXCEPTIONS
      catch(...) {
        destroy(new_start, new_finish);
        data_allocator::deallocate(new_start, len);
        throw;
      }
#         endif /* __STL_USE_EXCEPTIONS */
      destroy(start, finish);
      deallocate();
      start = new_start;
      finish = new_finish;
      end_of_storage = new_start + len;
    }
  }
}

#endif /* __STL_MEMBER_TEMPLATES */

#if defined(__sgi) && !defined(__GNUC__) && (_MIPS_SIM != _MIPS_SIM_ABI32)
#pragma reset woff 1174
#endif

__STL_END_NAMESPACE 

#endif /* __SGI_STL_INTERNAL_VECTOR_H */

// Local Variables:
// mode:C++
// End:

```

# 总结

***

所以，设计代码的时候应该尽量往这样的标准上靠拢，严格要求自己。另外，在知乎上看到一个[讨论](https://www.zhihu.com/question/24601525)，还有一个更精巧漂亮的STL实现叫[EASTL](https://github.com/electronicarts/EASTL) ，有机会读一读。







