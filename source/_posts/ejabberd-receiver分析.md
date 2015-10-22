title: ejabberd_receiver分析
date: 2015-10-22 20:10:51
tags: [Ejabberd]
---

ejabberd_receiver 分析
=====
`ejabberd_receiver`是ejabberd 中 网关层的数据receive模块，客户端发送的数据通过`ejabberd_receiver` 接收并通过xml port解析后发送给 ejabberd_c2s的实例处理，至于它的加密、压缩、解压之类的就不说了。

主要说一下这个shaper（字母翻译：脉冲整形器，个人理解，流量控制）机制,什么意思呢？

原来 `ejabberd_receiver`会根据本次socket接收到的包的大小，判断是否需要缓冲一会再接收下一个socket包，这里用到了socket参数`{active, once}`

算法如下：
    根据本次收到的包的大小 和 maxrate 算出应该缓冲多少s，再算出上一次 到 本次接收数据包的时间间隔来决定是否需要缓冲。

shaper:update/2:

```erlang
update(none, _Size) -> {none, 0};
update(#maxrate{} = State, Size) ->
    MinInterv = 1000 * Size /(2 * State#maxrate.maxrate - State#maxrate.lastrate),
    Interv = (now_to_usec(now()) - State#maxrate.lasttime) /1000, 
    ?DEBUG("State: ~p, Size=~p~nM=~p, I=~p~n",
    [State, Size, MinInterv, Interv]),
    Pause = if 
                MinInterv > Interv ->
                    1 + trunc(MinInterv - Interv);
                true -> 0
            end,
    NextNow = now_to_usec(now()) + Pause * 1000,
    {State#maxrate{lastrate =(State#maxrate.lastrate + 1000000 * Size / (NextNow - State#maxrate.lasttime)) / 2, lasttime = NextNow},
    Pause}.
```

ejabberd_receive:process_date/2

```erlang
process_data(Data,#state{xml_stream_state = XMLStreamState,shaper_state = ShaperState, c2s_pid = C2SPid} =State) ->
    ?DEBUG("Received XML on stream = ~p", [(Data)]),
    XMLStreamState1 = xml_stream:parse(XMLStreamState, Data),
    lager:info("XMLStreamState1 ~p",[XMLStreamState1]),
    {NewShaperState, Pause} = shaper:update(ShaperState, byte_size(Data)),
    lager:info("pause :~p \n pid :~p",[Pause,C2SPid]),
    if
        C2SPid == undefined ->
            ok;
        Pause > 0 ->
            erlang:start_timer(Pause, self(), activate);
        true ->
            activate_socket(State)
    end,
    State#state{xml_stream_state = XMLStreamState1,shaper_state = NewShaperState}.
```
