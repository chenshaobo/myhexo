title: tsung压测restful服务器
date: 2015-11-06 16:18:20
tags: [Erlang,Tsung,压测]
---

1. android 手机一部
2. tsung 环境

思路：使用tsung的recorder功能 先记录下app的请求内容(这个可以通过 让手机代理到tsung机器的指定端口），然后让tsung使用recorder记录下来的xml文件无脑进行回放，以达到测试服务性压力。




1.tsung启动监听代理
======
执行`tsung-recorder -p http -L 8080 start`,这样就会直接进行代理，并记录通过8080端口的协议内容，然后就可以在app上面点击功能让app向服务器请求内容。


2.编辑tsung.xml配置
======
第一步生成的recorder 的xml文件默认在`~/.tsung/tsung_recorder_date.xml`,内容格式大概如下：

     
```xml
<session name='rec20151106-1447' probability='100'  type='ts_http' bidi="true">
<request><http url='http://172.16.2.106:80/api/v1/bookclubserver/mp/get' version='1.1'  contents='{"user_id":"144447713885360800","page_size":"10","filter_goods_id_set":[],"filter_user_type_set":[],"p_version":"1","page_index":"0"}' content_type='application/json' method='POST'><add_cookie key="ifm_sid" value="0521be8ac72fcf353dc38db77049ce2f"/></http></request>

<thinktime random='true' value='1'/>

<request><http url='http://172.16.2.103/data/app_user/upload/144447713885360800/logo_144447713885360800_logo.png' version='1.1' method='GET'><add_cookie key="ifm_sid" value="0521be8ac72fcf353dc38db77049ce2f"/></http></request>
<request><http url='/data/app_user/upload/144447713885360800/logo_144447713885360800_logo.png' version='1.1' method='GET'><add_cookie key="ifm_sid" value="0521be8ac72fcf353dc38db77049ce2f"/></http></request>

<thinktime random='true' value='3'/>

<request><http url='http://172.16.2.106:80/api/personalserver/personalinfo/get' version='1.1'  contents='{"user_id":"144447713885360800","p_version":"1"}' content_type='application/json' method='POST'><add_cookie key="ifm_sid" value="0521be8ac72fcf353dc38db77049ce2f"/></http></request>
<request><http url='http://172.16.2.103/data/app_user/upload/144447713885360800/logo_144447713885360800_logo.png' version='1.1' method='GET'><add_cookie key="ifm_sid" value="0521be8ac72fcf353dc38db77049ce2f"/></http></request>
<request><http url='http://172.16.2.106:80/api/bookclubserver/bookreader/fprint/get' version='1.1'  contents='{"user_id":"144447713885360800","p_version":"1","page_size":"120","page_index":"0"}' content_type='application/json' method='POST'><add_cookie key="ifm_sid" value="0521be8ac72fcf353dc38db77049ce2f"/></http></request>

<thinktime random='true' value='2'/>
....
</session>
```
   编辑好的tsung.xml如下，可以按照[tsung文档](http://tsung.erlang-projects.org/user_manual/configuration.html)的来配置，其实觉得挺复杂的。。：
```xml
 <?xml version="1.0"?>
<!DOCTYPE tsung SYSTEM "/usr/local/share/tsung/tsung-1.0.dtd"[ <!ENTITY mysession1 SYSTEM "/root/.tsung/tsung_recorder20151106-1447.xml">
]>
<tsung loglevel="notice" version="1.0">
  <!-- Client side setup -->
  <clients>
    <client host="localhost" use_controller_vm="true" maxusers="30000"/>
  </clients>
 
  <!-- Server side setup -->
<servers>
 <server host="localhost" port="8080"  type="tcp"></server>
</servers>
  <!-- to start os monitoring (cpu, network, memory). Use an erlang
  agent on the remote machine or SNMP. erlang is the default -->
  <monitoring>
    <monitor host="myserver" type="snmp"></monitor>
  </monitoring>
 
  <load>
  <!-- several arrival phases can be set: for each phase, you can set
  the mean inter-arrival time between new clients and the phase
  duration -->
   <arrivalphase phase="1" duration="10" unit="minute">
     <users interarrival="2" unit="second"></users>
   </arrivalphase>
  </load>
  <options>
   <option type="ts_http" name="user_agent">
    <user_agent probability="80">Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) Gecko/20050513 Galeon/1.3.21</user_agent>
    <user_agent probability="20">Mozilla/5.0 (Windows; U; Windows NT 5.2; fr-FR; rv:1.7.8) Gecko/20050511 Firefox/1.0.4</user_agent>
   </option>
  </options>
  <!-- start a session for a http user. the probability is the
  frequency of this type os session. The sum of all session's
  probabilities must be 100 -->
 <sessions>
 &mysession1;
 </sessions>
</tsung>

```


3.进行压测
======
执行`tsung start`就可以开始进行压测了

4.生成report
======
最后cd到`~/.tsung/log/data/`里面执行执行 `tsung_stats.pl`   生成` report.html`
