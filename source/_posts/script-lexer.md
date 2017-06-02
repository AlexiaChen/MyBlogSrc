---
title: 词法分析器完成
date: 2017-03-27 14:48:40
tags: 
 - 词法分析
 - 编译原理
      
---

经过昨天一天的努力，我制作的Stone语言的Tokenizer已经完成了，之前不支持解析带有空格的String Literal，也不支持带有空格的注释(comments)。现在可以完美支持了，当然与其他语言工业级别的tokenizer，这个当然没法比，这仅仅是个玩具，为了方便之后的语法分析，Stone语言的本身设计也很简单，一些代码格式结构会强制要求，不然会解析错误。

这个tokenzier设计原理很简单，它根据文件按照行扫描的方式，逐行读取和解析，然后根据解析出来的token作分类，大致有String类，Identifier类，还有Number类，没有做更详细的细分，因为之后这个Stone语言的解释器会逐步完善添加功能，所以我把每个token都与它所在的行号做了关联，以后会有用处，类似于下面:

``` cpp

class Token
{
public:
    static const std::shared_ptr<Token> EOF_TOEKN; // end of file
    static const std::string EOL_TOKEN; // end of line
public:
    virtual int32_t getLineNumber() const { return m_line_number; }
    virtual bool isIdentifier() { return false; }
    virtual bool isNumber() { return false; }
    virtual bool isString() { return false; }
    virtual int32_t getNumber() { throw StoneException("not number token"); }
    virtual std::string getText(){ return std::string(""); }
public:
    explicit Token(int32_t line):m_line_number(line){}
private:
    int32_t m_line_number;
};

```
上面是Token的抽象类，如果需要自己实现特定的Token类，就子类化Token就可以了。

该词法分析器依赖于C++ 11的正则表达式库。我的想法也是尽量使用C++ 11/14的特性来完成一些功能。就这样吧，还有很多要做，以后还要加入语言的闭包等等，挑战不小。

这里是该项目的[Github地址](https://github.com/AlexiaChen/stone-lang-in-cpp)。