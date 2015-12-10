title: io_lib:format 中文乱码探究
date: 2015-12-09 11:11:26
tags: [Erlang]
---

最近发现erlang项目的配置文件某些中文显示会乱码，先说下配置文件的实现：
 1. 由file:consult/1读取配置的原始文件（一系列的erlang term），获取到原始的 erlang term
 2. 再转化成erlang 代码 然后再会写到文件。

问题就出在了转化erlang 代码这里，我们使用的是`io_lib:format("~p",[data])` 来将erlang term 转化成字符串再回写到文件，而 `io:format/2`关于`~p/~w`在官方文档里面有这样的描述：
>w
>    Writes data with the standard syntax. This is used to output Erlang terms. Atoms are printed within quotes if they contain embedded non-printable 
>    characters, and floats are printed accurately as the shortest, correctly rounded string.
>p
>  Writes the data with standard syntax in the same way as ~w, but breaks terms whose printed representation is longer than one line into many lines and 
>     indents each line sensibly. It also tries to detect lists of printable characters and to output these as strings. The Unicode translation modifier is used for
>     determining what characters are printable. 

也就是说，当我们使用`io:format("~p",[Data])`来显示数据时，会根据data的binary数据是否可以转化成unicode可打印字符来打印数据，这时候中文的unicode就会每个字节逐个转化unicode
因此：
```erlang
6> Bin1=unicode:characters_to_binary("书鬼").
<<228,185,166,233,172,188>>
7> io:format("~p",[Bin1]).
<<"ä¹¦é¬¼">>ok
8> Bin2=unicode:characters_to_binary("书盲").
<<228,185,166,231,155,178>>
9> io:format("~p",[Bin2]).    
<<228,185,166,231,155,178>>ok

48> io:format("~w",[Bin1]).
<<228,185,166,233,172,188>>ok
49> io:format("~w",[Bin2]).
<<228,185,166,231,155,178>>ok
```

