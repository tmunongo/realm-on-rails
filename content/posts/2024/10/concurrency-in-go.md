---
title: Making Sense of Concurrency in Go
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1729941331/realm/tutorials/concurrency-in-go/cover.png
tags: ["Programming", "Go", "Concurrency"]
description: This is my best attempt at plugging the holes in my understanding of concurrency. It ends with me building a concurrent word count application.
publishDate: 2024-10-26
---

# Intro

I recently had my first real-world run-in with concurrency while working on a tunnel application to expose my homelab services. It sent me down a bit of a rabbit hole and, in this post, I'll share everything I learned about building concurrent applications with _Go_.

# The Problem

I want my application to provide two listeners: one for the tunnel service to handle and forward requests to my homelab, and another for the web interface. Obviously, these have to be running concurrently and listening on different ports.

This wasn't my first introduction to Go concurrency, but all I knew was that I could use the `go` keyword to create something called a _goroutine_. So, armed with this grain of knowledge, I set out to make the necessary changes to allow my application to concurrently start the tunnel and web servers.

```go
fn main() {
// some other code
if *serverMode {
	go web.startWeb("server")
	go runServer()
}
// mode code
}
```

Of course, that didn't work. But, I was more intrigued by how exactly it failed. When I ran the application, nothing happened. At that point, I was certain that both the tunnel listener and the web server were working. I even tested them separately. Clearly, I had a few holes in my understanding of concurrency in Go (and, in general), and what you'll read below is my best attempt at plugging those holes. We'll finish this off by building a concurrent word count application using our newly acquired concurrency toolbox.

# Why didn't the `go` keyword just work?

The logic is sound - we need to create two branches that will run concurrently and that's what the `go` keyword should do. The major flaw has to do with how concurrency works in Go. But, before we get to that, we need to understand a few basic ideas.

## Concurrency vs. Parallelism

I have seen many people try to explain the difference between concurrency and parallelism, which tells me that it's either something that's hotly contested, or just very difficult to pin down.

The way I understand it, concurrent things happen at the _same time_, but not necessarily _simultaneously_.

### Parallelism in hardware

Let's say we have a single-core machine. Even if we wrote our code to run in parallel, parallel execution would still not be possible because we would only have a single processor on which to execute. This means that parallelism is more a property of the hardware than it is about the code.

But, as with everything else in life, _context_ matters.

### Context

Imagine we have two running tasks. We can have a scheduler giving each task some CPU time before switching context to the other one. Task A takes 2 seconds (we'll use seconds for simplicity) to complete, while Task B takes 3 seconds.

![5 second context](https://res.cloudinary.com/ta1da-cloud/image/upload/v1729940559/realm/tutorials/concurrency-in-go/Pasted_image_20241026120930_iaafuz.png)

Our scheduler switches context every second, allowing each process to run for a second at a time. If our context window is 5 seconds, it will appear as if both tasks happen at the same time because both would be complete within that time. If, however, we reduce the context window to 4 seconds, we discover that Task A completes within 4 seconds instead of 2. The other 2 seconds are used by Task B.

![Reduced context window](https://res.cloudinary.com/ta1da-cloud/image/upload/v1729940559/realm/tutorials/concurrency-in-go/Pasted_image_20241026122755_mkadye.png)

The conclusion, then, is that within a 5-second context, these two tasks are parallel, but reducing the context size reveals that they are, in fact, concurrent.

This distinction is important because Go's concurrency model uses **goroutines** which present the problem space as a concurrent one instead of a parallel one. And, at the core of that is the _fork-join_ model.

## The Fork-Join Model

The _fork-join_ model is a paradigm in parallel programming where one or more branch points are created from a program's main line of execution. This branching off establishes a _child_ branch that runs concurrently with the parent. The _fork_ refers to this ability of the program to split off at a _fork point_ and execute. The _join_ refers to that branch eventually rejoining/synchronising with the main line of execution at a _join point_.

![Forking and joining](https://res.cloudinary.com/ta1da-cloud/image/upload/v1729940560/realm/tutorials/concurrency-in-go/Pasted_image_20241026121836_hhfyk1.png)

### Back to the code

With that in mind, let's return to the code that started all of this.

I used the `go` keyword to spawn two **goroutines** (more on that later) and they are scheduled by the runtime, but there is no guarantee that either one of them will run before the main _goroutine_ exits.

![Forking and not joining](https://res.cloudinary.com/ta1da-cloud/image/upload/v1729940560/realm/tutorials/concurrency-in-go/Pasted_image_20241026122941_zllpbk.png)

As we can see, we need a way to ensure that there is still a main _goroutine_ for the child branches to eventually rejoin. We have to create a _join point_.

# Synchronisation

We need to update the main function so that it doesn't exit before the _goroutines_ have a chance to run. In other words, we need to synchronise. Go offers us a few ways to achieve this using the `sync` package in the standard library. Let's explore some of them.

### A tangent - Goroutines

Before we get to that, we should take this opportunity to talk a bit about _goroutines_.

_Goroutines_ are like OS threads, but they're much more lightweight and efficient. They run at the user level and are managed by Go's runtime. Because they are so lightweight, the runtime can create millions of _goroutines_ with very minimal system overhead. Each _goroutine_ has its own _growable segmented stack_, which starts out very small, but can grow if there's ever need. They communicate by passing messages via _channels_. This design choice allows for efficient sharing of data between _goroutines_ when needed.

## Waitgroup

With that out of the way, the simplest way to think of a `Waitgroup` is as a counter tracking the number of running _goroutines_.

Remember how I showed that the problem with just using the `go` keyword is that the main _goroutine_ will probably exit before the child _goroutine_ has a chance to execute? We can use `wg.Wait()` - this function ensures that we don't exit until our _goroutines_ finish executing. In other words, we want to wait until the counter reaches 0.

We use the functions `wg.Add` and `wg.Done` to allow us to increase and decrease the counter, respectively.

```go
var wg sync.WaitGroup

if *serverMode {
	// increase the wait counter by the number of
	// go routines we plan to create
	wg.Add(2)
	// create an anonymous go func and immediately call it
	go func() {
		// use defer to decrease the counter eventually
		defer wg.Done()
		runServer()
	}
	go func() {
		defer wg.Done()
		web.StartWeb()
	}
}
// some more code
// start a goroutine to wait until all the goroutines are done
go func() {
	wg.Wait()
} ()
```

This is a simplified version of the actual code. Ideally, we should also create and pass a context into our goroutines to allow us to gracefully shut them down. This context is derived from `context.Background`:

```go
ctx, cancel := context.WithCancel(context.Background())
```

The `cancel` function is used to signal termination to any goroutines that carry the context. When the function is called, `ctx` will carry a cancellation signal that can be checked by the goroutines. At this point, they will clean up their resources and shut down.

Note the use of the `defer` keyword to call `wg.Done` and decrease the counter when the _goroutine_ completes. Co-location of `wg.Add` and `wg.Done` is good form as it makes it easier to debug. We can see if the counter decrement is missing which is often the source of some nasty bugs.

## Mutex

A key aspect of Go's concurrency model is that we want to avoid sharing memory. As the _Go_ idiom goes:

> **Don't communicate by sharing memory, share memory by communicating**

However, this is not always possible. Unlike, for example, the BEAM languages where each _thread_ has isolated memory, _goroutines_ still share memory as they share the same address space within a program. The `sync` package provides primitives for synchronising access to shared resources.

A _mutex_ (mutual exclusion) is a concurrency primitive that provides a way to control access to any _critical section_ of our program. It ensures that, especially in concurrent environments, access to resources is coordinated to prevent race conditions.

I like to think of it like a bank vault - if anyone can go in at any time and take money out and we don't keep track, sooner or later someone will walk in to withdraw some money and find it empty. So, we put a guard by the door who only allows one person in at a time. Similarly, we want to avoid a situation where two processes are accessing the same region of memory because all kinds of chaos can happen if both of them try to make changes.

```go
var count int
var mu sync.Mutex
var wg sync.WaitGroup

// Process 1
wg.Add(1)
go func() {
	// use wait groups to sync the goroutines
	defer wg.Done()
	for i := 0; i < 5; i++ {
		func() {
			// lock the mutex and unlock after incrementing count
			mu.Lock()
			defer mu.Unlock()
			count++
			fmt.Println("Process 1:", count)
		}()
		time.Sleep(100 * time.Millisecond)
	}
}()

// Process 2
wg.Add(1)
go func() {
	defer wg.Done()
	for i := 0; i < 5; i++ {
		func() {
			mu.Lock()
			defer mu.Unlock()
			count++
			fmt.Println("Process 2:", count)
		}()
		time.Sleep(150 * time.Millisecond)
	}
}()

wg.Wait()
fmt.Println("Final count:", count)
```

When we _lock_ the mutex, only the current _goroutine_ is allowed to access the _critical section_ and modify count. But, we must unlock it after. It's not uncommon to find bugs in concurrent code caused by a mutex left locked.

You may be wondering why I didn't use the tunnel application to show mutexes in action. I could use a mutex for both the `runServer()` and `web.StartWeb()` _goroutines_, but both are long-running processes which won't return until the context is cancelled. That means whichever one runs first will not release the mutex, thus blocking the application forever. That's something to pay attention to when using mutexes with long-running processes.

# CSP and Go Channels

I mentioned earlier that `Go` is designed to allow developers to build concurrent applications while avoiding the pitfalls of sharing memory. This is at the core of what make `Go`'s memory model special. It's not a unique idea, though. It's an application of a concept introduced by Charles Anthony Richard "Tony" Hoare in his 1978 paper, _Communicating Sequential Processes (CSP)_.

### A bit more theory - Communicating Sequential Processes (CSP)

> I actually got introduced to _CSP_ recently after a kind stranger on Mastodon recommended that I learn `Elixir`. It's one of three languages (that I know) that run on the `BEAM VM` where _CSP_ ideas are at the core.

As I understand it, the idea behind _CSP_ is that sharing memory is problematic. It often leads to problems including deadlocks, race conditions, starvation, etc. To avoid this, processes share data by **message passing**.

To be clear, sharing memory is not inherently bad. There are times when it's necessary. But, we are better off avoiding it because it makes our jobs harder, especially as our programs become more complex.

In _CSP_, a process is an _"encapsulated portion of logic"_. It may have inputs and outputs, and those inputs may be the outputs from another function, while the outputs may feed another function. Processes communicate synchronously by sending data through _channels_. The communication is synchronous because a sender will only send if the receiver is ready to receive the message. Hoare introduces two commands, `!` and `?`, for sending data into and reading from a channel, respectively.

I will leave my exploration of _CSP_ there as I'm sure you'll be able to find much better and more detailed explanations. I'll leave a [link](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf) to the original paper because, for a technical paper from the 70s, it's a surprisingly good read.

## Channels

`Go` channels get their name from the similar construct in Hoare's CSP, and are built around message passing. Their best use is facilitating communication between `goroutine`s, even though they can also be used to control access to shared memory.

A channel variable stores data. We can store data in a channel at one point, then have another process read that data later.

```go
sigChan := make(chan os.Signal, 1)

// some code

// Wait for interrupt signal
<-sigChan
log.Println("Received interrupt signal. Shutting down...")
```

For example, this channel holds an OS signal which can then be accessed later.

You may be wondering what the `<-` operator means. Channels can be unidirectional, such that they only read or write data.

```go
// read only channel
var dataChan <-chan interface{}

// send only channel
var dataChan chan<- interface{}

// bidirectional channel
dataChan := make(chan interface{})
```

The code above shows the two different ways in which we can initialise a channel variable. A channel with the `<-` operator on the left side can only read data, while having the operator on the right side means it can only send data. We can also use `make` to create a bidirectional channel.

That operator is also used to send and read data:

```go
stringChan := make(chan string)

go func() {
	stringChan <- "Hello channel"
}()
```

When the `<-` operator is to the right of the channel, the data is being sent to the channel. Think of it as data flowing _into_ the channel. The data from the channel can be read by putting the operator to the left side of the channel as in, data flowing _out of_ the channel.

```go
fmt.Println(<-stringChan)
```

# A Demo Project

In this final section, we will apply everything we have learned about concurrency in `Go` by building a simple application that will read data from a text file, count the occurrences of every word in the text, and then dump the results as key-value pairs to an output text file. Of course, we will use `goroutine`s to make this faster.

A short overview of how our program will work:

- Read the text file and break it down into chunks.
- Create a `goroutine` worker pool with a fixed number of workers.
- Send each chunk to a worker for processing, and receive a map of words-to-occurrence count.
- Merge the resultant maps into one final result
- Write the results to a text file.

## Reading the text file

We will use the `os` package to read the text file from our _samples_ directory.

```go
file, err := os.Open('samples/paradise-lost.txt')
if err != nil {
	log.Fatal(err)
}
```

Next, we create a `lines` buffered channel so that we can distribute the text chunks between the worker *goroutine*s. This channel will accept 100 lines of text before blocking, and those lines will be fed into our worker pool of *goroutine*s.

```go
lines := make(chan string, 100)
```

These text files could get quite big, so we have to make sure that reading one does not block the main thread. We will use a _goroutine_ to read the file text line-by-line and send each line to the `lines` channel.

```go
go func() {
	defer close(lines)
	// chunk the text file
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines <- scanner.Text()
	}
	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
}()
```

## Creating a worker pool

We will create a worker pool of *goroutine*s and limit it to the number of CPUs on the machine. We need to limit the number of workers in our pool because synchronisation to communicate through channels comes at a cost which can impact performance.

```go
// get number of cpus
cpus := runtime.NumCPU()

// start workers
for w := 0; w < cpus; w++ {
	wg.Add(1)
	results[w] = worker(lines, &wg)
}
```

We use a `WaitGroup` to ensure that all the chunks have been processed before merging. We will also need a channel to hold the results from each worker, which we will merge in the end.

```go
results := make([]<-chan map[string]int, cpus)
```

## Processing each 'chunk'

As you can see above, we have a `worker` function that takes a some lines and a reference to the `WaitGroup`, allowing us to decrease the counter after processing.

```go
func worker(chunks <-chan string, wg *sync.WaitGroup) <-chan map[string]int {
	ch := make(chan map[string]int)
	go func() {
		defer close(ch)
		defer wg.Done()
		for chunk := range chunks {
			ch <- processChunk(chunk)
		}
	}()
	return ch
}
```

This function returns a map of strings to integers - words to counts. The `processChunk` function does most of the heavy lifting. This function will transform each word to lower case and strip any common punctuation. This way, we avoid having multiple entries for the same word.

```go
func processChunk(chunk string) map[string]int {
	wordCount := make(map[string]int)

	words := strings.Fields(chunk)

	for _, word := range words {
		// match case to avoid duplication
		word = strings.ToLower(word)
		word = strings.Trim(word, ".,!?:;\"'()[]{}*#%&-=<>")

		if word != "" {
			wordCount[word]++
		}
	}

	return wordCount
}
```

## Merge the results

The results from each worker are stored in the `results` channel, which we can merge to get the final result.

```go
final := mergeMaps(results...)
```

Just for good measure, we can also sort the final map by appearances to have the most common words at the top.

```go
sortedCounts := sortWordCounts(final)
```

This is all mostly housekeeping, so, for the sake of brevity, I'll leave the detailed functions out. You can find the complete code in the [GitHub repo](https://github.com/tmunongo/wordcount-go) along with the sample texts to try it yourself.

# Conclusion

So, I ended up covering way more than I had set out to explore in this post. I know enough about concurrency now to know that, where possible, it should be avoided. When it works, it feels like magic, but it's so easy to get wrong, and quite difficult to debug. But, don't let that discourage you because getting it right feels sooo good.

Since you've made it this far, I can only hope that this has been informative, or, at least, a good read. If you think I got something wrong, would like to suggest improvements, or just want to say hello, you can find me on [Mastodon](hachyderm.io/@ta1da).
