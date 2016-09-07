---
title: 谈谈函数式编程
date: 2016-09-05 15:38:56
tags:
    - 函数式编程
    - lambda演算
    - Y组合子
---

# 什么是函数式编程

---

其实有关于函数式编程我有在之前的博文[《编程语言为何如此众多》](http://mathxh-love.org/blog/2016/05/19/programming-language/)提到过，有兴趣的可以去看看 :)

那么到底什么是函数式呢？听上去好厉害，好高大上的样子。

大家都知道面向对象编程提到的几个特性：封装，继承，多态，一切皆对象。那么其实函数式编程也有它固有的几个特点：不可变量，惰性求值，高阶函数，无副作用，一切皆函数。

## 从停机问题开始



调程序的时候经常会遇到死循环的Bug，聪明的你有没有想过发明一个自动检查程序里面有没有死循环的工具呢？不管你有没有过这种想法，反正我有过，可惜答案是，没有！

停机问题在[wiki](https://en.wikipedia.org/wiki/Halting_problem)上的描述比较学术，又是什么图灵机，又是数学中的集合。因为涉及到[计算理论](https://en.wikipedia.org/wiki/Theory_of_computation)的东西，为了防止小白看不懂，下面用一个小白话来讲，

停机问题：**<font color="red">给定任意一个程序及其输入，判断该程序是否能够在有限次计算以内结束。</font>**

## 假设存在停机算法



如果存在停机算法，那么对于给定任意一个函数以及这个函数的输入,停机算法就能告诉你这个函数会不会结束。
``` javascript
function isHalting(func,input){
    return if_func_will_halt_on_input;
}
```

## 利用停机判定


设一个函数，并调用它自身:
``` javascript
function foo(func){
    if(isHalting(func,func)){
        while(true);
    }
}

// 判定自身
foo(foo);
```
这是一个悖论：**<font color="red">当函数foo以foo为输入时，到底停机还是不停机？ </font>**


## lambda演算语法



停机问题只是个引子，接下来让我们步入正题。

用形式化的表述，[λ演算](https://en.wikipedia.org/wiki/Lambda_calculus)的语法只有三条：
- <表达式> ::= <标识符>
- <表达式> ::= λ <标识符+> . <表达式>
- <表达式> ::= (<表达式> <表达式>)

例如，根据以上语法，可以写一个加法函数。注意，这个函数是**匿名**的:
``` lisp
λ x y. x + y
```
之前定义的3条语法，前二条是用于产生函数，第三条用于函数调用。

``` lisp
; 输出5 
((λx y. x + y) 2 3) 

;为了方便，把匿名函数绑定到一个变量
let add = λ x y. x + y
;输出5
(add 2 3) 
```
看到这里，其实知道Lisp语言的同学可能就有种似曾相识的感觉了。Lisp语言就是一种函数式编程语言，函数式编程语言就是基于lambda演算发展起来的。细心的人已经发觉，lambda演算与图灵机模型对比，它其实更加侧重于计算的描述，甚至表达式不需要关心函数名，它仅仅是个描述计算过程的计算体。所谓的lambda表达式就是这种计算体的一种叫法，只是在各种编程语言环境下，lambda表达式换了个语法而已。

## lambda演算公理

以下是lambda演算的公理系统:

置换公理
- λ x y. x + y => λ a b. a + b

代入公理
- (λx y. x + y) a b => a + b 

## 函数生成器

lambda演算相当于一个函数生成器:
``` lisp
let mul = λx y. x*y
let con = λx y. xy

; 代入

mul 3 5  -­‐> 3 * 5 
con 'fu' 'ck' -->  'fuck'
```

## 定义IF函数

大家都知道在函数式编程里，一切皆函数，就连什么平时接触到的for，if等语句都不例外。那么在函数式编程里面如何构造一个IF函数呢？

``` lisp
;第一个参数condition为if函数的判断条件，如为真，则执行true_value,反之，false_value

let if = λ condition true_value false_value .
         (condition and true_value) or (not condition and false_value)


;调用if,输出15

if true (mul 3 5) (add 2 3)

=> (true and (mul 3 5)) or (not true and (add 2 3))
=> (mul 3 5) or false 
=> (mul 3 5)
=> 15

;调用if,输出5

if false (mul 3 5) (add 2 3)

=> (false and (mul 3 5)) or (not false and (add 2 3))
=> false or (add 2 3) 
=> (add 2 3)
=> 5
         
```

# 递归

---

来个有意思点的计算，定义一个计算n的阶乘的函数:
``` lisp
let fact = λ n .
          if (n == 0) 1 
                     (mul (n 
                          (fact n - 1)))
```

问题出现了，我们在定义fact的时候引用的自身（废话，递归不调用自身还叫递归？）。虽然在实际的编译器处理过程中，编译器都可以识别这种定义，但是这不符合严谨的数学公理体系。

## 如何表达递归

之前的fact函数不是无法引用自身吗？那么我们把“自身”参数化，那么函数内部就可以引用了。
``` lisp
let P = λ self n .
        if ( n == 0) 1 (mul 
                        (n
                         (self n - 1))
```

然后，再令:
``` lisp
let fact n = P (P n)

; 然后调用,输出24
fact 4
-> P (P 4)
-> if (4 == 0) 1 (mul 4 (P (P n-1)))
-> (mul 4 (P (P 3)))
-> 4 * P (P 3)
-> 4 * 3 * P (P 2)
-> 4 * 3 * 2 * P (P 1)
-> 4 * 3 * 2 * 1
-> 24
```
可惜，以上还不是真正的递归,只是每次额外多传入了一个参数，反复调用而已。我们的目的是要一个真正的递归函数,但是lambda演算没有这样一个公理可以在定义函数的时候引用自身，怎么办？

## Y组合子与不动点

不管之前的说法，我们就认定真正的fact是存在的:
``` lisp
;之前的函数P，为了方便，乘法表示就不用自定义的函数mul了
let P = λ self n .
        if ( n == 0) 1 ( n * self (n - 1))
                         
; 函数P接收2个参数，但是我们可以让函数柯里化(Currying),有时候又称部分求值(Partial Evaluation)
; P接收一个fact，本质上又产生了一个新的单参函数

P (fact) -> λ n .
        if ( n == 0) 1 ( n * fact (n - 1))


```
>*注: [函数柯里化](https://en.wikipedia.org/wiki/Currying)本质的意义是把一个多参的函数转换成单参函数作为返回值的形式,这样方便优化，有兴趣可以看知乎的讨论，[柯里化对函数式编程有何意义？](https://www.zhihu.com/question/20037482), [如何理解functional programming里的currying与partial application?](https://www.zhihu.com/question/30097211)*

然后，神奇的事发生了,细心的人发现，函数 P (fact) 与之前定义的函数fact相等，
 - P (fact) = fact

我们发现了函数P的一个[不动点](https://en.wikipedia.org/wiki/Fixed-point_combinator),什么是不动点呢？就是一个点（广义上的）在一个函数的映射下,函数的值仍然为这个点: f(x) = x 。所以，思路就是找到不动点，如果找到了不动点，就可以把“伪递归”函数P转化为真正的递归函数了。


（ To be continue, 时间不够）






