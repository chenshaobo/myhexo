title: linux下写swift
date: 2015-12-10 10:42:07
tags: [Swift]
---
swift 终于开源了，赶紧用linux尝尝鲜。
目前swift支持的linux版本有 ubuntu15.10 和ubuntu 14.04.下面我会用Ubuntu14.04.1来尝尝鲜。


安装
=====
具体的手动安装教程可以在swift的[github仓库](https://github.com/apple/swift)查看.

当然，苹果也提供的ubuntu的swift安装包，如果不想折腾就直接下载安装吧：
- 使用`wget`获取安装包：`wget https://swift.org/builds/ubuntu1404/swift-2.2-SNAPSHOT-2015-12-01-b/swift-2.2-SNAPSHOT-2015-12-01-b-ubuntu14.04.tar.gz`

-解压：`tar -zxvf swift-2.2-SNAPSHOT-2015-12-01-b-ubuntu14.04.tar.gz`

-添加swift路径到PATH变量： `export PATH=/path/to/swift-2.2-SNAPSHOT-2015-12-01-b-ubuntu14.04/usr/bin/:"${PATH}"`

-确保所有的swift依赖包都安装了：1. apt-get update  2. sudo apt-get install git cmake ninja-build clang uuid-dev libicu-dev icu-devtools libbsd-dev libedit-dev libxml2-dev libsqlite3-dev swig libpython-dev libncurses5-dev pkg-config

安装完后输入`swift --version`会出现版本信息时，那么恭喜你安装成功了，赶紧用swift 去coding一些有趣的东西吧。
```swift
root@localhost:/mnt/hgfs/workspace# swift --version
Swift version 2.2-dev (LLVM 46be9ff861, Clang 4deb154edc, Swift 778f82939c)
Target: x86_64-unknown-linux-gnu
```


REPL
=====
swift 提供了一个终端 REPL(read eval print loop) 进行交互
```swift

root@localhost:/mnt/hgfs/workspace/mpreader# swift
Welcome to Swift version 2.2-dev (LLVM 46be9ff861, Clang 4deb154edc, Swift 778f82939c). Type :help for assistance.
 1>  
 2>  
 16> let sum = 100
sum: Int = 100
17> if sum > 10 { print("\(sum) bigger than 10")}
44 bigger than 10
 18> if sum > 10 { 
 19.     print("\(sum) bigger than 10") 
 20.  
 21. } 
44 bigger than 10
```
退出REPL的命令是`:q`

编译swift文件
=====
`root@localhost:/mnt/hgfs/workspace# vim testSwift.swift`
```swift
import Foundation
import Glibc


let player = ["rock", "paper", "scissors", "lizard", "spock"]

srandom(UInt32(NSDate().timeIntervalSince1970))
for count in 1...3 {
    print(count)
    sleep(1)
}

print(player[random() % player.count]);
```

执行 `swift testSwift.swift` 就会执行testSwift.swift文件的内容。
```shell
root@localhost:/mnt/hgfs/workspace# swift main.swift 
1
2
3
rock
```

构建swift程序包
======
swift同时开源了包管理项目，一个swift bao的文件组成如下 ：
```
example-package-playingcard 
├── Sources │ 
    ├── PlayingCard.swift │ 
    ├── Rank.swift 
    │ └── Suit.swift 
└── Package.swift
```
由源代码文件在`source`目录下，和 `manifest file` 文件Package.swift组成，`Package.swift`就是定义一个package类的实例，用于表述包的基本信息和其依赖的包：
```swift
import PackageDescription 
let package = Package( name: "DeckOfPlayingCards", targets: [], dependencies: [ .Package(url: "https://github.com/apple/example-package-fisheryates.git", majorVersion: 1), .Package(url: "https://github.com/apple/example-package-playingcard.git", majorVersion: 1), ] )
```
通过`swift build` 就会编译并且生成包的执行文件 ：`./.build/debug/packagename`
