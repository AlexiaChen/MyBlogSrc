---
title: 最简单的计算机之有限自动机
date: 2018-10-15 20:30:48
tags: 
     - 程序语言理论
     - 有限自动机
---

> *简单是终极的复杂。* -- *达 芬奇*

## 前言

---

其实这算是计算理论的第二个章节，第一个章节可以去看我之前写的文章----[《程序的含义》](https://alexiachen.github.io/blog/2017/10/15/program-semantic/)。

追求简单是人类内心的本性使然，看上去好像没有太多修饰，当你仔细揣摩，你会发现，最精华的理论已经融入每个角落，越是简单的东西，其实越难吧空，需要经过千锤百炼。

现代计算机具有强大的计算能力，但是正是由于其强大，所以伴随着过多的复杂性。我们很难理解一台计算机多个子系统的全部细节，更别说理解这些子系统如何互相协作从而构成整个系统了。这些复杂性使得对真实的计算机的能力与行为进行直接推导显得不切实际，此时计算机的简化模型就显得非常有用。简单的模型只提取出真实计算机中令人感兴趣的特性，它可以帮助人们建立对计算完整的认知。

接下来，我们会逐步揭开什么是计算，最后分析这样简单的模型所能达到的计算极限。

## 确定性有限自动机

---

现实中，计算机通常有大量的RAM和DISK，还有许多I/O设备（键盘等），还有CPU。有限状态机也被称作有限自动机，这是一个极简的计算机模型。它为了简单，抛弃了RAM DISK等这些特性。

### 状态 规则 输入 输出

有限状态机你可以把它看作是一个抽象机器，它拥有一些可能的状态，能跟踪到自己当前具体处于其中的一个状态。注意，它没有键盘等这些接口，它只有一个抽象接口，就是一个来自外部的信息输入流会被它逐个读取，并随着这些信息的输入，自动转移状态。

以下是一个有限状态机的图示：

![](http://wx2.sinaimg.cn/large/a1ac93f3gy1fwbj5b9ttzj20a305p0sl.jpg)

至于状态机怎么看，我就不过多介绍了。如果学过《编译原理》的词法分析的章节，一定会接触到的。

- 该机器有两个状态， 1和2
- 该机器的输入字符集合为{a，b}
- 该机器的初始状态是1

该机器会根据读到的字符来决定转移的状态，它不停的接受a，b在状态1和2之间来回切换，简直没完没了了。它像一个黑盒子一样运行，谁也不知道发生了啥，机器外面没人知道发生了什么，所以机器要有个输出，我们才知道最终的结果，有了结果，机器就停止运行了，相当于这个函数才有了输出，有输入必然要有输出，不然没意义。 所以我们需要为这台机器增加一个终止状态，以表示运行结束，产生输出。

我们暂且把状态2标记为终止状态，当然如果用在词法分析理论上也可以被称为接受状态，表明机器对某个序列是接受还是拒绝。修改好的状态机图示如下：

![](http://wx4.sinaimg.cn/large/a1ac93f3gy1fwbjpr86a3j209903tq2s.jpg)

红色就表示终止状态。当然，正规点的自动机终止状态是画两个圆表示终止，我这里图个简便，请谅解下。

好了，我们来分析下。

上图的自动机初始化状态为1, 当读入一个字符a的时候，它会转移到状态2，这是一个终止状态，所以我们可以认为这自动机接受了字符串“a”。如果它又读取了一个字符b，状态又转移到了1,这不是终止状态，所以自动机不接受字符串“ab”，也就是拒绝了“ab”。所以很容易可以推理出来，自动机接受“a”，“aba”，“ababa”这样的字符串。如果把图示下面的字符b也换成a。那么自动机接受“a”，“aaa”，“aaaaa”这样奇数的a组成的字符串，拒绝“”，“aa”，“aaaa”这样偶数个字符a组成的字符串或空字符串。这台自动机就可以判断a组成的字符串是技术还是偶数，是足以称为最简单的计算机了。

当然，我们可以构造更复杂的自动机，我就不打算构造了。

### 确定性

显然，如果了解自动机概念的人，就知道之前所提到的自动机都是具有确定性，也就是说，无论它处于什么状态，并且无论读入什么字符，它最终所处的状态总是完全确定的。这样的确定性有2种约束条件：

- 不存在二义性，也就是说一个状态对于同样的输入，它不能有多个规则

- 每个状态都必须针对每个可能的输入字符至少有一个规则

具有这种确定性的自动机专业点叫确定性有限自动机（Deterministic Finite Automaton，DFA）。

### 用程序语言来实现DFA

DFA是一种抽象机器，也可以被认为是一种解释器，这种机器很容易用软件来模拟。

首先，需要定义一个规则集合RuleSet。

```ruby
class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state,character)
    self.state == state && self.character == character
  end

  def follow
    next_state;
  end

  def inspect
    "#<FARule #{state.inspect} --#{character}--> #{next_state}>"
  end
end

class DFARuleSet < Struct.new(:rules)
  def next_state(state,character)
    rule_for(state,character).follow
  end

  def rule_for(state,character)
    rules.detect { |rule| rule.applies_to?(state,character) } # find first if
  end
end

```

每个规则用一个FARule来表示，都有一个applies_to? 这样的API来判断某些输入情况下是否可以apply。DFARuleSet表示规则集合，相当于FARule类的一个容器，存放多个FARule。

好的，现在可以构造一个规则集合了：

```ruby

=begin
#<struct DFARuleSet rules=[#<FARule 1 --a--> 2>, #<FARule 1 --b--> 1>, #<FARule 2 --a--> 2>, 
#<FARule 2 --b--> 3>, #<FARule 3 --a--> 3>, #<FARule 3 --b--> 3>]>
=end
rules = DFARuleSet.new([
  FARule.new(1,'a',2), FARule.new(1,'b',1),
  FARule.new(2,'a',2), FARule.new(2,'b',3),
  FARule.new(3,'a',3), FARule.new(3,'b',3)
])

# 测试DFARuleSet类

# => 2
rules.next_state(1,'a')
# => 1
rules.next_state(1,'b')
# => 3
rules.next_state(2,'b')

```

到这里，是否能根据这个规则集合画出对应的DFA的图呢，这是可以的。下图就是以上RuleSet对应的自动机

![](http://wx3.sinaimg.cn/large/a1ac93f3gy1fwcprbf862j20ac05f0so.jpg)

不过，这台自动机没有终止状态，还不完整，所以我们要编写一个DFA的类的表示DFA来配置RuleSet和初始状态，终止状态，加入读取字符流的接口，并模拟抽象机器的运行，这样就灵活了。计算机科学很重要的一点就是抽象思维，分离变化与不变化。是不是跟上一章讲解语义的一样呢？其实都相当于一台解释器。

```ruby

class DFA < Struct.new(:current_state,:final_states,:ruleset)
  def accepting?
    final_states.include?(current_state)
  end

  def read_char(character)
    self.current_state = ruleset.next_state(current_state,character)
  end

  def read_string(str)
    str.chars.each do |character|
      read_char(character)
    end
  end  
end

# 测试下DFA

# => true
DFA.new(1,[1,3],rules).accepting?

# => false
DFA.new(1,[3],rules).accepting?

```

之后，为了更加方便，我们构造一个可以创建DFA的工厂类：

```ruby

class DFAMaker < Struct.new(:start_state, :final_states, :ruleset)
  def make_dfa
    DFA.new(start_state,final_states,ruleset)
  end
  
  def accepts?(str)
    make_dfa.tap { |dfa| dfa.read_string(str) }.accepting?
  end
end

# => false
DFAMaker.new(1,[3],rules).accepts?('a')

# => false
DFAMaker.new(1,[3],rules).accepts?('baa')

# => true
DFAMaker.new(1,[3],rules).accepts?('babab')

# => true
DFAMaker.new(1,[2],rules).accepts?('aaaa')

# => false
DFAMaker.new(1,[1],rules).accepts?('a')

# => true
DFAMaker.new(1,[1],rules).accepts?('b')

```

## 非确定性有限自动机

（to be continued）