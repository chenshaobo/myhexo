title: erlang程序优化点
date: 2015-11-11 01:54:26
tags: [Erlang]
---
 进程标志设置
======
       消息和binary内存：erlang:process_flag(min_bin_vheap_size, 1024*1024)，减少大量消息到达或处理过程中产生大量binary时的gc次数
       堆内存：erlang:process_flag(min_heap_size, 1024*1024)，减少处理过程中产生大量term，尤其是list时的gc次数
       进程优先级：erlang:process_flag(priority, high)，防止特殊进程被其它常见进程强制执行reductions
       进程调度器绑定：erlang:process_flag(scheduler, 1)，当进程使用了port时，还需要port绑定支持，防止进程在不同调度器间迁移引起性能损失，如cache、跨numa node拷贝等，当进程使用了port时，主要是套接字，若进程与port不在一个scheduler上，可能会引发严重的epoll fd锁竞争及跨numa node拷贝，导致性能严重下降

 虚拟机参数
======
     +S X:X ：启用调度器数量，多个调度器使用多线程，有大量锁争用
     -smp disable ：取消smp，仅使用单线程，16个-smp_disabled虚拟机性能高于+S 16:16
     +sbt db ：将scheduler绑定到具体的cpu核心上，再配合erlang进程和port绑定，可以显著提升性能，但是如果绑定错误，反而会有反效果


消息队列
======
     消息队列长度对性能的影响主要体现在以下两个方面：进程binary堆的gc和进程内消息匹配，前者可以通过放大堆内存来减少gc影响，后者需要谨慎处理。
     若进程在处理消息时是通过消息匹配方式取得消息，同时又允许其它进程无限制投递消息到本进程，此时会引发灾难，匹配方式取得消息会引发遍历进程消息队列，如果此时仍然有其它进程投递消息，会导致进程消息队列暴涨，遍历过程也将增大代价，引发恶性循环。已知模式有：在gen_server中使用file:write（raw模式）或gen_tcp:send等，这些操作都是erlang虚拟机内部通过port driver实现的，均有内部receive匹配接收，对于这些操作，最好的办法是将其改写为nif，直接走进程堆进行操作，次之为将`file:write`或`gen_tcp:send`改写为两阶段，第一阶段为port_command，第二阶段由gen_server接收返回结果，这种异步化可能有些正确性问题，对于`gen_tcp:send`影响不大，因为网络请求本身要么同步化要么异步化，都需要内部的确认机制；对于`file:write`影响较大，`file:write`的错误通常为目录不存在或磁盘空间不足，确保这两个错误不造成影响即可，同时如果进程的其它部分需要使用file的其它操作，必须首先清空之前file:write产生的所有file的port消息，否则有可能产生消息序列紊乱的问题。
     对于套接字的接口调用，可以参考rabbitmq的两阶段套接字发送方法，而对于文件接口调用，可以参考riak的bitcask引擎将文件读写封装为nif的方法

内存及ets表
======
     ets表可以用于进程间交换大数据，或充当缓存，以及复杂匹配代理等，其性能颇高，并发读写可达千万级qps，并有两个并发选项，在建立表时设置，分别是{write_concurrency, true} | {read_concurrency, true}，以允许ets的并发读写
     使用ets表可以绕过进程消息机制，从而在一定程度上提高性能，并将编程模式从面向消息模式变为面向共享内存模式

 CPU密集型操作
======
     erlang执行流程的问题：
       1. 其指令都是由其虚拟机执行的，一条指令可能需要cpu执行3-4条指令，一些大规模的匹配或遍历操作会严重影响性能;
       2. 其bif调用执行过程类似于操作系统的系统调用，需要对传入参数进行转换，在大量小操作时损失性能较为严重
       3. 其port driver流程较为繁冗复杂，需要经历大量的回调等，一般的小功能操作，不要通过port driver实现
     建议：
       字符串匹配不要通过list进行，最好通过binary；单字节匹配，尤其是语法解析，如xmerl、mochijson2、lexx等，尽管使用binary，但是它们是一个字节一个字节匹配的，性能会退化到list的水平，应该尽量将其nif化；
       对于一些小操作，反而应该去bif化、去nif化、去port driver化，因为进入erlang内部函数的执行代价也不小；
       已知的性能瓶颈：re、xmerl、mochijson2、lexx、erlang:now、calendar:local_time_to_universal_time_dst等

数据结构
======
     减少遍历，尽量使用API提供的操作
     由于各种类型的变量实际可以当做c的指针，因此erlang语言级的操作并不会有太大代价
     lists：reverse为c代码实现，性能较高，依赖于该接口实现的lists API性能都不差，避免list遍历，[||]和foreach性能是foldl的2倍，不在非必要的时候遍历list
     dict：find为微秒级操作，内部通过动态hash实现，数据结构先有若干槽位，后根据数据规模变大而逐步增加槽位，fold遍历性能低下
     gb_trees：lookup为微秒级操作，内部通过一个大的元组实现，iterator+next遍历性能低下，比list的foldl还要低2个数量级
     其它常用结构：queue，set，graph等

 计时器
======
     erlang的计时器timer是通过一个唯一的timer进程实现的，该进程是一个gen_server，用户通过timer:send_after和timer:apply_after在指定时间间隔后收到指定消息或执行某个函数，每个用户的计时器都是一条记录，保存在timer的ets表timer_tab中，timer的时序驱动通过gen_server的超时机制实现。若同时使用timer的用户过多，则tiemr将响应不过来，成为瓶颈。
     更好的方法是使用erlang的原生计时器erlang:send_after和erlang:start_timer，它们把计时器附着在进程自己身上。

 尾调用和尾递归
======
     尾调用和尾递归是erlang函数式语言最强大的优化，尽量保持函数尾部有尾调用或尾递归

文件预读，批量写，缓存
======
     这些方式都是局部性的体现：
     预读：读空间局部性，文件提供了read_ahead选项
     批量写：写空间局部性
       对于文件写或套接字发送，存在若干级别的批量写：
         1. erlang进程级：进程内部通过list缓存数据
         2. erlang虚拟机：不管是efile还是inet的driver，都提供了批量写的选项delayed_write|delay_send，
            它们对大量的异步写性能提升很有效
         3. 操作系统级：操作系统内部有文件写缓冲及套接字写缓冲
         4. 硬件级：cache等
     缓存：读写时间局部性，读写空间局部性，主要通过操作系统系统，erlang虚拟机没有内部的缓存

套接字标志设置
======
     延迟发送：{delay_send, true}，聚合若干小消息为一个大消息，性能提升显著
     发送高低水位：{high_watermark, 128 * 1024} | {low_watermark, 64 * 1024}，辅助delay_send使用，delay_send的聚合缓冲区大小为high_watermark，数据缓存到high_watermark后，将阻塞port_command，使用send发送数据，直到缓冲区大小降低到low_watermark后，解除阻塞，通常这些值越大越好，但erlang虚拟机允许设置的最大值不超过128K
     发送缓冲大小：{sndbuf, 16 * 1024}，操作系统对套接字的发送缓冲大小，在延迟发送时有效，越大越好，但有极值
     接收缓冲大小：{recbuf, 16 * 1024}，操作系统对套接字的接收缓冲大小

序列化/反序列化
======
     通常情况下，为了简化实现，一般将erlang的term序列化为binary，传递到目的地后，在将binary反序列化为term，这通常涉及到两个操作：
     term_to_binary及binary_to_term，这两个操作性能消耗极为严重，应至多只做一次，减少甚至消除它们是最正确的，例如直接构造binary进行跨虚拟机数据交换；
     但对比与其它的序列化和反序列化方式，如利用protobuf等，term_to_binary和binary_to_term的性能是高于这些方式的，毕竟是erlang原生格式，对于力求简单的应用，其序列化和反序列化方式推荐term_to_binary和binary_to_term

并发化
======
     在一些场景下，如web请求、数据库请求、分布式文件系统等，单个接入接口已经不能满足性能需求，需要有多个接入接口，多个数据通道，等等，这要求所有请求处理过程必须是无状态的，或者状态更改同步进入一个公共存储，而公共存储也必须是支持并发处理的，如并发数据库、类hdfs、类dynamo存储等，若一致性要求较高，最好选用并发数据库，如mysql等，若在此基础上还要求高可用，最好选择同步多结点存储，
     mnesia、zk都是这方面的典型；若不需要较高的一致性，类hdfs、类dynamo这类no sql存储即可满足

 hipe
======
     将erlang汇编翻译成机器码，减少一条erlang指令对应的cpu指令数
