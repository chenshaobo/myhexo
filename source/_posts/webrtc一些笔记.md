title: webrtc一些笔记
date: 2016-09-13 10:02:05
tags: [webrtc,peer to peer]
---
#### webrtc一些笔记

##### 基础框架
 ![](http://7xj8b1.com1.z0.glb.clouddn.com/turn.png)

组成部分：
1. Signalling,客户端session控制，网络和多媒体信息同步的机制。不是RTCPerrConnection API的一部分，用户可以根据需求自己定义和实现signalling，signalling主要用于三种类型的信息：
   - session控制消息：初始化或关闭 会话，还可以上报错误
   - 网络配置：通过signalling告诉 第三方(想和自己连接的Peer)自己的IP和Port
   - 多媒体文件处理能力:决定双方的多媒体文件的编码、解码格式。

2. ICE framework 用于连接Peer(端点)间的互相连接.
3. STUN 和 STUN协议的扩展 [TURN](https://en.wikipedia.org/wiki/Traversal_Using_Relays_around_NAT)协议，这个主要是[ICE](https://en.wikipedia.org/wiki/Interactive_Connectivity_Establishment) framework 用来支持 NAT穿透，使得 RTCPeerConnection 能够应对变幻莫测的网络环境。



`stun`的`long-term credential mechanism` 的key 可以通过`coturn`的 `turnadmin -a -u username -p password -k`获得,也就是说如果通过`udp`连接到`coturn server`则需要通过 `long-term credential mechanism` 来认证,下面的例子：
 
server:  
```
turnserver  --user=ninefingers:0xbc807ee29df3c9ffa736523fb2c4e8ee --user=gorst:hero -r north.gov --cert=turn_server_cert.pem  --pkey=turn_server_pkey.pem --log-file=stdout -v --mobility --cipher-list=ALL $@
```
client 使用udp:
```
turnutils_uclient  -z 5 -n 10 -s -m 1 -l 170 -e 127.0.0.1 -X -g -u ninefingers -w youhavetoberealistic   $server_ip -v
```
client 使用tcp:
```
turnutils_uclient  -z 5 -n 10 -s -m 1 -l 170 -e 127.0.0.1 -X -g -u gorst -W hero  $server_ip -v
```
注意在server命令中 `--user=ninefingers:0xbc807ee29df3c9ffa736523fb2c4e8ee`和`--user=gorst:hero`的不同。

简单的来说，`stun` 用来告诉client自身穿透nat之后的公网ip和端口是多少，而`turn`则是扩展了中继转发功能,`turn`具体流程如下：
```
                                                            Peer A
                                       Server-Reflexive    +---------+
                                       Transport Address   |         |
                                       192.0.2.150:32102   |         |
                                           |              /|         |
                         TURN              |            / ^|  Peer A |
   Client’s              Server            |           /  ||         |
   Host Transport        Transport         |         //   ||         |
   Address               Address           |       //     |+---------+
  10.1.1.2:49721       192.0.2.15:3478     |+-+  //     Peer A
           |               |               ||N| /       Host Transport
           |   +-+         |               ||A|/        Address
           |   | |         |               v|T|     192.168.100.2:49582
           |   | |         |               /+-+
+---------+|   | |         |+---------+   /              +---------+
|         ||   |N|         ||         | //               |         |
| TURN    |v   | |         v| TURN    |/                 |         |
| Client  |----|A|----------| Server  |------------------|  Peer B |
|         |    | |^         |         |^                ^|         |
|         |    |T||         |         ||                ||         |
+---------+    | ||         +---------+|                |+---------+
               | ||                    |                |
               | ||                    |                |
               +-+|                    |                |
                  |                    |                |
                  |                    |                |
            Client’s                   |            Peer B
            Server-Reflexive    Relayed             Transport
            Transport Address   Transport Address   Address
            192.0.2.1:7000      192.0.2.15:50000     192.0.2.210:49191
```
在上图中，左边的TURN Client是位于NAT后面的一个客户端（内网地址是10.1.1.2:49721），连接公网的TURN服务器（默认端口3478）后， 服务器会得到一个Client的反射地址（Reflexive Transport Address, 即NAT分配的公网IP和端口)192.0.2.1:7000， 此时Client会通过TURN命令创建或管理ALLOCATION，allocation是服务器上的一个数据结构，包含了中继地址的信息。 服务器随后会给Client分配一个中继地址，即图中的192.0.2.15:50000，另外两个对等端若要通过TURN协议和Client进行通信， 可以直接往中继地址收发数据即可，TURN服务器会把发往指定中继地址的数据转发到对应的Client，这里是其反射地址。

Server上的每一个allocation都唯一对应一个client，并且只有一个中继地址，因此当数据包到达某个中继地址时，服务器总是知道应该将其转发到什么地方。 但值得一提的是，一个Client可能在同一时间在一个Server上会有多个allocation，这和上述规则是并不矛盾的。


通信过程：
![](http://7xj8b1.com1.z0.glb.clouddn.com/p2p_process.png)



参考：  
[P2P通信标准协议(二)之TURN](https://pannzh.github.io/tech/p2p/2015/12/16/p2p-standard-protocol-turn.html)  
[the-basic-p2p-communication-process](https://github.com/YK-Unit/AppRTCDemo/blob/master/README.md#the-basic-p2p-communication-process)
