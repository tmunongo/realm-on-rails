---
title: Exploring Pub/Sub for Building Scalable Systems in Go
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1714023369/realm/essays/go-pubsub/4_crkths.png
tags: ["Programming", "Go"]
description: In this article, we will see how publish/subscribe allows us to build resilient, loosely coupled, and scaleable systems that align more with the demands of modern data-intensive, distributed applications.
publishDate: 2024-04-27
---

# Introduction

_Publish/Subscribe_, commonly referred to as _Pub/Sub_, is a messaging pattern that facilitates asynchronous communication between services. It is an example of an event-driven pattern. A _pub/sub_ system consists of three main entities: _publisher_, _subscriber_, and the _message broker_. In this article, we will see how _pub/sub_ allows us to build resilient, loosely coupled, and scaleable systems that align more with the demands of modern data-intensive, distributed applications.

# Background

Traditionally, inter-service communication has predominantly followed a request-driven pattern, in contrast to the event-driven approach. The _request/response_ pattern is characterized by tight-coupling, with both the client and the server knowing a lot about each other and what the other requires. Communication is often synchronous, which means that after making a request, the client must wait for the response from the server before continuing. This architecture breaks down, however, when we begin to build systems with many services, e.g. a microservice architecture.

![Request Response Chaining](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1714023369/realm/essays/go-pubsub/3_xwdj5c.png)

The example above is a simplified version of what it may look like when a user uploads an image to a photo-sharing platform like Instagram. We see that, once the user uploads their image, it must first be handled by the _Upload Service_ where it may be stored in a temporary storage area. That service makes a request to the _Filter Service_ which applies any requested filters to the image. It makes a request to the _Resize Service_, and so on, until the process is complete and a notification is sent to the user (and, possibly, their followers) that their image is ready, then it is shared.

While this chain is simpler than a possible mesh-architecture alternative, there are still many issues that we must address. The first being that, if any of those requests fail, the whole chain breaks. That puts additional responsibility on the developers to set up mechanisms to handle these failures, and to decide what to do when they happen. Secondly, request/response is a synchronous, blocking pattern, which means that latency will have a positive correlation with the number of hops in the request chain. Additionally, a timeout is also needed to avoid situations where a server sits indefinitely waiting for a response from a server that may be busy.

We can summarise the issues with request/response as follows:

- It is bad for multiple receivers
- high coupling
- clients and servers must be always running

One of the more popular alternatives to this request-driven architecture is an event-driven one such a the _publish/subscribe_ pattern.

We use event-driven patterns where:

- scalability is important
- we have many moving parts that are constantly evolving
- we want loose coupling and to put more power in the hands of the receivers
- we want to avoid a messy _mesh architecture_ where multiple clients must communicate with many other clients

# Understanding the Pub/Sub Pattern

As already mentioned, _publish/subscribe_ is an event-driven inter-service communication pattern. Events are "both a fact and a notification". They represent something that has happened but do not include an expectation of any further action that must be taken. This is sometimes described as _'fire-and-forget'_, signifying how, in an event-driven architecture, the event emitter often doesn't wait for any acknowledgment from any possible receivers that the event has been received.

An important thing to note in an event-driven architecture is the inversion of responsibility from the emitter to the recipient. We can take, for example, communication between the **Warehouse Service**, **Notifications Service**, and **Inventory Service** on the backend of a theoretical e-commerce platform, as shown below.

![Services communicate via message broker](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1714023369/realm/essays/go-pubsub/4_crkths.png)

In this pattern, responsibility falls on the recipient to decide if an event emitted on a given topic is of interest to them. The **Warehouse Service** simply needs to emit events on the _order packaged_ topic. It does not need to know specifically who should receive the request and what they must do with it. The **Notifications** and **Inventory** services choose to subscribe to events on this topic because they both have an interest in performing some actions when the order has been packaged.

# Pub/Sub

At its core, the _pub/sub_ pattern aims to distribute a single event to multiple subscribers. As we mentioned earlier, there are three main components of a _pub/sub_ system which we will now explore more in-depth.

## Publisher

The publisher is the originator whose main responsibility is generating the data that will be published. A publisher can be anything, from a backend service to an IoT device. This data is published to a topic, and subsequently to all subscribers automatically. The data is created as a message, and includes the event data along with any other metadata that may be useful as part of the message.

> **A quick aside on messages vs events**
>
> An event is a _statement of fact_ about something happening with some info about what exactly happened. A message is something sent over asynchronous communication such as a message broker. A message is a typical way of broadcasting an event.
>
> The message is the medium, the event is the payload.

## Subscriber

A subscriber consumes messages on specific topics. They receive, process, and act upon data received from a topic. Subscribers are responsible for deciding which topics they are interested in.

## Message Broker

The final piece of the puzzle is the message broker. A message broker is an intermediary managing communication between processes/services. It provides both a way for publishers to emit events and for subscribers to receive those events. This can be handled via topics or queues.

Queues are _linear_, which means a message is put on a queue, and a consumer reads from that queue. They are designed for **one-to-one** communication so each message in a queue is consumed by a single receiver. Once that message is consumed, it is removed from the queue to prevent other consumers from receiving it.

Topics are designed for **one-to-many** scenarios. Multiple interested subscribers can receive messages published to a given topic. They allow for **broadcast-style communication**, delivering all messages to interested parties. Topics are the main vehicle of communication in the **pub/sub** model.

Message brokers are the lynch-pin of the **pub/sub** pattern. They handle the state of consumers, keeping track of what they have seen before. They often offer some kind of delivery guarantee. This absolves the event emitter of having to worry about whether or not to retry if the other service is unreachable, which is often the case in a **request/response** pattern.

# Pros and Cons of using the Pub/Sub Pattern

## Pros

As we have shown, the **pub/sub** pattern provides many ways for us to build resilient, scaleable systems. If we are building a system with multiple services, we do not need to worry about request chaining and handling potential failures in that chain. It allows us to build loosely-coupled systems, which has many advantages such as allowing us to add and remove individual parts of that system with minimal effort, and to make changes that don't impact other modules.
In summary, **pub/sub**:

- Allows for building resilient systems
- Scales with multiple receivers
  - The number of publishers and subscribers is not set in stone. We can add more of either to a required topic depending on usage.
- Is great with microservices
- Allows loose coupling
  - We can build more modularized software components that are easier to maintain and extend.
- Works even if the client (receiver) is not running

## Cons

It's not all perfect.

**Message Delivery**: One of the biggest challenges for this pattern is related to message delivery. How can the emitter know that the consumer actually got the message? _Apache Kafka_, for example, offers _exactly once delivery_. This is important because accidentally triggering an event more than once can have unintended consequences. That is why it is important to ensure that the message broker supports exactly once semantics.

**Added complexity**: The changes required to both the system and one's mental model to move from a **request/response** to **pub/sub** are not trivial. Some may find it to be a source of unnecessary additional complexity and waste of resources in smaller applications. Additionally, the need for the broker to be always running to develop and test your services is something else for developers to consider when adopting this pattern.

# Implementing in Go

We are going to explore further the **pub/sub** pattern by building a simple implementation in Go using **CloudAMQP**. **CloudAMQP** provides managed RabbitMQ and LavinMQ servers, allowing us to try out message queueing.

You can begin by setting up an account on their [website](https://customer.cloudamqp.com/signup), and then return to this to follow along.

Start by creating a new Go project:

```bash
# make new directory
mkdir <project_name>
cd <project_name>
# initialize go module
go mod init github.com/<your_git_username>/<project_name>
```

We will be using the Go CloudAMQP library maintained by [streadway](https://github.com/streadway). Proceed to install the library:

```shell
go get github.com/streadway/amqp
```

We will also need the **godotenv** library for automatically importing our _.env_ file into the code:

```bash
go get github.com/joho/godotenv
```

In our main function, we first get the **CLOUDAMQP_URL** from the environment. Make sure that, after creating a new instance in **CloudAMQP**, you copy the given URL into your _.env_ file. We use this URL to establish a connection using `amqp.Dial(url).

```go
func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	url := os.Getenv("CLOUDAMQP_URL")
	if url == "" {
		url = "amqp://localhost"
	}

	// establish connection
    connection, err := amqp.Dial(url)
	log.Println("Connected to CloudAMQP")
    if err != nil {
		log.Fatalln(url)
        panic(err)
    }
    defer connection.Close() // clean up connection when done
}
```

### Publisher

We need to start a goroutine to publish messages. Inside the goroutine, we open a channel using `connection.Channel()`. Create a timer using `time.NewTicker(1 * time.Second)` that ticks every second.

```go
go func() {
	channel, err := connection.Channel()
	if err != nil {
		panic(err)
	}

	// every second
	timer := time.NewTicker(1 * time.Second)

	// ... rest of goroutine
}
```

We want to provide a number as an argument when we run the program, and that number will be published to the consumers. Inside the timer loop, we check if an argument has been provided. If not, we print an error and exit. Otherwise, we convert that argument which will be in string format to a number.

```go
go func() {
	// previous code
	for t := range timer.C {
		if len(os.Args) < 2 {
			fmt.Println("Please provide a number as an argument.")
			os.Exit(1)
		}

		num, err := strconv.Atoi(os.Args[1])
		if err != nil {
			fmt.Println("The argument should be a number.")
			os.Exit(1)
		}

		// ...
	}
}
```

Lastly, we create an `amqp.Publishing` struct with the message properties such as delivery mode, timestamp, content type, and body. Then, publish the message to an exchange named _"amqp.topic"_ with the routing key "ping".

```go
// rest of publisher code
for t := range timer.C {
	// ...

	// create message
	msg := amqp.Publishing{
		DeliveryMode: 1, // persistent
		Timestamp:    t,
		ContentType:  "text/plain",
		Body:         []byte(strconv.Itoa(num)),
	}

	// publish message to exchange "amq.topic" with routing key "ping"
	mandatory, immediate := false, false
	err = channel.Publish("amq.topic", "ping", mandatory, immediate, msg)
	if err != nil {
		panic(err)
	}
}
```

The publisher will publish a message every second.

### Consumer

Similarly, we will create a goroutine for our consumer. The goroutine also opens a channel using `connection.Channel()`, declares a queue named test using `channel.QueueDeclare()`, bind the queue to an exchange named _"amq.topic"_, using _#_ as the routing key with `channel.QueueBind()`. This allows us to receive messages with any routing key.

```go
// start a goroutine to consume messages
go func() {
	// open a channel
	channel, err := connection.Channel()
	if err != nil {
		panic(err)
	}
	defer channel.Close() // clean up channel when done

	// declare a queue, set durable, autoDelete, exclusive, noWait to false
	durable, autoDelete, exclusive, noWait := false, true, false, false
	q, err := channel.QueueDeclare("test", durable, autoDelete, exclusive, noWait, nil)
	if err != nil {
		panic(err)
	}

	// bind queue to exchange with routing key "#"
	err = channel.QueueBind(q.Name, "#", "amq.topic", false, nil)
	if err != nil {
		panic(err)
	}
	// ...
}
```

We consume messages with `channel.Consume()`. Inside our consumption loop, we print out the received message body, timestamp, and acknowledge the message using `message.Ack()` because we set `autoAck` to false when we consume.

```go
// start consuming messages, set autoAck, exclusive, noLocal, noWait to false
		autoAck, exclusive, noLocal, noWait := false, false, false, false
		messages, err := channel.Consume(q.Name, "", autoAck, exclusive, noLocal, noWait, nil)
		if err != nil {
			panic(err)
		}

		// print received messages and acknowledge them
		// set multiAck to false
		multiAck := false
		for msg := range messages {
			fmt.Println("Body:", string(msg.Body), "Timestamp:", msg.Timestamp)
			msg.Ack(multiAck)
		}
```

When we run the program, you can see the open queue in the **CloudAMQP** dashboard:

![Queues on CloudAMQP](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1714023418/realm/essays/go-pubsub/Pasted_image_20240417080408_rbrkv6.png)

And the printed received messages in the console:

![Messages consumed and logged](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1714023419/realm/essays/go-pubsub/Pasted_image_20240417080551_nd1s2n.png)

You can find the full code in the GitHub [repo](https://github.com/tmunongo/go-pubsub).

# Conclusion

As we have seen, the _pub/sub_ pattern provides us with a way to deal with some of the complexity of building modern, distributed applications. For systems that use, for example, a microservice architecture, _pub/sub_ adds an extra layer of predictability and reliability. However, it is also not universal solution and can add unnecessary complexity to smaller applications.

If you have any questions, comments, or suggestions, the comment section is below, and my [Mastodon](https://mastodon.social/@ta1da) is open. Get in touch, let's chat. Otherwise, never stop learning.

# Resources

- Building Microservices, 2nd ed. - Sam Newman
- Designing Event-Driven Systems, Ben Stopford
