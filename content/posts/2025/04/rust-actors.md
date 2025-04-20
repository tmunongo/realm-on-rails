---
title: Exploring the Actor Model in Rust
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1734763339/realm/covers/library_mfqmlr.jpg
tags: ["Programming", "Rust", "Design Patterns"]
description: This blog post will explore the actor model using Rust. We'll discuss why it's a valuable approach, the challenges it helps overcome, and how to use it practically in your Rust programs.
publishDate: 2025-04-12
---

Following my last post on Elixir's _actor model-based_ concurrency, I became interested in how we can leverage the same model in one of my favourite languages - `Rust`. I find this combination particularly interesting because, as the software we build becomes more complex and code bases grow, we must build better tools that can help with the cognitive load of developing and maintaining it. Rust already achieves this with its memory safety, helping developers avoid the common pitfalls of manually managing memory. Similarly, concurrency is another common source of pain and suffering, and the _actor model_ offers a structured approach to building scaleable, maintainable, and concurrent systems.

This blog post will explore the actor model using Rust. We'll discuss why it's a valuable approach, the challenges it helps overcome, and how to use it practically in your Rust programs.

> _This post assumes a working knowledge of Rust_.

# Growing pains

If you've ever had to deal with traditional concurrency primitives like threads and mutexes, then you'll know that they can become a significant source of headaches, particularly in larger code bases. You haven't experienced suffering until you've had to track down a race condition or debug a deadlock involving multiple locks held by different modules in a large system. The bugs are almost impossible to reproduce, and the cognitive load is borderline unmanageable.

Consider this simplified example:

```rust
fn process_data(data: &mut SharedData) {
	//... possibly many other LOC
	// potential for a race condition here if multiple threads access this
	data.counter += 1
	//... more LOC
}
```

Without careful management, multiple threads can try to access and modify `SharedData`, and the results could be catastrophic. Managing locks to prevent this can introduce a different set of complexities, including the risk of deadlocks where a locked mutex is never unlocked, resulting in resource contention.

> _It's important to point out that the above code wouldn't compile without the use of synchronisation primitives like `Mutex` since multiple threads are accessing and modifying the same `SharedData`._

# The Actor Model: A Paradigm Shift

In my last post, I explored how the **actor model** offers a different way to think about building concurrent applications. Instead of directly manipulating shared state, it encourages us to break the system down into independent entities called **actors**. Each actor has its own state and logic, and communicates with other actors exclusively via asynchronous **messages**. This shift promotes modularity and makes it easier to reason about the behaviour of individual components within a large system.

## Inspired by CSP

The actor model's core principles are quite similar to the ideas introduced in _C.A.R Hoare's Communicating Sequential Processes (CSP)_. In CSP, independent processes communicate through channels, sending and receiving messages. Similarly, actors in the actor model operate in isolation, managing their own state, and interacting with each other by exchanging messages. This "share nothing" approach mitigates the risks associated with shared mutable state, such as race conditions and deadlocks.

As a language, Rust is inherently well-suited to implementing the actor model. Its ownership and borrowing system provide compile-time guarantees that prevent data races, a crucial aspect when dealing with concurrency, even within the message-passing paradigm. Additionally, Rust supports asynchronous programming via `async/await`, and powerful run times like `tokio` provide the necessary foundation for building efficient and non-blocking actor-based systems.

## Challenges addressed by the Actor model

Let's explore, more explicitly, some of the challenges that the actor model addresses, particularly in large code bases:

- **Improved modularity and maintainability**: breaking down a large application into independent actors with well-defined message interfaces, the actor model promotes modularity. This makes cross-team collaboration easier as changes within one actor are less likely to have unintended side effects on other parts of the system.
- **Simplified reasoning about concurrency**: instead of trying to wrap our heads around intricate locking mechanisms, developers can instead focus on the message handling logic within individual actors. This greatly simplifies the development and debugging process.
- **Enhanced scalability and resilience**: the asynchronous nature of message passing allows actors to handle many concurrent requests without blocking. In distributed systems, actors can reside on different machines, and the message-passing paradigm naturally extends to network communication, making it easier to build scaleable and fault-tolerant applications.

# Implementing Actors with `actix`

Now, we are going to illustrate the actor model by building a simplified **word count aggregator**. This aggregator will receive one word at a time and maintain a count of each unique word. You can find the complete code in the GitHub [repo](https://github.com/tmunongo/rust-actors).

The first thing we will do is create the message structs that define what messages our actors can send and receive:

```rust
#[derive(Message)]
#[rtype(result = "usize")]
pub struct AddWord(pub String);
#[derive(Message)]
#[rtype(result = "HashMap<String, u64>")]
pub struct GetCounts;
```

- The `AddWord` message adds a given word to the aggregator
- `GetCounts` retrieves the current word counts as a `HashMap`.

Next, we will define the `WordCountAggregator` struct, whose state is the `HashMap` containing the word counts.

```rust
pub struct WordCountAggregator {
    counts: HashMap<String, u64>,
}

impl Actor for WordCountAggregator {
    type Context = Context<Self>;
}
```

To make the `WordCountAggregator` an actor, we implement `Actor` for it, with a single type, `Context`, which holds the life cycle of the actor. Each actor runs within a separate context, with its own state and behaviour.

We define the behaviour through functions which specify how the actor will handle each message it receives.

```rust
impl Handler<AddWord> for WordCountAggregator {
    type Result = usize;

    fn handle(&mut self, message: AddWord, _: &mut Self::Context) -> Self::Result {
        let AddWord(word) = message;
        let count = self.counts.entry(word.clone()).or_insert(0);
        *count += 1;
        println!("Added word: {}, count is now {}", word, count);
        *count as usize
    }
}

impl Handler<GetCounts> for WordCountAggregator {
    type Result = ResponseActFuture<Self, HashMap<String, u64>>;

    fn handle(&mut self, _msg: GetCounts, _ctx: &mut Self::Context) -> Self::Result {
        let counts = self.counts.clone();
        let fut = async move { counts };
        Box::pin(fut.into_actor(self))
    }
}
```

These _handlers_ are defined for each of the message types we mentioned above.

The `AddWord` handler extracts the word from the message, and then tries to find the word in the existing word counts. If it does not exist, it will be added to the `HashMap`, then the count is increased and finally, that count is returned.

The `GetCounts` method clones the current word counts and creates a new asynchronous future that returns the cloned counts. This is then converted to an actor future, pinned to the _heap_ and returned.

### Interacting with the actor

We want to be able to interact safely with the `WordCountAggregator` actor by decoupling it from the outside world. We can do this by building an interface that allows us to interact with it without the need to know how it is implemented.

```rust
pub struct AggregatorHandle {
    addr: Addr<WordCountAggregator>,
}
```

As we cannot reference actors directly, but only by their address, we will always supply the handler with the address to the actor.

We need three handler functions:
**new**: to create a new instance of the actor, start it, and return a handle to it.
**add_word**: to send an `AddWord` message to the actor
**get_counts**: to send a `GetCounts` message to the actor

```rust
impl AggregatorHandle {
    pub fn new() -> Self {
        let actor = WordCountAggregator {
            counts: HashMap::new(),
        };

        let addr = actor.start();
        AggregatorHandle { addr }
    }

    pub async fn add_word(&self, word: String) {
        let _ = self.addr.send(AddWord(word)).await;
    }

    pub async fn get_counts(&self) -> Result<HashMap<String, u64>, actix::MailboxError> {
        self.addr.send(GetCounts).await
    }
}
```

The messages are sent to the actor mailbox, where they are subsequently processed.

## Using the Aggregator

We can test the aggregator by building a simple _CLI_ that will count the words as a user inputs them. We will use the word _"quit"_ as the exit trigger word.

```rust
#[actix::main]
async fn main() {
    let handle = AggregatorHandle::new();
    loop {
        let mut input = String::new();
        println!("Enter a word:");
        stdin().read_line(&mut input).unwrap();
        let input = input.trim();
        if input == "quit" {
            break;
        }
        let _ = handle.add_word(input.to_string()).await;
    }
    match handle.get_counts().await {
        Ok(counts) => {
            println!("Final word counts: {:?}", counts);
        }
        Err(e) => {
            println!("Error getting word counts: {:?}", e);
        }
    }
}
```

All we need is a loop that will query the user for some input, receive that input, and send a message to the actor to add the word. When the user inputs the word _"quit"_, the loop will exit, and we send a message to the actor to ask for the final counts.

This example demonstrates how the `WordCountAggregator` actor manages its internal state **(counts)** and responds to messages.

# Scaling and distribution

The actor model's message-passing nature makes it inherently well-suited for building distributed systems. For example, we can improve the above example by using `tokio::spawn` to have each `add_word` call from a different asynchronous task, and they will be processed sequentially by the actors without the need for explicit locks. Actors can reside on different machines, with communication happening over the network.

In this example, we used `actix` which provides abstractions for handling remote actors and message serialisation, making it easier to build complex distributed applications. However, to get a more in-depth understanding of the actor model, I would suggest trying to implement the same functionality using `tokio` since the actix framework is build on top of that.

# Conclusion

We have seen, in this post, how the **actor model**, especially when paired with Rust's power and safety, offers a compelling approach to building and maintaining complex, concurrent software systems. It simplifies concurrency management by allowing us to clearly define rules for communication between distributed entities, which promotes modularity. Generally, it provides a valuable set of tools for tackling the challenges of dealing with concurrency in massive codebases.

If you have made it this far, I hope that this has been informative or, at least, a good read. If you have any thoughts, comments, or corrections, or you just want to say hello, [Mastodon](https://hachyderm.io/@ta1da?ref=tawandamunongo.dev) is where you'll find me.

## Further resources

- **Tokio:** [https://tokio.rs/](https://tokio.rs/)
- Trying out the actor model in other languages:
  - **Pykka**: https://pykka.readthedocs.io/
