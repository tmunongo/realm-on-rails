---
title: A Brief Exploration of Traits and Lifetimes in Rust
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1734763339/realm/covers/library_mfqmlr.jpg
tags: ["Programming", "Rust"]
description: In this post, I'll show how traits and lifetimes serve similar purposes to concepts like interfaces in OOP, but with some important differences.
publishDate: 2024-12-21
updated: 2024-12-21
---

As I mentioned in my previous post, taking some time to play with `C++` opened my eyes to the reasoning behind various design choices in `Rust`. The experience left me with a clearer view of what problems Rust aims to solve. In this post, I'll explore one of these concepts, showing how _traits_ and _lifetimes_ serve similar purposes to concepts like _interfaces_ in OOP, but with some important differences.

# Project Overview

We are going to explore these important Rust concepts through the lens of a **Time Traveller's Library** application. As you may already know, a lot of humanity's written knowledge has been lost over the ages. Our application does exactly what the name suggests - it allows a time traveller to check out any book throughout history. However, there's one caveat - a book can only be checked out during the time period in which it existed. For example, a text that was destroyed during The Great Fire that ravaged the Library of Alexandria cannot be checked out today, or can a book be checked out before it was authored.

Check out the [GitHub](https://github.com/tmunongo/library-in-time) repo for the full code.

# Generics and Traits

In many libraries, not every book can be checked out. Some books have this _trait_ of being _borrowable_, while others do not. All books, however, exist across time and thus have a _temporal_ _trait_.

My first instinct when I read [Chapter 10](https://doc.rust-lang.org/book/ch10-00-generics.html) of **The Book** was that `trait`s sounded awfully like `interfaces`. There are some similarities, but the devil is in the details, and those details make a difference.

A **trait** is a behaviour. They are deeply intertwined with [_generics_](https://doc.rust-lang.org/book/ch10-01-syntax.html), allowing us to place bounds on what types a generic function can accept.

For example:

```rust
struct GenericTimeLibrary<T> {
	texts: Vec<T>,
}

struct Book {
    title: String,
    author: String
}

struct Scroll {
    title: String,
    author: String
}
```

The `GenericTimeLibrary` struct takes a _generic_ parameter, `T`. This `T` can be anything - we've not put any constraints on what it can be. That means the _texts_ field of the `GenericTimeLibrary` will accept any type.

This code will compile.

```rust
let mut library = GenericTimeLibrary{
	texts: Vec::new()
};

let book = Book{
	title: String::from("The Hitchhiker's Guide to the Galaxy"),
	author: String::from("Douglas Adams")
};

library.texts.push(book);

println!("Number of texts in library: {}", library.texts.len());
```

But, so will this:

```rust
// create library

let hello = String::from("Hello, Rust!");

library.texts.push(hello);

println!("Number of texts in library: {}", library.texts.len());
```

```shell
% cargo run
Number of texts in library: 1
```

I don't know about you, but I wouldn't want to visit a library filled with strings or integers.

Instead, we only want to accept _valid_ texts. These could be `Book`s, `Scroll`s, etc. We need to tell the compiler to only accept these structures by defining a shared behaviour for them.

> It's like [duck typing](https://en.wikipedia.org/wiki/Duck_typing), i.e. "if it walks like a duck and quacks like a duck...". Their behaviour defines what they are.

We could say, for example, that any valid text in this library should have a title and an author. This will allow the librarian to catalogue them. We specify this to the compiler by creating a trait, `WasAuthored`. This trait will specify a set of methods which any[1][1] struct can implement and acquire that behaviour.

```rust
trait WasAuthored {
    fn get_title(&self) -> String;
    fn get_author(&self) -> String;
}
```

Then, we modify the `GenericTimeLibrary` struct with a _trait bound_:

```rust
struct GenericTimeLibrary<T: WasAuthored> {
	texts: Vec<T>,
}
```

At this point, `rustanalyzer` should immediately point out an error where we tried to push a `String` into the `GenericTimeLibrary`:

```text
the trait bound `String: WasAuthored` is not satisfied
the trait `WasAuthored` is not implemented for `String`
```

This tells is that `String` does not satisfy the given _trait bound_. But, at the moment, neither does `Book`. We need to implement `WasAuthored` for book:

```rust
impl WasAuthored for Book {

}
```

At this point, we get a little help from the compiler. This _trait_ requires that we implement our predefined methods for the struct.

```text
not all trait items implemented, missing: `fn get_title`, `fn get_author`rust-analyzerE0046
```

After updating the implementation:

```rust
impl WasAuthored for Book {
    fn get_author(&self) -> String {
        format!("Author: {}", self.author)
    }

    fn get_title(&self) -> String {
        format!("Title: {}", self.title)
    }
}
```

we can add `Book`s to the library.

At this point, however, we run into a problem with the other _authored_ type: `Scroll` when we try to push one into the library:

```text
mismatched types
expected `Book`, found `Scroll`
```

`Rust`s type system enforces that all items in the `Vec` must have the same type. Since we instantiated the library with a `Vec<Book>`, it cannot later accept a scroll, even if both implement the `WasAuthored` trait.

Instead, we have to use a _trait object_ instead of the generic type. A trait object will allow us to achieve _dynamic dispatch_, enabling _polymorphism_. This will allow us to work with types that implement the `WasAuthored` trait, even if the compiler cannot know their type at compile time. And, since the type is not known at compile time, we must `Box` it so that our data is stored on the _heap_.

```rust
struct GenericTimeLibrary {
    texts: Vec<Box<dyn WasAuthored>>,
}
```

Of course, that means we lose access to the specific type information of our objects, and must now use `Box` whenever we push into the library:

```rust
let scroll = Scroll{
	title: String::from("Dead Sea Parchment A"),
	author: String::from("Ancient Person")
};

library.texts.push(Box::new(scroll));
```

Now, we have a generic struct with the ability to restrict what kind of data it can accept.

# Lifetimes

You may have noticed that, in the `Book` and `Scroll` structs, the _author_ and _title_ structs are owned strings. It's not always possible, or efficient, to have our structs own all their fields. Sometimes, we can only have a reference to them:

```rust
struct Book {
	title: String,
	author: &str,
}
```

In the above case, the `Book` author is a string reference. The compiler will immediately tell us, after making this change, that this can lead to problems:

```text
missing lifetime specifier
expected named lifetime parameter

main.rs(24, 12): consider introducing a named lifetime parameter: `<'a>`, `'a `
```

Realising why this can be a problem was one of the key takeaways from my time with `C++`.

If we have a field in a struct that is a reference, there's the possibility that the struct may outline the data to which it references. In `C++`, this would result in a _dangling pointer_ and could lead to undefined behaviour if we tried to access the de-allocated memory.

The lifetime parameter, `'a`, explicitly ties the lifetime of the struct to that of the referenced data. This ensures that the underlying data in `&str` lives at least as long as the data from which it is referenced.

This very contrived example shows this in practice:

```rust
let book;

{
	let author = Author {
		name: String::from("Douglas Adams")
	};

	book = Book {
		title: String::from("The Hitchhiker's Guide to the Galaxy"),
		author: &author.name
	};
} // author.name is dropped

println!("{:#?}", book.author);
```

The compiler will immediately warn us that `author.name` does not live long enough to be referenced by the `Book` instance. When `Author` is dropped, the memory is released, which would leave the reference in `book.author` pointing to empty memory or, even worse, data which doesn't belong to our program. When possible, we should always strive to have our data types own their data directly.

As an alternative, we can change `author.name` to a string literal:

```rust
let author = Author {
	name: "Douglas Adams"
};
```

A string literal has a `'static` lifetime, which means that it is stored in the binary and persists for the entire duration of the program. However, `author` does not own its `name`. All it holds is a reference to some location in memory where the string literal resides. If we want `author` to own its `name`, then it's lifetime would become linked to that of `book` and it would have to live at least as long as `book`.

## Knowing when we need lifetimes

Generally, the compiler will guide you, but it is important to recognise _when_ we might need lifetimes because this makes it much easier to understand _why_ we need them.

The first situation is when **storing references in structs**. We have already explored this case.

The second is when **returning references from functions**:

```rust
impl Library {
	fn get_book_by_author(&self, author: &str) -> &Book {
		self.books.iter()
			.find(|b| b.author == author)
			.unwrap()
	}
}
```

This won't compile because the compiler cannot infer the lifetimes. If, for some reason, the `Library` goes out of scope, then our reference to a `Book` in that library would be left dangling. We fix this by adding a lifetime annotation, type the lifetime of the book to that of the parent data type:

```rust
impl Library {
	fn get_book_by_author<'a>(&'a self, author: &str) -> &'a Book {
		self.books.iter()
			.find(|b| b.author == author)
			.unwrap()
	}
}
```

The third case is when **defining trait objects with references**:

```rust
trait BookProcessor {
	fn process(&self, book: &Book) -> &str;
}
```

Again, this will not compile. Returning a string reference like this creates a **lifetime mismatch** problem as the compiler cannot guarantee that the string slice lives long enough. The trait definition does not specify where the string slice comes from, or how long it will live. This ambiguity means that the borrow checker cannot ensure that the reference is valid for the required lifetime.

We can specify a lifetime explicitly, telling the compiler that, for example, the output reference has the same lifetime as the input reference to `Book`:

```rust
trait BookProcessor<'a> {
	fn process(&self, book: &'a Book) -> &'a str;
}
```

All this is done to ensure memory safety without a garbage collector. By requiring explicit lifetimes like this, the compiler can ensure that no reference outlives the data to which it points.

## Lifetime Elision Rules

We have seen some of the situations where we have to add lifetimes. Now, let's turn to situations where `Rust`'s _lifetime elision rules_ allow us to omit them. These are common cases such as:

1. When each input reference gets it's own lifetime parameter
2. If there's exactly one input lifetime parameter, it's assigned to all output lifetimes
3. If there are multiple input lifetime parameters but one of them is `&self` or `&mut self`, the lifetime of self is assigned to all output lifetimes

For example:

```rust
impl Temporal for Book {
	// Actually means: fn exists_at<'a>(&'a self, year: i32) -> bool
	fn exists_at(&self, year: i32) -> bool {
		// implementation
	}
}
```

# Conclusion

In this post, we have seen how Rust is able to provide the ability to manually manage memory while still maintaining memory safety. _Traits_ and _lifetimes_ are especially important concepts in `Rust`, and understanding what purpose they serve opens up many doors to optimising and improving our applications.

If you've made it this far, I hope this has been informative or, at least, a good read. If you have any thoughts, comments, or corrections, or you just want to say hello, [Mastodon](https://hachyderm.io/@ta1da) is where you'll find me.

# Appendix

[1]: As I was writing this, it occurred to me that traits enforce the presence of methods, but don't enforce the presence of specific fields in a struct. So, any struct can implement the methods required by the trait without storing the necessary data internally. While this provides flexibility, it also leaves the door open for "empty" implementations that just satisfy the compiler. It is possible to use patterns like [procedural macros](https://doc.rust-lang.org/book/ch19-06-macros.html#procedural-macros-for-generating-code-from-attributes) to overcome this, but that is beyond the scope of this post.
