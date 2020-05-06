---
layout: post
title: RISC-VアセンブリでLチカする
date: 2020-05-06 22:03:26 +09:00
categories: Embedded RISC-V Assembly
---

急にRISC-Vに興味が出てきたので（RISC-V原典を積んだのはもうだいぶ前だが……）、RISC-VのCPUを使ったボードであるHiFive1 Rev.Bを買った。

当然立派なIDEやSDKがあるので、普通にC++で書いたコードを動かすことができる。しかしC++を使っているだけではRISC-Vを使っているという満足感が得られないので、とりあえずベアメタルでアセンブリを書くことにした。

必要なものは次の通り:

* RISC-V向けGNU toolchain
* [JLink Software](https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack)
* Ubuntuマシン
** 多分なんでもできるけど、一番リスクが低そうなのでUbuntuで試した。

## toolchainの調達

参考にしたページたち（後述）によると、32bitむけツールチェーン（ `riscv32-unknown-elf-xx` ）を使うよう記載がある。しかし[公式](https://www.sifive.com/boards)からダウンロードできるのは64/32bit両サポートとなった64bitっぽい名前のものである。これでもHiFive1 Rev.B向けのコンパイルはできるようなのだが（Freedom E SDKは実際にこれを使って動いていた）、使う前に何らかの設定をしなくてはいけないらしくさっぱりわからない。

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

正直ここに一番時間がかかった。

## JLink software

落としてきてインストールする。Ubuntuの場合はdebパッケージをインストールするだけ。

これでflashできるのと、デバッガを接続できるようになる。デバッガは常時有効になっているようなので、今回書いた簡素なコードでも動かせばレジスタの情報を見ることができる。

## コード

https://github.com/naotaco/hello-riscv-asm

アセンブリとリンカスクリプトとMakefileがあるだけ。

リンカスクリプト（ `linker.lds` ）はSDKのHiFive1 Rev.B向けのBSPから流用（Apache-2.0）。 `0x20010000` がFlashのアドレスらしい。ここに `_start` シンボルが置かれるようにしておけばよい。リンカスクリプトはかなり過剰なつくりな上に（gcc向け設定がたくさんある…）シンボルの配置もアレなので、シンプルにゼロから書いた方がいいような気がしてきたが……。

アセンブリはCのコードを参考に書いてみた。GPIOにRGBそれぞれのビットがあるので、それぞれ有効にして0を書き込むと白く光る。1を書くと消える。適当にループで待つ。このへんはRISC-V原典と首っ引きで書いたが、けっこう書きやすくてよかった。疑似命令も使いやすいし、x86みたいに意味不明なレジスタ名じゃないし。

あとzeroレジスタがあるのは便利でいいですね。性能のことはわからんが逆アセンブルしたあとの可読性のうえでも便利な気がする。コンパイラが使ってくれるのかは知らんが……。

```asm
.equ GPIO_BASE, 0x10012000
.equ GPIO_OFFSET_VALUE,     0x00
.equ GPIO_OFFSET_INPUT_EN,  0x04
.equ GPIO_OFFSET_OUTPUT_EN, 0x08
.equ GPIO_OFFSET_PORT,      0x0C
.equ GPIO_OFFSET_PUE,       0x10
.equ GPIO_OFFSET_OUT_XOR,   0x40

.equ USE_PORTS, (1 << 19) | (1 << 21) | (1 << 22)
.equ WAIT_COUNT, 2000000

.section .text
.globl _start
_start:
	lui sp, 0x80004

init_regs:
	li t3, GPIO_BASE # load immediate
	li t4, USE_PORTS # flags to write
	sw t4, GPIO_OFFSET_OUTPUT_EN(t3) # store word
	sw t4, GPIO_OFFSET_PORT(t3)
	sw zero, GPIO_OFFSET_OUT_XOR(t3)

loop:
	sw zero, GPIO_OFFSET_PORT(t3) # store zero (GPIO low) to light up.

	li t5, WAIT_COUNT
wait1:
	addi t5, t5, -1
	nop
	bnez t5, wait1 # go to wait1 if t5 != zero
	
	sw t4, GPIO_OFFSET_PORT(t3) # turn off

	li t5, WAIT_COUNT
wait2:
	addi t5, t5, -1
	nop
	bnez t5, wait2 # go to wait2 if t5 != zero
	
	j loop

.section .rodata
```

Makefileは、最低限のコンパイルオプション（ `arch`, `abi` ）とリンカスクリプトを指定して.Sファイルをコンパイルするよう書いた。いま気づいたが大文字で `.S` って拡張子にするのARMっぽくてアレだな。

jlink呼び出しのところは「みつきんのメモ」さんの記述を参考に。

デバッガ呼び出しのところはSDKのコードを流用だが、これもJlinkを呼んでいるだけ。QEMUならOpenOCDとかになるようだが、実機ならJLink一択。

## コンパイル・動作

`bin/riscv32-unknown-elf-xx` のある場所を `RISCV_PATH` に設定しておけば `make` と打てばビルドはできるはず。 `boot.elf`, `boot.hex` ができていればOK.

JLinkが使える状態でHiFive1 Rev.Bがつながっていれば、 `make flash` で起動バイナリを焼くことができる。

するとLEDが白く点滅する（はず）。

焼いた後は勝手に再起動するので、そのあと続けて `make debug` と打つと、作ったelfファイルとともにgdbが起動するはず。

`b` と打ってBreakして、 `info registers` と打つと、レジスタの様子がみられる。ARMと比べるとたくさんあっていいですねえ。

## まとめ

RISC-Vのアセンブリを書いて動かせる環境が準備できた。これでRISC-V原典を読みながら試すことができる。というかこれを試すためにけっこう読み進めてしまった。

例年であれば旅行に出ていたはずのGWだが、StayHomeにより進捗が生まれたという点で非常に喜ばしい。

## 参考

* https://github.com/dwelch67/sifive_samples/tree/master/hifive1b/blinker01
* http://mickey-happygolucky.hatenablog.com/entry/2019/11/05/165524





