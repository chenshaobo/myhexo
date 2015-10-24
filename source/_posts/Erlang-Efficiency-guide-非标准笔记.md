title: Erlang_Efficiency_guide_非标准笔记
date: 2015-10-24 14:27:28
tags: [Erlang]
---
Efficiency guide 译文
===

timer模块
====
通过`erlang:send_after/3` 或`erlang:start_timer/3` 来启动一个定时器会比使用timer模块更加有效率。timer模块使用一个独立的进程来管理定时器，因此该进程很容易过载，如果很多进程频繁创建或取消定时器。

`list_to_atom/1`
====
Atoms 是不参与垃圾回收的。一旦一个原子被创建，它将不会被回收，Erlang虚拟机会因为atoms数量太多（默认1048576）而导致崩溃。
因此，转换输入的字符参数变成atom会导致系统变得不安全。如果只允许已经定义的原子可以允许被转换，可以使用 `list_to_existing_atom/1`去避免服务器崩溃。（这就使得我们需要提前创建所有允许被创建的atiom

`length/1`
====
执行`length/1`所消耗的时间是与输入列表的长度成比例增长的。而 `erlang:tuple_size/1`、`byte_size/1`、和`bit_size/1`的执行时间是常量时间。因此避免对长度过长的list进行`leng/1`运算。一些对`length/1`的使用可以被替换成模式匹配，比如：
    foo(L) when length(L) >=3 -> .....
可以替换为
    foo([_,_,_|_]=L)->....
另外对不使用的变量命名为`_`也可以提升程序效率。

`setelement/3`
====
`setelement/3`复制它修改的元祖，因此，在循环中调用`setelement/3`将会每次都创建新的副本。如果无法优化循环调用`setelement/3`的代码，那么对一个大tuple修改多个元素的最优办法就是将tuple转换为list修改list后再转换会tuple。

`size/1`
====
`size/1`可以返回tuple或binary的大小。使用 BIFs `tuple_size/1`和 `byte_size/1`可以让编译器和运行时系统去优化性能。

`split_binary/2`
====
通过模式匹配来切分binary会比调用`split_binary/2`来的快。另外，混合比特语法匹配和split_binary/2 会阻止一些对对比特语法匹配的优化。
这样：
    "  Bin1:Num/binary,Bin2/binary  " =Bin`
而不要：
    {Bin1,Bin2}=split_binary(Bin,Num)

'--'操作符
====
列表的长度越长，`--`的效率就越低。
不要：
    HugeList1 -- HugeList2
而是这样(对列表元素没有顺序要求的列表使用）：
    HugeSet1 = ordsets:from_list(HugeList1),
    HugeSet2 = ordsets:from_list(HugeList2),
    ordsets:subtract(HugeSet1,HugeSet2)
对于对列表元素有顺序要求的列表：
`    Set=gb_sets:from_list(HugeList2),
    [E|| E 《-HugeList1, not gb_sets:is_element(E，Set)]`

binaries 是如何被实例化的
====
在内部来说，binaries和bitstring是一样的东西。
在虚拟机内部有四种类型的binary对象。有两种包含了binary数据，另外两种仅仅只是引用了binary的一部分。而binary容器是 引用binaries（引用计数binaries的缩写）和堆binaries（heap binaries）。
- Refc binaries 包含两部分：
  1.一个保存在进程堆的（process heap）对象，即ProcBin,所有的ProcBin都是进程链接的一部分，因此gc 会追踪它们，并且在ProcBin消失后减少引用次数。
  2.保存在所有进程堆之外的binary对象，binary对象可以被任意个ProcBins（任意个进程中）引用，它包含了引用计数器用来计算当前引用的数量，当引用数量为0时就会被回收。
- Heap binaries 是小binaries，最大为64字节。所以直接保存在程序的堆中。它将会在进程gc或当作消息发送时被复制，gc不需要任何的处理就可以回收。
有两种类型的引用对象可以引用 一个refc binary 或 heap binary，它们就是 sub binaries 和 匹配文本。
sub binaries 由 `split_binary/2` 创建或者匹配到一个binary时。sun binaries 只是引用了其他binaries的一部分（refc binaries 或heap binary），因此匹配binaries是非常廉价的，因为他不会发生任何的拷贝。
上下文匹配和sub binary类似，不同的是对binary 匹配做了优化；举个例子，它包含了一个直接指向binary数据的指针。

构造二进制
====
运行时系统特别对附加binary作了优化，举个例子：
    Bin0= "  0 ",  %%为变量Bin0绑定一个heap binary，
    Bin1="  Bin0/binary,1,2,3  "  %%创建一个refc binary 其内容是Bin0的副本，refc binary的ProcBin部分拥有数据的大小（数据存储到二进制中的大小），binary object 却会有额外的空间被开辟，binary object的大小可能是 Bin0的两倍或者是256（或者更大）。
    Bin2 =" Bin1/binary,4,5,6"



