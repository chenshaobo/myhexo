title: Erlang通过NIF集成c代码示例
date: 2015-10-22 21:24:21
tags: [Erlang]
---

ERLANG NIF 编写
===

很多时候一下计算量大，效率要求很高的地方也许使用c会好于erlang。

Erlang层代码
====
-  通过 `-on_load`模块属性，实现erlang vm 加载模块时同时加载c的共享库文件。
-   nif的函数erlang入口为 func(args) -> erlang:nif_error({error,not_loaded}).

C层代码
====
- 包含 erl_nif.h  , `#include<erl_nif.h>`，
- 注册NIF ,这里分为了三步：
  1. ErlNifFunc 数组，告诉erlang vm 库中实现的NIF，以及erlang函数名对应的c实现函数:
	static ErlNifFunc test_nifs[] =
	{ 
 	{"hello",1,&hello_1} 
	};
  2. ERL_NIF_INIT宏 将 ErlNifFunc数组联同所属模块的模块名告诉Erlang vm。`ERL_NIF_INIT(test_nif,test_nifs,NULL,NULL,NULL,NULL);`
  3. c实现函数 `static ERL_NIF_TERM hello_1(ErlNifEnv * env,int argc,const ERL_NIF_TERM argv[])` , 函数接受3个参数，并返回一个ERL_NIF_TERM对象，第一个参数env就是前面提到过的ErlNifEnv 指针。第二个参数argc是Erlang调用NIF时传入的参数数目。第三个参数argv中的元素就是传入的各个参数（数目与argc中的一致）。

3.编译c代码
   `gcc -o test_nif.so -fpic -shared -I/usr/local/lib/erlang/erts-5.10.4/include test_nif.c`.

test_nif.c

```c
#include<erl_nif.h>
#include<string.h>
static ERL_NIF_TERM hello_1(ErlNifEnv * env,int argc,const ERL_NIF_TERM argv[])
{
 	return enif_make_tuple2(env,enif_make_atom(env,"hello"),argv[0]);
}
static ErlNifFunc test_nifs[] =
{ 
 	{"hello",1,&hello_1} 
};
ERL_NIF_INIT(test_nif,test_nifs,NULL,NULL,NULL,NULL);
```

test_nif.erl

```erlang
-module(test_nif).
-on_load(init/0).
-export([hello/1]).
init()->
 	erlang:load_nif("./test_nif",0);
hello(Arg)->
 	erlang:nif_error({error, not_loaded}).
 ```

