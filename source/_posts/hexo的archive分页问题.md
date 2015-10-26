title: hexo的archive分页问题
date: 2015-10-27 02:37:11
tags: [hexo]
---
在配置hexo的过程中，希望的效果是首页的文章分页，然后 archives和tags的文章不分页。
开始以为是主题的代码实现bug，蒙头去改。后来才发现是配置问题，在hexo的[issue](https://github.com/hexojs/hexo/issues/1553)里面也有这样的记录.
本人的hexo版本是 3.0 ，步骤如下：
1.安装 hexo-generator-archive： `npm hexo-generator-archive --save`
2.配置`_config.yml`，修改：

```shell
# Pagination
## Set per_page to 0 to disable pagination
per_page: 6
pagination_dir: page
archive_generator:
  yearly: true
  monthly: true
  per_page: 0
category_generator:
  per_page: 0
tag_generator:
  per_page: 0
```


