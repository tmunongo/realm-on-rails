---
title: Using C++ Was Supposed to Make Me Appreciate Rust...
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1731851172/realm/tutorials/cpp-hash-map/cover_hash_cpp_rppveu.png
tags: ["C++", "Rust", "Programming", "DSA"]
description: Instead, I ended up liking it more than Rust.
publishDate: 2024-11-17
---

# Introduction

I have a bit of a love-hate relationship with `Rust`. Most of the time, I enjoy writing it, but there are times when it feels like the compiler can be a bit overbearing. Which is understandable - it's a language that requires correctness - but my limited experience with `C`/`C++` outside of a few classes in uni meant that I'm not **entirely** familiar with the problems that it was built to solve. So, a few weeks ago, I set out to solve that by diving back into `C++`.

A linked-list would have been perfect to work on in C++ given that I [recently did so in Rust](https://www.tawandamunongo.dev/posts/rust-smart-pointers-linked-list), but I found the C++ version to be a bit on the easy side. I decided, instead, to go with a hash map, which turned out to be an excellent way to understand the similarities and differences between the languages. Along the way, I gained a deeper understanding of memory management, templates, and the C++ standard library's design philosophy. I might even go as far as to say that I came out of it liking C++ more than Rust.

# A Bit of Theory, First

Before we dive into the implementation, let's take a moment to understand how hash maps work and what makes them such an important data structure. If you are already familiar, feel free to skip to the next section.

## What is a Hash Map

You may know them by other names such as hash table or dictionary - the underlying idea is the same: it is a data structure that implements an associative array abstract data type. Simply put, they map _keys_ to _values_.

What makes them special, however, is that they can achieve **O(1)** average complexity for insertions, deletions, and look-ups. This gives us the best of both worlds compared to linked lists (slow look-up, fast insertion and deletion), and arrays (fast look-up, slow insertion and deletion).

### Hash Function

At the core of this is a hash function. This function allows us to generate a hash _( should be as unique as possible)_ from the key that will map to the value we want to store. A hash function should consistently return the same output for the same input, and should distribute outputs uniformly across its range.

A good hash function should have these three properties:

- **Determinism**: Produce the same hash for the same input
- **Uniform distribution**: Outputs should be spread evenly
- **Efficiency**: Computation should be fast

We can compare, for example, a pair of possible hash functions. One is good, the other one not so much:

```cpp
size_t bad_hash(const std::string& input) {
    size_t ascii_sum = 0;

    for (char c : input) {
        ascii_sum += static_cast<unsigned char>(c);
    }

    return ascii_sum % 10;
}
```

In the first example, we get a reference to the key string and then sum the ASCII values of all the characters in the string. Finally, we apply the modulo operator to constrain the hash output to 10 possible values. This is a bad hash function because it maps all possible strings into one of 10 buckets (0 to 9).

We can improve this function:

```cpp
size_t better_hash(const std::string& input) {
    uint32_t hash = 0;
    for (char c : input) {
        hash = hash * 31 + static_cast<unsigned char>(c);
    }

    hash = ((hash >> 16) ^ hash) * 0x45d9f3b;
    hash = ((hash >> 16) ^ hash) * 0x45d9f3b;
    hash = (hash >> 16) ^ hash;

    return hash;
}
```

This improved version generates a rolling hash for the input string, and then uses bit manipulation (multiple times) to mix the higher and lower bits of the hash to improve entropy. Then, we multiply by the `hex` constant `0x45d9f3b` to further scramble the bits and help spread the values more uniformly.

# Implementing the Hash Map

There are four important aspects of the hash map design that I will outline here:

1. **Hash function**: instead of trying to be a hero and writing my own, I decided to leverage `C++`'s `std::hash`.
2. **Storage**: I took some inspiration from `Rust`'s Hash Map implementation and used separate chaining with linked lists for collision resolution (collions are inevitable)
3. **Memory management**: using **smart pointers** to manage the nodes is the way to go, even if it means missing the opportunity to get my hands dirty with some manual memory management.
4. **Generics**: the hash map should be generic over both key and value types, which can be achieved using `Template Parameters`.

## The Basic Structure

In an empty directory, create a _hashmap.h_ file for the class definition:

```cpp
// includes...

template <
    typename  K,
    typename  V,
    typename Hash = std::hash<K>
>
class HashMap {
private:
    struct Node {
        K key;
        V value;
        std::unique_ptr<Node> next;

    Node(const K& k, const V& v)
        : key(k), value(v), next(nullptr) {}
    };

    std::vector<std::unique_ptr<Node>> buckets;
    size_t size_;
    float max_load_factor_;
    Hash hasher;

public:
    explicit HashMap(size_t initial_capacity = 16, float max_load_factor = 0.75)
        : buckets(initial_capacity)
        , size_(0)
        , max_load_factor_(max_load_factor)
        , hasher() {}

    void insert(const K& key, const V& value);
    bool remove(const K& key);
    void resize(size_t new_capacity);
    V* get(const K& key);
    const V* get(const K& key) const;
    size_t size() const { return size_; }
    bool empty() const { return size_ == 0; }
};
```

As mentioned above, we use the `unique_ptr` smart pointer. This ensures that dynamically allocated memory is released from the free store (heap).

The hash map will have an initial capacity of 16, and we will set the maximum _load factor_ at 0.75.

The _load factor_ is the ratio of filled slots to total slots:

![load factor calculation](https://res.cloudinary.com/ta1da-cloud/image/upload/v1731851160/realm/tutorials/cpp-hash-map/Screenshot_from_2024-11-17_15-29-47_mjdl9r.png)

This is important because the higher the load factor, the more likely collisions become. However, if the load factor is too small, then we are essentially wasting space. If the load factor ever goes above the maximum, we will resize the hash map. Typically, we should double the size.

## Implementation

Because the `HashMap` class is a template, all the definitions must be in the header file. This is because `C++` compilers need to see the implementations when instantiating templates as they are resolved at compile time.

```cpp
template<typename K, typename V, typename Hash>
void HashMap<K, V, Hash>::insert(const K& key, const V& value) {
    if (float(size_ + 1) / buckets.size() > max_load_factor_) {
        resize(buckets.size() * 2);
    }

    size_t index = hasher(key) % buckets.size();

    auto current = buckets[index].get();
    while (current) {
        if (current->key == key) {
            current->value = value;
            return;
        }
        current = current->next.get();
    }

    auto new_node = std::make_unique<Node>(key, value);
    new_node->next = std::move(buckets[index]);
    buckets[index] = std::move(new_node);
    size_++;
}

template<typename K, typename V, typename Hash>
bool HashMap<K, V, Hash>::remove(const K& key) {
    size_t index = hasher(key) % buckets.size();

    if (!buckets[index]) {
        return false;
    }

    if (buckets[index]->key == key) {
        buckets[index] = std::move(buckets[index]->next);
        size_--;
        return true;
    }

    auto current = buckets[index].get();
    while (current->next){
        if (current->next->key == key) {
            current->next = std::move(current->next->next);
            size_--;
            return true;
        }
        current = current->next.get();
    }

    return false;
}

// more functions
```

# Memory Management Deep Dive

I will only explore the main differences/similarities between this and how we would handle memory management in Rust. You can check out the full code on [GitHub](https://github.com/tmunongo/chash) with comments explaining the actual Hash Map implementation if that's something in which you are interested.

1. Smart Pointers:
   We use the `std::unique_ptr` smart pointer, which is similar to `Rust`'s `Box<Node>`. It automatically frees up memory when the pointer goes out of scope, freeing us from having to worry about that. Also, similarly to `Rust`'s ownership rules, it cannot be copied, only moved.

2. Move Semantics
   One of the things that always trips me about in Rust is the idea of implicit moves. Let's take this, for example:

```rust
fn main() {
    let s1 = String::from("hello, rust!");
    let s2 = capitalize(s1);

    println!("{}", s1);
    // println!("{}", s2);
}
```

If we try to print `s1`, we get this error:

```shell
error[E0382]: borrow of moved value: `s1`
  --> src/main.rs:5:20
   |
2  |     let s1 = String::from("hello, rust!");
   |         -- move occurs because `s1` has type `String`, which does not implement the `Copy` trait
3  |     let s2 = capitalize(s1);
   |                         -- value moved here
4  |
5  |     println!("{}", s1);
   |                    ^^ value borrowed here after move
```

In the above example, ownership of the `String` has moved from `s1`, a problem which can easily be rectified by borrowing or cloning.

In `C++`, however, we explicitly transfer ownership of the pointer using `std::move`. After moving, the original pointer becomes null.

3. Raw Pointer Usage
   The last key point is the usage of raw pointers for traversal. When we use:

```cpp
   auto current = buckets[index].get();
```

we get a raw pointer, `Node*`. This does not affect ownership - the `std::unique_ptr` remains responsible for freeing up memory when it goes out of scope. Of course, this still offers fewer memory safety guarantees than Rust because, if the `std::unique_ptr` is destroyed or reset, any dangling raw pointers will cause undefined behaviour.

# Conclusion

Writing this hash map in `C++` helped me understand a lot about what problems `Rust` was designed to solve. What I liked most about `C++` was the greater flexibility on offer, even though it requires more careful handling of memory and edge cases. Without the safety net provided by the borrow checker, we also have to be more mindful of ownership and lifetimes.

I know this sounds crazy, but this experience left me with a newfound appreciation and, dare I say, love for `C++`. I especially liked the flexibility. I made more mistakes, many of which could end up as [CVE](https://en.wikipedia.org/wiki/Common_Vulnerabilities_and_Exposures)s, but I learnt a lot, too. That's not to say I wouldn't learn the same things in Rust, but, at least in `C++` I can actually finish writing my code.

Don't be surprised to see more `C++` content here in the future. If you've made it this far, I hope this has been informative. If you think I got something wrong, would like to suggest improvements, or just want to say hello, you can find me on [Mastodon](https://hachyderm.io/@ta1da).
