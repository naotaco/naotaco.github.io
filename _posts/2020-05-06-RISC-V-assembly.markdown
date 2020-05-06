---
layout: post
title: RISC-VアセンブリでLチカする
date: 2020-05-06 22:03:26 +09:00
categories: Embedded RISC-V
---

急にRISC-Vに興味が出てきたので（RISC-V原典を積んだのはもうだいぶ前だが……）、RISC-VのCPUを使ったボードであるHiFive1 Rev.Bを買った。

当然立派なIDEやSDKがあるので、普通にC++で書いたコードを動かすことができる。しかしC++を使っているだけではRISC-Vを使っているという満足感が得られないので、とりあえずベアメタルでアセンブリを書くことにした。

必要なものは次の通り:

* RISC-V向けGNU toolchain
* [JLink Software](https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack)
* Ubuntuマシン
** 多分なんでもできるけど、一番リスクが低そうなのでUbuntuで試した。

## toolchainの調達

参考にしたページたちによると、32bitむけツールチェーン（ `riscv32-unknown-elf-xx` ）を使うよう記載がある。しかし[公式](https://www.sifive.com/boards)からダウンロードできるのは64/32bit両サポートとなった64bitっぽい名前のものである。これでもHiFive1 Rev.B向けのコンパイルはできるようなのだが（Freedom E SDKは実際にこれを使って動いていた）、使う前に何らかの設定をしなくてはいけないらしくさっぱりわからない。

単にこのコンパイラに `-march=rv32imac -mabi=ilp32` とするとエラーが出るので、何らか設定の方法があるのだとは思うが面倒なので諦めた。仕方ないので自分でビルドする。

riscv-gnu-toolchain: https://github.com/riscv/riscv-gnu-toolchain

これをcloneしてきて、READMEに書いてある通りにビルドすると動いた。但しコンパイル時に使いたいアーキテクチャを指定する必要がある。またmasterだとうまくコンパイルできなかった。

{% highlight bash %}
sudo apt install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
git clone git@github.com:riscv/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git checkout v20180629
./configure --with-arch=rv32imac --with-abi=ilp32 --prefix=/some/where
make -j8 #=> riscv32-unknown-elf-as など
{% endhighlight %}

できたtoolchainのas, ld, objcopy等を使う。

## JLink software

落としてきてインストールする。Ubuntuの場合はdebパッケージをインストールするだけ。

これでflashできるのと、デバッガを接続できるようになる。デバッガは常時有効になっているようなので、今回書いた簡素なコードでも動かせばレジスタの情報を見ることができる。

## コード












