---
layout: post
title: RISC-VアセンブリでLチカする
date: 2020-05-06 22:03:26 +09:00
categories: Embedded RISC-V
---

急にRISC-Vに興味が出てきたので（RISC-V原典を積んだのはもうだいぶ前だが……）、RISC-VのCPUを使ったボードであるHiFive1 Rev.Bを買った。

立派なIDEやSDKがあるので、普通にC++で書いたコードを動かすことができる。しかしC++を使っているだけではRISC-Vを使っているという満足感が得られないので、とりあえずベアメタルでアセンブリを書くことにした。

追記

