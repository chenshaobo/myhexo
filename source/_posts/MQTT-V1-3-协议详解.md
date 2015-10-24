title: MQTT_V1.3_协议详解
date: 2015-10-24 14:34:53
tags: [mqtt]
---
MQTT 协议详解
====

预览
====
    %%        7   6   5   4      3     2   1      0
    byte1     message_type   dupflag   QoSLV   RETAIN
    byte2     Remaining Length
    byte3      Variable header
    byten       ....
                    MSG

Fixed header（固定头部）
====
    %%        7   6   5   4      3     2   1      0
    byte1     message_type   dupflag   QoSLV   RETAIN
    byte2     Remaining Length

* message_type:消息类型，第4-7位比特，不同的值表示不同的意思，具体如下：
    1. 1 ：CONNECT,客户端请求连接服务器	       
    2. 2 : CONNACK,连接应答
    3. 3 ：PUBLISH ,发布一条消息      	
    4. 4 :  PUBACK, 发布应答        	
    5. 5 :  PUBREC, 发布被接收应答发布1        	
    6. 6 ：PUBREL ，发布释放应答发布2        	
    7. 7 : PUBCOMP,发布完成应答发布3        	
    8. 8 ：SUBSCRIBE,请求订阅        	
    9. 9 ：SUBACK,订阅应答        	
    10. 10 ：UNSUBSCRIBE ,取消订阅
    11. 11 ：unsuback,取消订阅应答
    12. 12 ：PINGREQ ,ping请求
    13. 13 ：PINGRESP,ping回应
    14. 14 ：DISCONNECT,客户端断开连接
    15. 15 ：保留

* DUP:用于标识是否是重发的发布，发布应答，订阅，取消订阅的消息，当QoS大于0，且设置必须应答时。
* QoS:消息的发送保证级别；0：至多一次，1：至少1次 ；2：只有一次 3：保留
* RETAIN：对发布消息有用，为1时标识发布的消息对新订阅的用户有用，且需要持久化，
* Remaining Length:低7位为消息的字节数量，第8位为下一个字节也是长度标志位，最大为四个字节。


Variable Header(可变头部)
====
某些MQTT的命令会包含一个可变的头部组件，它位于 固定头部（fixed header)和负载之间。
Protocol name(协议名称）
====
协议名出现在一条MQTT 连接消息的可变头部中，这个字段是UTF编码，比如 MQIsdp 或MQTT

Protocol version（协议版本）
====
协议版本字段出先在一条MQTT连接消息的可变头部中，占用一个字节。

Connect flag（连接标识）
====
Clean_session,WILL,Will QoS,Retain flags 出现在CONNECT 消息的可变头部。

Clean session flag
====
位置：在connect flag字节的 第1位（从0位开始），如果该位不置1则服务器需要持久化该客户端的订阅消息，以便下一次连接后继续使用。如果置1，则客户端断开后清空订阅信息，每次连接都需要重新订阅信息。

Will QoS、Will flag 、Will Message
====
位置：在connect flag 字节的第3 和第4位
這三個flag，就是在MQTT簡介裡被提到的 最後遺囑(Last Will and Testament) 機制所用的flag。這機制是這樣的，client在一開始發送CONNECT訊息給server要求建立連線時，就把要對哪個主題說什麼遺言一起傳給server，當它在不正常的情況下斷線時(比如說網路連線斷掉、裝置故障等等)，則這些訊息就會被server主動發佈到該主題上。如果是client主動發送DISCONNECT訊息給server要求斷線時，則此機制將不會有作用。

要啟動此機制，首先就是要將Will flag設為1，這樣就代表要啟用，之後你設定遺言的QoS level為何，server會依照你設定的QoS level來幫你傳送訊息，最後設定此此則遺言是否要保留(Retain)在server上。如果有設定Will flag，則在pyaload內會需要定義Will Topic和Will Message，也就是要對哪個主題發送什麼樣的遺言。

User name 和 password 标识
====
位置：在connect flag 字节的第6和第7位
客户端在连接时指明是否包含了登陆名称和登陆密码。

Keep Alive timer（存活定时器）
====
keep alive timer 出现在一个CONNECT消息的可变头部，定义了从客户端接受消息的最大间隔时间（秒），可用于服务端心跳包机制来判断与客户端的网络连接是否已经断开。keep alive timer 字段大小为两个字节，0表示客户端用于不会断开。

Connect return code 返回码
====
connect return code出现 在CONNACK 消息中，大小为一个字节，当前有意义的值是：
- 0x00 : 接受连接
- 0x01:  拒绝连接，协议版本不可用
- 0x02:  连接失败，标识拒绝
- 0x03:  服务器连接失败
- 0x04:  用户名和密码错误
- 0x05:  没有验证

Topic name (订阅名称）
====
topic name 出现在MQTT PUBLISH 消息的可变头部，用来标明发布消息所属的channel，订阅时使用该值来标明从哪里接收发布消息。

