title: Riak安装与MapReduce测试
date: 2015-10-22 20:33:37
tags: [Riak,MapReduce]
---
Riak安装与MapReduce测试
===
1.安装环境:
=====
1. Ubuntu 14.04
2. riak-2.1.1 源码编译
3. erlang版本R16B03-1(注意 riak目前还不支持R17以上的erlang 版本)

2.依赖安装
=====
1. ssl :sudo apt-get install libssl0.9.8
2. pam library: sudo apt-get install libpam0g-dev

3.下载并编译riak
=====
1. 下载:`wget http://s3.amazonaws.com/downloads.basho.com/riak/2.1/2.1.1/riak-2.1.1.tar.gz`
2. 解压:`tar zxvf riak-2.1.1.tar.gz`
3. 编译:`cd riak-2.1.1 && make`

4.构建riak集群
=====
1. 生成riak node实例:`make devrel DEVNODES=$N`,其中N是想要生成的节点数
2. 配置riak node ：riak的配置文件位于 $RIAK_HOME/dev/dev*/etc/riak.conf,可以配置节点名称,HTTP服务监听IP和端口,PCB 协议监听IP和端口storage backend(存储后端) 等。
3. 启动riak node :`$RIAK_NODE_ROOT/bin/riak start`
4. 组成集群

  1. 加入集群： `$RIAK_NODE_ROOT/bin/riak-admin cluster join $NODENAME`
  2. `$RIAK_NODE_ROOT/bin/riak-admin cluster plan`
  3. 提交:`$RIAK_NODE_ROOT/bin/riak-admin cluster commit`
  4. 查看集群状态:`$RIAK_NODE_ROOT/bin/riak-admin member-status`

5.相关官方文档
=====
1. riak.conf 配置文件：`http://docs.basho.com/riak/2.1.1/ops/building/configuration/`
2. riak和riak-admin:`http://docs.basho.com/riak/2.1.1/ops/running/tools/riak/` 、`http://docs.basho.com/riak/2.1.1/ops/running/tools/riak-admin/`
3. 存储后端的选择：`http://docs.basho.com/riak/latest/ops/building/planning/backends/`
4. MapReduce:`http://docs.basho.com/riak/2.1.1/dev/advanced/mapreduce/`

6.MapReduce 实践
=====
MapReduce是Riak主要用于非主键查询的方法，但是MapReduce 操作的代价是十分昂贵的，甚至会降低生产环境集群的性能。因此，应当尽量少用MapReduce，并且永远不要用于实时查询。Riak允许你通过Erlang或者Javascript来进行MapReduce操作，但是从Riak2.0开始，javascript开始被弃用。
MapReduce测试：
五台机器，组成集群：
一台 
model name      : Intel(R) Core(TM) i5-4460  CPU @ 3.20GHz
MemTotal:        1429236 kB
四台
Intel(R) Xeon(R) CPU E5-2620 0 @ 2.00GHz
MemTotal:       65897328 kB


在erlang shell里面输入：
```erlang
    {A,B,C}=erlang:now(),
    {ok, Soc1} = riakc_pb_socket:start_link("127.0.0.1", 10017),
    Map =fun(V, _, _) ->
        {struct, PropList} = mochijson2:decode(riak_object:get_value(V)),
        U = proplists:get_value(<<"user_id">>, PropList),
        [dict:from_list([{U, 1}])]
    end,
    Reduce = fun(Results, _) ->
        Return =
        lists:foldl(fun(D, Acc) ->
        dict:merge(fun(_, X, Y) -> X + Y end, D, Acc)
        end, dict:new(), lists:flatten([Results])),
        [Return]
    end,
    Reslut = riakc_pb_socket:mapred_bucket(Soc1, <<"user_read_log4">>, [{map, {qfun, Map}, none, false}, {reduce, {qfun, 		Reduce}, none, true}], 6000000),
    {A1,B1,C1}=erlang:now(),
    (A1* 1000000000000 + B1*1000000 + C1)  - (A* 1000000000000 + B*1000000+ C).
```

%通过PCB接口，使用erlang进行MapReduce处理 240080 条数据，耗时 62112283 微秒，约等于 62s

```shell
  root@localhost:/data/riak-2.1.1# date +%s
	1442537754
	root@localhost:/data/riak-2.1.1# curl -XPOST -H"content-type: application/json"\
        http://localhost:10018/mapred --data @-<<\EOF
    	{"inputs":"user_read_log4","query":[{"map":{"language":"javascript","source":"
    	function(v) {
    	var data=Riak.mapValuesJson(v)[0];
    	var r={};
    	r[data.user_id]=1;
   	return [r];
    	}","keep":false}},
    	{"reduce":{"language":"javascript","source":"
    	function(v){
                    var i, j, r = {}, w;
                for (i = 0; i < v.length; i += 1) {
                    for (w in v[i]) {
                        if (v[i].hasOwnProperty(w)) {
                            if (r[w]) { r[w] += v[i][w]; }
                            else { r[w] = v[i][w]; }
                        }
                    }
                }
                return [r];
    	}"
    	}}],"timeout":1000000}
 	EOF
	root@localhost:/data/riak-2.1.1# date +%s
	1442538003
```


%通过http接口，使用javascript 进行Mapreduce 处理240080 条数据，1442538003-1442537754=249s

```erlang
	map_javascript()->
    	{A,B,C}=erlang:now(),
    	{ok, Soc1} = riakc_pb_socket:start_link("127.0.0.1", 10017),
    	Map= <<"function(v) { var data=Riak.mapValuesJson(v)[0];var r={};r[data.user_id]=1;return [r];}">>,
    	Reduce= <<"function(v){var i, j, r = {}, w;for (i = 0; i < v.length; i += 1) {for (w in v[i]) \
           {if (v[i].hasOwnProperty(w)) {if (r[w]) { r[w] += v[i][w]; }else { r[w] = v[i][w]; }}}}return [r];}" >>,
    	Result=riakc_pb_socket:mapred_bucket(Soc1, <<"user_read_log4">>, [{map, {jsanon, Map}, none, false}, {reduce, {jsanon, Reduce}, none, true}], 6000000),
    	{A1,B1,C1}=erlang:now(),
    	{Result,(A1* 1000000000000 + B1*1000000 + C1)  - (A* 1000000000000 + B*1000000+ C)}.

	(book_club_server@localhost)11> bus_user_read_behaviortrace_handler:map_javascript().
	{{ok,[{1,
       	[{struct,[{<<"201507301601028734">>,27301},
                 {<<"201507301601028728">>,26948},
                 {<<"201507301601028735">>,23250},
                 {<<"201507301601028733">>,27156},
                 {<<"201507301601028730">>,27175},
                 {<<"201507301601028732">>,26993},
                 {<<"201507301601028727">>,26930},
                 {<<"201507301601028729">>,27177},
                 {<<"201507301601028731">>,27150}]}]}]},240914091}
```
%通过PCB协议接口，使用Javascript 进行MapReduce处理240080 条数据，耗时 240914091微妙 ，约240秒.
```


通过上面的测试，我们就可以知道为什么Riak自己都不推荐使用Javascript 进行MapReduce了，使用Erlang  的进行MapReduce的效率几乎是 javascript 的4倍。



