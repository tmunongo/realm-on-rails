---
title: Systems Programming Languages are in a Weird Place Right Now
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1734763339/realm/covers/library_mfqmlr.jpg
tags: ["Programming", "Rust", "Zig", "Go", "C++"]
description: Some thoughts about my struggle picking and sticking to a system's programming language
publishDate: 2025-04-05
---

So, systems programming is in a weird place right now.
At least, in terms of the languages used.
It's been known for a while, now, that memory safety is the leading cause of bugs in computer software. At the root of this issue are the non-memory-safe languages, of which C and C++ are the most widely used.
That last part is important because, they are the most widely used systems programming languages at the moment. There have been efforts, for example, to start porting over parts of the Linux kernel to more memory safe languages (more on that later), but it's been the source of a lot of fighting within that community as some people just do not want to make that transition, especially given the available options.
Options are the biggest issue here because, at the moment, the most well-known and widely adopted, memory-safe, systems-level programming language is Rust. Now, I have had my fair share of issues with Rust, mostly because its memory-safety comes at quite a steep cost. And, for many people, giving up the simplicity of C - a language that's so simple and bare bones that everything it does can almost directly be mapped to Assembly - is just too much of an ask, especially when the alternative is Rust.
This is a community that has been rejecting C++ for decades as many of them see it as an abomination, an overly bloated and complex successor to the simplicity of C. And, things have only gotten worse in the last few years as C++ has tried to "modernise". In fact, there are ongoing efforts right now to introduce some kind of memory safety into C++, but it may both be too little too late, and too far for those who are resistant to change, do not like Rust, and do not wish to see every language become Rust.

The biggest question is whether or not there's actually space for non-memory safe languages in systems programming. The benefits are obvious - at least for the most obvious memory safety bugs (null pointer, use after free, etc.), Rust is the solution (or any other memory safe language). But, is there a way to achieve the same memory safety guarantees without the pain points of having to appease the borrow checker?

Which brings me to where I started - learning a system's level programming language is a bit weird right now.

It's way too soon to say C is on it's way out. Yet, starting to learn it now feels just a little bit too late. C++ is in a weird state of trying too hard to be "modern", in the process alienating some of its most loyal users. I tried Zig and while I did enjoy the simplicity, it's still a long way from stability, and it's not entirely memory safe.

Does that leave Rust as the only option? It really feels like it at this point. Every other language falls into one of three categories:

- **memory-unsafe** and at risk of becoming antiquated at some point in the near future. After all, the US government is already pushing for it.
- too new and niche. This is a problem because:
- 1. most new programming languages just don't make it out of infancy
- 2. instability makes them difficult to learn and barely usable in anything outside personal, side projects
- **memory-safe** and is Rust.
