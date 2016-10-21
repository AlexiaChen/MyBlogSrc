---
title: 烦人的Scala的构建工具
date: 2016-10-20 09:39:40
tags: 
 - Scala
 - 构建工具
      
---

  有关构建工具针对不同的编程语言有很多，林林种种，也用过一些，像C/C++的Cmake，Java的Maven，Ant。还有Gradle（它支持Java，Scala，Groovy的构建）。还有一个Scala-SBT（Scala Simple Build Tool）,是一个针对Scala工程的构建工具。直接用Scala作为构建逻辑的DSL。问题是Scala这种融合多重编程思想揉杂的语言，本身就复杂，灵活多变，把它作为一种构建的DSL是不是过分了？构建这种是很普适的过程，其中并没有什么复杂的逻辑，是否应该用更加不这么极端的语言来描述一个构建过程？ 

  另外想吐槽下，Windows下编译开源软件或者是搭建开源软件的开发调试环境真是麻烦，不如Unix-like的系统方便。Linux虽然丑，但是这丑是载入史册的，做得一丝不苟，有据可查，非常标准化。


![](http://ww4.sinaimg.cn/large/a1ac93f3gw1f8yhsfpyzfj211e0g4agw.jpg "Sbt")