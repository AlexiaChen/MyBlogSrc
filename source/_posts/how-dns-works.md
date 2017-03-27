---
title: DNS是怎样工作的？
date: 2017-03-09 15:38:56
tags:
    - DNS
    - 计算机网络
    - TCP/IP
---

>*直接开始正文算了，主要是总结。*

## Episode 1-----网站是未知的
---

先来陈述一个事实，计算机和其他设备在因特网上互相通信识别对方都是通过IP地址进行的。但是人们并不擅长记忆类似于10.0.0.1 192.168.1.0等这样的IP地址，所以就用了字符文字串（google.com, wikipidia.org）

而域名系统（Domain Name System, DNS）,就是把IP地址和字符文本串关联在一起的系统，这样就能找到IP地址了。

假设个场景： 小A在浏览器里输入的一串mathxh.com的网址

首先，浏览器和操作系统会去它们各自的缓存中检查是否有mathxh.com的地址，如果没有，那么操作系统会去请求**解析器**(resolver)

啥是resolver呀？请看下一章

## Episode 2-----漫漫长路
---

当当当，因为前一章节提到，cache里面没有mathxh.com的IP，所以这个请求到resolver了，resolver通常是你上网的ISP(Internet Service Provider)提供,也就是因特网服务提供商，你家办的是电信的宽带吗？ 这时候电信公司就是你的ISP。所有的Resolver必须知道一件事：<font color="red">根服务器在哪。</font>

根服务器又知道.com TLD 服务器(Top-Level Domain，顶级域名)在哪里。

等等，Resolver到底是啥？还是没有说清楚，其实Resolver就是我们通常所说的DNS服务器，你需要知道配置DNS server的IP地址来的，通常这个server由ISP提供，当然，也可以采用免费的域名提供商提供的server。比如：[OpenDNS](https://www.opendns.com/)。至于，怎么使用，配置下它提供的DNS server的IP地址就可以了。所以中国封锁网站都是封IP，不是封域名。对于个别封锁域名的网站，用OpenDNS提供的服务既可以上被封的网站，因为OpenDNS找得倒被封域名的IP啊。

## Episode 3-----层级结构的顶层
---

好了，咱的请求经过询问了根服务器后，得知了COM顶级域名服务器的地址（这个地址会缓存下来，下次就不必找根服务器了）。

然后，刚刚我们请求到达的根服务器只是全球13个根服务器其中的一个。根服务器在DNS层级结构中的最顶层。

![](http://wx1.sinaimg.cn/large/a1ac93f3gy1fdmgg2b0iwj207q04bt8o.jpg)

全球分散着13个独立的组织,他们与13个根服务器一一对应，这些服务器的名字是以[A-M].root-servers.net的形式存在，字符A-M，刚好是13个。
但是！这不是意味着全球只有13个物理根服务器来支撑整个互联网！这个13个根服务器每一个都会有多份自己的镜像服务器分布在全球各地。

## Episode 4-----顶级域名的大杂烩
---

当当当，我们的请求到达了.COM顶级域名服务器。

先说个题外话:
>*大部分顶级域名是归一个叫Internet Corporation for Assigned Names and Numbers(ICANN)的组织机构管理分配的。.COM这个顶级域名是世界上最早的一批创建的了，在1985年。现如今已成为互联网上最广泛的域名。*

当然了，还有很多其他类型的顶级域名，比如，.jp代表日本，.fr代表法国, .中国代表中国, 还有广为人知的.net,.org, .edu 。 最后还有一种域名,基础设施顶级域名(InfTLDs),比如, [.ARPA](https://en.wikipedia.org/wiki/.arpa), 一般用来DNS反向查找,简单来说就是，从IP地址查域名。

现今，还有很多杂七杂八的顶级域名被建立了：.hot , .pizza, .app, .health等等。

现在回到之前的场景，我们的请求到达了.COM顶级域名服务器，.COM服务器为我们找到了一系列已授权的名字服务器：ns1.mathxh.com, ns2.mathxh.com .... ns6.mathxh.com （可能更多）。

## Episode 5-----回家
---

由前一章节得知，问题来了，那么多个已授权的名字服务器，我到底该与哪个建立连接？（抓耳挠腮）。

简单！ 这就需要域名注册商的帮助了。

当买下域名的那一刻，域名注册商就联系顶级域名登记处预定这个名字,并把这个域名注册到已授权的名字服务器上（当然，这名字服务器有很多）。比如，一个域名example.com下面，就有多台对自己负责的名字服务器。

请求会直接去找ns1.mathxh.com的名字服务器，然后使用[WHOIS查询](https://en.wikipedia.org/wiki/WHOIS)，一般电脑上都安装这个工具了，最后，由其中一台nsX.mathxh.com告诉了我们mathxh.com的IP地址。

好了，完工了，请求记住了IP地址该原路返回回家了。请求把带回来的IP地址缓存了下来，以免下次需要使用又需要请求Resolver。最后，把IP地址告诉浏览器，浏览器就对IP地址开始真正请求访问了。

## 终章--------哎哎？ 好像错过了什么
---

在找到mathxh.com的IP地址之前，是怎么找到ns1.mathxh.com的地址的？
不是要询问ns1.mathxh.com才找到mathxh.com的IP吗？还没有找到主域名的IP，就可以找到子域名ns1.mathxh.com的IP了吗？好矛盾呀。

我们是不可能在找到主域名mathxh.com的IP前,就得到子域名的IP的，无解！

其实实际情况是这样的：
当resolver询问.COM顶级域名服务器的时候，会有一个额外的信息response。这个response内就包含mathxh.com底下至少一个子域名的实际IP地址，所以resolver就知道nsX.mathxh.com的IP地址了。

所以resolver不仅知道子域名的名字，还知道子域名的IP地址，所以就打破了之前无解的循环依赖，由子域名就可以找到主域名的IP地址，主域名也可以找到子域名IP。