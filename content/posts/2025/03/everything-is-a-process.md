---
title: In Elixir, Everything is a Process
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1734763339/realm/covers/library_mfqmlr.jpg
tags: ["Programming", "Elixir"]
description: I set myself an interesting/unreasonable challenge with this one - trying to explain everything that makes Elixir special in a single post.
publishDate: 2025-03-08
---

# Introduction

I've always been interested in the challenges and obstacles software engineers face building bug-free and reliable distributed systems. In 2024, this interest led me to Elixir. Elixir is a dynamic and functional programming language built to run on the Erlang virtual machine (BEAM) with incredible scalability, fault-tolerance, and concurrency capabilities.

It wasn't immediately obvious to me what made Elixir special. At least, not until I understood one of it's core principles. This idea - that "everything is a process" - is the key to understanding the inner workings of this beautiful language, and a fundamental design choice that shapes how you build applications with Elixir. In this post, we will dive deep into what this means, how it's implemented, and the potential benefits of building software with Elixir.

This post assumes a basic understanding of Elixir syntax.

# Understanding Processes in Elixir

You have probably heard of operating system processes. An Elixir process is nothing like its resource-heavy namesake. Instead, it is a surprisingly lightweight unit of computation that runs concurrently with other processes within the Elixir runtime. The result is that, while an OS can efficiently manage thousands of threads or processes, Elixir, thanks to the BEAM, can comfortably run millions of these lightweight processes on a single machine.
Each Elixir process has its own:

- **Memory heap**: Isolated memory space for the process' data. This isolation is crucial for fault tolerance, as a crash in one process is unlikely to corrupt the state of others.

- **Mailbox for receiving messages**: A queue for asynchronous message handling without the need for external tools. Importantly, processes don't block waiting for messages; they process them when they arrive in their mailbox, enabling non-blocking concurrency.

- **Process ID (PID)**: A unique identifier for the process within the Elixir runtime. These PIDs are used to send messages to specific processes and are essential for the monitoring and supervision functionality provided by the Supervisor.

We can think of processes as being just another "green thread" - similar to goroutines. However, they are isolated from each other, meaning that if one process crashes, it doesn't affect the others directly due to the separate memory. This simplifies the mental model for concurrency and enables Elixir to excel at building robust and fault-tolerant systems.

## Creating processes

That is just about all the knowledge we need to start creating our own processes. We can do that with spawn/1, which creates a new process that runs a given function:pid = spawn(fn -> IO.puts("Hello from a new process!") end)

This code creates a new process that simply prints a message and then exits. You can run this code inside an Interactive Elixir (IEx) terminal and see that the spawn function returns a PID which can be used to send messages to the process.

## Message Passing

One important consequence of Elixir processes having isolated memory is that they can only communicate by passing messages.
For a more detailed exploration, check out my previous post, Making Sense of Concurrency in Go, where I referenced the seminal Communicating Sequential Processes paper by CAR. Hoare.

This is a core concept in the actor model, which Elixir embraces. Processes don't share memory; instead, they send messages to each other. This has the benefit of eliminating the need for concurrency primitives like mutexes.
You can send a message to a process by using send/2

```elixir
:send(pid, {:hello, "world"})
```

To receive messages, a process uses the receive/1 block

```elixir
:receive do
{:hello, msg} -> IO.puts("Received hello with message: #{msg}")
end
```

This retrieves a message from the process mailbox if it matches the pattern. These isolated processes communicating via message passing are what allow Elixir to excel at building concurrent systems.

# Processes for State Management

In Elixir, processes are also used for state management. As a functional programming language with immutable data structures, maintaining state can be a challenge. Processes provide a solution to this problem.
We can visualise this by building a simple counter as a process:

```elixir
defmodule Counter do
def start do
spawn(fn -> loop(0) end)
end

    defp loop(count) do
    	receive do
    		:increment -> loop(count + 1)
    		:decrement -> loop(count - 1)
    		{:get, sender} ->
    			send(sender, count)
    			loop(count)
    	end
    end

end
```

The Counter module creates a process that maintains a count. When we call spawn, it starts a new process that runs loop/1, with an initial value of 0. This process accepts messages to increment or decrement the count, or to retrieve the current value.

A key aspect of this Counter example, and state management in Elixir processes in general, is the use of recursion in the loop/1 function. Because Elixir is functional and data is immutable, we can't simply update a variable to change the counter's value. Instead, loop/1 achieves state persistence through recursion.
Let's examine how this works. Consider the :increment message::increment -> loop(count + 1)

When the process receives :increment, it calculates the new count (count + 1). Then, it recursively calls loop/1 with this new count. This recursive call is what defines the next state of the process. The original loop/1 call ends, but a new loop/1 call begins, now holding the updated count. This recursive looping is how the process effectively remembers and updates its state over time as it receives messages.
We can test this counter in IEx (after saving the contents of the above in counter.ex):

```elixir
# compile

iex(1)> c("counter.ex")
[Counter]

# start the process

iex(2)> counter_pid = Counter.start()
#PID<0.113.0> # your PID will be different

# send the increment message

iex(3)> send(counter_pid, :increment)
:increment

# send the get message

iex(4)> send(counter_pid, { :get, self() })
{:get, #PID<0.114.0>}

# receive the get message

iex(5)> receive do
...(5)> count -> IO.puts("Current count: #{count}")
...(5)> end
Current count: 1
:ok
```

# Supervisors and OTP

The idea that everything in Elixir is a process extends to the supervision strategies.

The Open Telecom Platform (OTP) is a set of libraries and design principles that come with Elixir (inherited from Erlang). In OTP, supervisors are special processes that monitor other processes (called worker processes) and can restart them if they crash. This creates a hierarchical process structure that can recover from failures automatically.

Because processes are designed to be lightweight and potentially fail, the importance of Supervisors cannot be understated. They embody the 'let it crash' philosophy by providing a structured way to handle failures and having supervisors restart processes to maintain the system's resilience.
Here's an example of a Supervisor:

```elixir
defmodule MyApp.Supervisor do
use Supervisor

def start_link(init_arg) do
Supervisor.start_link(**MODULE**, init_arg, name: **MODULE**)
end

@impl true
def init(\_init_arg) do
children = [
{Counter, 0}
]

    Supervisor.init(children, strategy: :one_for_one)

end
end
```

This Supervisor starts and monitors the Counter process, restarting it if it crashes. The :one_for_one strategy used here is just one strategy, and the OTP provides others like :one_for_all and :rest_for_one. We won't go in-depth here, but you can read more about them here.
Our focus has been on Supervisors, but the OTP is broader than just supervisors. It's a comprehensive framework of libraries, patterns, and design principles for building reliable, distributed, and fault-tolerant BEAM-based applications, and Supervisors are a key part of this framework.

## Advantages of the Process-centric Approach

Before we dive into a real world example of how these processes work in action, we will take a look at some of their advantages:

- **Concurrency**: Elixir processes are lightweight and can run concurrently and efficiently, taking full advantage of multi-core systems.
- **Fault-tolerance**: The isolation of processes means that failures are contained. Combined with supervision strategies, this leads to self-healing and resilient systems.
- **Scalability**: The process model scales naturally horizontally from a single machine to distributed systems across multiple nodes.
- **State management**: Processes provide a clean way to manage state in a functional language.
- **Resource isolation**: Each process has its own memory heap, preventing resource contention or memory leaks in one part of the system affecting others.

# Processes in Practice: Building a chat server

We are going to see how processes work together in a real-world scenario by implementing a simple chat application using Elixir.

```elixir
# chat.ex
defmodule ChatServer do
def start do
  spawn(fn -> loop(%{}) end)
end

defp loop(clients) do
  receive do
    message ->
    case message do
      {:register, client_pid, username} ->
        IO.puts("#{username} joined the chat")
        new_clients = Map.put(clients, client_pid, username)
        broadcast(new_clients, :server, "#{username} joined the chat")
        loop(new_clients)
          {:message, from_pid, message} ->
              case Map.get(clients, from_pid) do
                nil ->
                  loop(clients)
                username ->
                broadcast(clients, username, message)
                loop(clients)
              end

          {:unregister, client_pid} ->
              case Map.get(clients, client_pid) do
                nil ->
                  loop(clients)
                username ->
                  IO.puts("#{username} left the chat")
                  new_clients = Map.delete(clients, client_pid)
                  broadcast(new_clients, :server, "#{username} left the chat")
                  loop(new_clients)
              end
    end
  end
end

defp broadcast(clients, from, message) do
  Enum.each(clients, fn {pid, \_} ->
  send(pid, {:message, from, message})
  end)
end
end
```

The first process, shown above, is the ChatServer. This process manages the chat room, keeping track of connected clients, and broadcasting messages.
It maintains a map of connected clients (with each client represented by its PID) and their usernames. Here, we handle user registration and deregistration, as well as message broadcasting.

```elixir
# chat.ex continued
defmodule ChatClient do
def start(server_pid, username) do
  spawn(fn -> loop(server_pid, username) end)
end

defp loop(server_pid, username) do
  send(server_pid, {:register, self(), username})
      message_loop(server_pid, username)
end

defp message_loop(server_pid, username) do
  receive do
    msg ->
      IO.inspect(msg, label: "Client message received")
      case msg do
        {:message, from, message} ->
        IO.puts("[#{from}] #{message}")

        {:send, message} ->
          send(server_pid, {:message, self(), message})
        end
        Process.sleep(100)
        message_loop(server_pid, username)
    end

end

def send_message(client_pid, message) do
    send(client_pid, {:send, message})
  end
end
```

The ChatClient consist of multiple processes - one for each connected client - that are responsible for sending and receiving messages.

It interacts with the server process through message passing. When a client sends a message, it's forwarded to the server, which then broadcasts it to all connected clients.

We will test this implementation of the chat system in an IEx session:

```elixir
# Compile
iex(4)> c("chat.ex")
[ChatClient, ChatServer]

# Start the chat server

iex(7)> server_pid = ChatServer.start()
#PID<0.160.0>

# Start three client processes

iex(8)> ada = ChatClient.start(server_pid, "Ada")
#PID<0.161.0>
iex(9)> bob = ChatClient.start(server_pid, "Bob")
#PID<0.162.0>
[server] Bob joined the chat
iex(10)> charles = ChatClient.start(server_pid, "Charles")
#PID<0.163.0>
[server] Charles joined the chat

# Send a message from Ada

iex(17)> ChatClient.send_message(ada, "Hello, from Ada")
{:send, "Hello, from Ada"}

# the message will appear for all clients

[Ada] Hello, from Ada
[Ada] Hello, from Ada
[Ada] Hello, from Ada

# Bob responds

iex(18)> ChatClient.send_message(bob, "Hi, Ada! I'm Bob")
{:send, "Hi, Ada! I'm Bob"}
[Bob] Hi, Ada! I\'m Bob
[Bob] Hi, Ada! I\'m Bob
[Bob] Hi, Ada! I\'m Bob

# Finally, a message from Charlie

iex(19)> ChatClient.send_message(charles, "Hey folks!")
{:send, "Hey folks!"}
[Charles] Hey folks!
[Charles] Hey folks!
[Charles] Hey folks!
```

The example shows our chat server accepting connections from three clients. Each client can send messages, and these are all broadcast to all connected clients.

As you can see, each message appears three times in our shell because we have three clients. Try to improve the broadcast/3 function so that the broadcast message is not sent back to the original sender.

Through this example, we got to see several aspects of Elixir's process-centric design:
- **Concurrency**: Each client runs in its own process, allowing the system to handle many clients simultaneously.
- **State Management**: The server process maintains the state of connected clients, demonstrating how processes can be used for stateful operations in a functional language.
- **Message Passing**: All communication between clients and the server is done through asynchronous message passing, showcasing Elixir's actor model implementation.

# Conclusion

I like to think of my software development journey as having a before and after Elixir. Before I discovered Elixir, all I knew about building concurrent systems was that it was something to be avoided at all costs. After immersing myself in Elixir and getting to understand its "everything is a process" model, I gained a clearer understanding of what it takes to build stable concurrent systems.

I hope you got to see, too, how this philosophy is the bedrock of a language designed for resilience and scale. With multi-core systems being the norm these days, most developers will, at some point, have to wrestle with the beast that is concurrency. Elixir equips developers with an intuitive toolkit for tackling concurrency challenges, ensuring that we can build robust and scalable software with greater ease whilst also avoiding the potential pitfalls.

If you have made it this far, I hope that this has been informative or, at least, a good read. If you have any thoughts, comments, or corrections, or you just want to say hello, Mastodon is where you'll find me.
