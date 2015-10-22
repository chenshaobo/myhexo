title: Erlang发送邮件相关问题
date: 2015-10-22 18:22:11
tags: [Erlang]
---
Erlang 发送邮件相关问题
====

1. 协议相关
=====
一封邮件的发送的协议格式如下：

	"HELO XXX\r\n"
	"AUTH LOGIN \r\r"
	"$Account\r\n" ($Account为账号需要经过base64 encoding）
	"$Password\r\n" ($Password 为密码需要经过base64 encoding)
	"DATA\r\n"
	"From: < $Account> \r\n" ($Account 为发送者的email
	"To : < $ToEmails >\r\n" ($ToEmails 为发送者的列表）
	"Subject: =?UTF-8?B? $Tittle ?=\r\n"($Tittle 是邮件标题经过base64 编码后的字符串，这样做的目的是为了避免中文乱码）
	"MIME-version: 1.0\r\n"
	"Content-Type:text/html;charset=UTF-8\r\n\r\n"
	"$DATA\r\n\r\n" (正文内容）
	"\r\n.\r\n"(结束）
	"QUIT\r\n"(退出）

2.乱码问题
=====
Erlang 处理中文，唯一办法就是转换成utf-8 ,所以在smtp协议里面就需要指明对应的编码，所以标题需要改为`"Subject: =?UTF-8?B? $Tittle ?=\r\n"($Tittle 是邮件标题经过base64编码后的字符串，这样做的目的是为了避免中文乱码)` , 正文部分需要指明charset ：`"Content-Type:text/html;charset=UTF-8\r\n\r\n"`

3. 相关资料
======
- http://wdicc.com/sendmail-use-perl/
- http://www.cnblogs.com/quitboy/p/4605694.html
- http://www.chinaemail.com.cn/blog/content/667/
