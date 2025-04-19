---
title: I Learnt Rust Smart Pointers By Coding a Linked List
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1727798378/realm/tutorials/rust-smart-pointers/Screenshot_from_2024-10-01_17-59-22_yuy0kc.png
tags: ["Programming", "Rust", "DSA"]
description: I heard someone say that implementing a linked list in Rust is not for the faint of heart. I decided to try it, and here's what I learned.
publishDate: 2024-10-01
---

A few weeks ago, I wanted to quit Rust. I thought it was too hard. A lot has happened since then, including some very enlightening conversations with strangers on Mastodon. The result was that I thought I'd give it another go, and what better way to dive back in than taking on the bane of my first year C++ programming course - the [accursed linked list](https://rust-unofficial.github.io/too-many-lists/index.html#an-obligatory-public-service-announcement).

What you'll see here is that writing a linked list in Rust is not as easy as I recall from my Java class. However, it did teach me a lot, and got me thinking about things other languages don't need me to think about. And, that's exactly what I love about Rust (and C++) - they force me to think about the code.

With that in mind, let's code a linked list.

# Linked Lists

A linked list is a data structure that stores data in non-contiguous blocks of memory.

![linked list](https://res.cloudinary.com/ta1da-cloud/image/upload/v1727798378/realm/tutorials/rust-smart-pointers/Screenshot_from_2024-10-01_17-59-22_yuy0kc.png)

A node in a linked list contains data, and a pointer to the next item (or both next and previous, in the case of a doubly linked list). The biggest advantage of linked lists is that adding to and removing items from the ends is very fast if we've got the pointers stored somewhere.

```rust
struct List<T> {
	head: Node<T>,
	tail: Node<T>
}
```

With arrays, on the other hand, the data is stored on contiguous blocks of memory, which means that the whole structure must be moved when we want to add data. The worst case would be trying to add an element close to the beginning of the array, where we would have to copy over all the subsequent elements.

![array](https://res.cloudinary.com/ta1da-cloud/image/upload/v1727797856/realm/tutorials/rust-smart-pointers/Screenshot_from_2024-10-01_17-39-25_rlx1gp.png)

The biggest downside is accessing elements. Unlike arrays, we can't simply access an item by an index because they're not stored contiguously. Instead, we have to traverse the whole list from the head (or tail), following each pointer until we find what we are looking for. In many cases, this negates any benefits we would have had when splitting or merging a linked list. The resulting worst case time complexity is O(n).

# The First Hiccup

With the basics out of the way, I started working on my implementation and immediately ran into the first problem. To understand the problem, we must first understand the difference between heap and stack memory.

## Where is the data stored?

When we create variables, they must be stored somewhere in memory. This memory can either be allocated on a stack or heap. Generally, primitive data types and structs containing only primitive types are stored on the stack. These are static and their size is known at compile time. However, if the size of what we want to store can only be known at runtime, then we want our memory to be dynamically allocated.

Some important things to understand about the stack:

1. Storage is temporary and the data is cleared as soon as the method that owns the data finishes its execution.
2. Stack memory is static. The size of data stored here must be known by the compiler.
3. Allocation and de-allocation are automatic.
4. Data access is fast because of the _last in, first out_ behaviour, so there's never need to search for a place to put data.

The heap, on the other hand:

1. Control is given to the programmer to allocate and de-allocate memory. This makes it less safe than the stack because it demands that the programmer must pay close attention to how they manage their memory.
2. It is dynamic and flexible, allowing the allocated memory to grow. This allows us to store data whose size is unknown by the compiler.

Part of how Rust ensures memory safety is by ensuring that the sizes of types are known at compile time. Otherwise, the developer must make a conscious decision to use dynamic memory allocation. This is what we need to do because we want our linked list to hold data whose type is generic and hence, unknown at compile time.

```rust
struct Node<T> {
  data: T,
  next: Node<T>
}
```

Writing this gives us this error

```shell
recursive type `Node` has infinite size

main.rs(4, 8): recursive without indirection

main.rs(4, 8): insert some indirection (e.g., a `Box`, `Rc`, or `&`) to break the cycle: `Box<`, `>`
```

That's just the Rust compiler complaining about the type of data being unknown at compile time. Our recursive data type lacks indirection i.e. a known size at compile time. Essentially, we end up with an infinite loop and never reach a point where the size of `T` is known.

## Smart Pointers

We saw earlier what pointers are. According to **The Book**, smart pointers are:

> **pointers with additional metadata and features**

Since the size (and type) of the data in each node is unknown, we want to store it on the heap instead of the stack. Then, on the stack, we store a pointer to the actual data. We can do this using the `Box` smart pointer.

```rust
struct Node<T> {
	data: T,
	next: Box<Node<T>>
}
```

This makes the Rust compiler happy... for now.

# The Second Hiccup

The second issue is that Rust lacks a null type (fortunately). As we have seen, a node might have a next node, or it might not. We want it to be _optional_.

This situation is handled by using the `Option` enum. It has two variants: `Some`, which represents the presence of a value in the form of a tuple wrapping a value of _generic type_, `T`, and `None`, which represents the absence of a value.

```rust
struct Node<T> {
	data: T,
	next: Option<Box<Node<T>>>
}
```

This is enough for a singly-linked list. It's not the prettiest looking code and, a year ago, this was gibberish to me. If you're not already familiar with Rust, I can't imagine you just looking at this code and knowing exactly what it does.

The full singly-linked list code looks like this:

```rust
#[derive(Debug)]
struct Node<T> {
	data: T,
	next: Option<Box<Node<T>>>
}

impl<T> Node<T> {
    // implement a function to set the next node
    fn set_next(&mut self, next: Node<T>) {
        self.next = Some(Box::new(next));
    }
}

fn main() {
    // create a head node
    let mut head = Node {
        data: 3,
        next: None
    };

    // create a next node
    let mut next = Node {
        data: 7,
        next: None
    };

    // set the next node
    head.set_next(next);

    println!("head: {:#?}", head);
}
```

I'd say we're done here, but a singly-linked list is low-hanging fruit. At least, that's what my Java professor used to say. With that in mind, let's proceed.

# The Third Hiccup

The main difference between a singly-linked list and a doubly-linked list is the presence of an extra pointer which will point to the previous node.

```rust
struct Node<T> {
	data: T,
	next: Option<Box<Node<T>>>,
	prev: Option<Box<Node<T>>>
}
```

But, apparently, this is a big no-no because of Rust's ownership model: _a value can only have one owner at any given time_. Our `Node` structure potentially creates a situation where a value may have multiple owners, thus violating that rule.

![doubly-linked list](https://res.cloudinary.com/ta1da-cloud/image/upload/v1727798311/realm/tutorials/rust-smart-pointers/Screenshot_from_2024-10-01_17-58-00_gzmlub.png)

We also create a cycle of ownership where, for example, Node A owns Node B via `next` and Node B owns Node A via `prev`. This prevents the Rust compiler from knowing when to deallocate the memory, which could result in memory leaks.

Fortunately, Rust gives us a way to get around this rule using the `Rc<T>` (reference counting) smart pointer. It allows us to keep track of the number of references to a value. That way, when the last reference is dropped, the compiler can deallocate the memory.

```rust
struct Node<T> {
	data: T,
	next: Option<Rc<Node<T>>>,
    prev: Option<Rc<Node<T>>>
}
```

## Implications

This solution brings up some nuances about Rust's memory management and ownership model. Using the `Rc<T>` smart pointer here allows multiple ownership of the same data by keeping track of the number of references to the value. However, while it is valid, it does present some possible issues:

- _Performance_: `Rc<T>` has a slight performance overhead
- _Reference cycles_: if not managed correctly, using `Rc<T>` for both `next` and `prev` can result in reference cycles and lead to memory leaks.

To prevent reference cycles, we would need to make sure that we manually break these cycles when removing nodes:

```rust
impl<T> Drop for Node<T> {
    fn drop(&mut self) {
        // break cycles when the node is dropped
        self.next = None;
        self.prev = None;
    }
}
```

Alternatively, we can use `Weak<T>` for the `prev` pointer, which hold a _"non-owning reference to the managed allocation"_. That means it does not count towards ownership and also does not prevent the value from being dropped.

```rust
struct Node<T> {
	data: T,
	next: Option<Rc<Node<T>>>,
    prev: Option<Weak<Node<T>>>
}
```

# The Last Hiccup

We replaced the `Box` smart pointer with `Rc`, and this solved most but not all of our problems. The last issue we have to deal with is because of another one of Rust's rules of ownership: _at any given time, we can either have one mutable reference, or any number of immutable references_ - but not both at the same time. This makes sense because the last thing we want is to have data changing while it is being referenced by something else.

Again, Rust provides a way to _break_ this rule using the `RefCell<T>` smart pointer. It works by allowing us to enforce the rules of borrowing at runtime instead of compile time. We can keep track of how many immutable and mutable borrows we have. The code will still compile where it wouldn't have because, even though we are breaking the rules, it can only panic at runtime.

This is important for a doubly-linked list because we will need to be able to mutate a node through its `prev` and `next` pointers.

```rust
struct Node<T> {
	data: T,
    // works but not a good idea
	next: Option<Rc<RefCell<Node<T>>>>,
    prev: Option<Rc<RefCell<Node<T>>>>
}
```

This works perfectly fine but, as we have already seen, there's no such thing as free lunch. Using this combination `Rc<RefCell<T>>` adds complexity and comes with the risk of runtime panics if not managed correctly. It works, but it's not advisable.

> For more on that, check out chapter 5 of `Learning Rust With Entirely Too Many Linked Lists`: https://rust-unofficial.github.io/too-many-lists/fourth.html

# Conclusion

I hope this will help you understand this topic as it that took me a while to fully wrap my head around. We didn't even cover all the Rust smart pointers - for example, if we wanted to add thread-safety, we could replace `Rc<T>` with `Arc<T>` (atomic reference counting). If you enjoyed this, disagree, or would like to correct me about anything here, I can be found on [Mastodon](hachyderm.io/@ta1da).
