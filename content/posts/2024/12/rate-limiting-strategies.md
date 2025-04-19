---
title: Rate Limiting Strategies for Backend Services
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1735542764/realm/covers/rate-limiting-cover_clnllr.jpg
tags: ["Python", "FastAPI", "Backend Design Patterns"]
description: Rate limiting is an essential technique for protecting backend services and ensuring fair resource usage. In this post, we explored Token Bucket, Fixed Window, Sliding Window, and Redis-based Distributed Rate Limiting, all implemented in Python with FastAPI.
publishDate: 2024-12-30
---

# Introduction

A while back, I worked on a task to automate the translation of a bunch of web pages using the Google Translation API. I was using the free-tier, and soon got blocked off from the service by the rate limiter. At the time, this was quite frustrating, even though I did find a way to get past it. As I have built and used more public APIs, however, I have become sympathetic to the need for rate limiting and throttling, especially as a way to ensure fair use of public resources.

This experience did get me thinking about different strategies for rate limiting and why one might be preferred over another. In this post, I will explore different rate limiting strategies, showing how to implement them using `Python` and `FastAPI` and why one might be chosen over another.

# What is rate limiting

**Rate limiting** is a technique used in the design of backend services to control the rate at which requests are accepted and processed by the server. This is done to protect system resources, ensure system stability, and enforce fair use among clients. Allowing uncontrolled traffic in a public-facing API with no safe guards is risky and can lead to ballooning costs, degraded performance, and even outages.

There are a few things to consider when implementing rate limiting.

For starters, it can be implemented at different levels of the [OSI stack](https://en.wikipedia.org/wiki/OSI_model). For example, it can be set up at the network level, which would limit the number of requests that can be made to a specific network resource. In our case, we will implement it at the _application level_.

Secondly, it's important to correctly define "_excess traffic_". We want to prevent abuse of our APIs, but we don't want to end up blocking legitimate traffic via an overly aggressive rate limiter. In this case, we must correctly classify network traffic, using as much available information about an incoming request as possible to determine whether or not it should be rate limited.

Third, we need to get our _limits_ right. This forces us to think about _what counts as a reasonable number of requests for any given client to send to our server within a given period_. We must consider that, for example, we may experience traffic spikes at certain times of the day and, if these are the times most of our users are active, we run the risk of denying service to legitimate users. On the other hand, we have to consider how much traffic our servers can handle to guide us and avoid bringing the whole service down.

# Why rate limiting is necessary

There are a few reasons why we may want to implement rate limiting. These fall into two buckets - protecting our servers and our ability to provide the service, and ensuring that legitimate users do not get degraded performance.

## Fair resource allocation

Any service must ensure that no client or group of clients overwhelm the system and block off access for the rest of the users. We must also ensure that only legitimate users are using our service, as opposed to, for example, bots or other malicious actors. Rate limiting helps us ensure that _legitimate clients are given equal opportunity to access our service_ while also limiting those who may seek to monopolise our resources.

## Compliance

Many services have _service-level agreements (SLAs)_ with clients to guarantee availability and access. In order to meet these targets (e.g. "1000 requests per user per day"), we need to be able to ensure that no one user overwhelms the system to the point of being unable to serve everyone else. This ties in to the need to ensure that no single user or group of users consumes disproportionate system resources.

## Protecting servers

Rate limiting also _protects_ our servers from _Denial-of-Service_ attacks. These are attacks meant to overwhelm and possibly bring down a server by flooding it with excess traffic. According to [Cloudflare](https://blog.cloudflare.com/ddos-threat-report-for-2024-q3/), _Distributed-Denial-of-Service (DDoS)_ attacks spiked in Q3 2024, resulting in a 55% YoY increase. Along with that, excess traffic need not always be malicious - sometimes it can be as simple as someone accidentally writing an infinite loop with a call to our API. Regardless, we must be vigilant in protecting our servers.

## Cost management

Resource usage can get out of hand if not kept in check. Especially if we are using a public cloud service with auto-scaling enabled, heavy traffic can increase the scale factor, resulting in ballooning server bills.

# Rate limiting strategies

## Some rate limiting concepts

Before we get into the actual strategies, it's important to address three shared concepts at the core of how we implement rate limiting: _limit_, _identifier_, and _window_, i.e. how many requests _(limit)_ can a given user or users _(identifier)_ make within a given period of time _(window)_. We use these elements to determine whether or not a given request should be subject to rate limiting.

Armed with this knowledge, the second decision is how to handle the requests if the limit has been reached. The server can respond by _blocking_ the request, _throttling_, or _shaping_ it.

_Blocking_ is straightforward - when the limit had been reached, we do not allow any more access to the resource. This is usually a way to protect the server from excessive traffic, while the next two are more concerned with reigning in users.

_Throttling_ allows us to continue serving requests but with degraded service. I have seen this done by sites slowing down the download speed, for example, once a certain limit has been exceeded.

_Shaping_ allows the request to go through, but it will be given lower priority, meaning that any requests from users who have not exceeded the limit will be served first. For example, AI-powered code editors like Cursor may allow a certain number of queries for free-tier users, and then de-prioritise queries from the user if they have passed the limit by putting them at the back of the queue. This would allow paying users or those have yet to exceed their limit to continue to get the best service.

## The strategies

As mentioned, we will only be exploring rate limiting at the application level; specifically these four strategies:

1. Token bucket
2. Fixed window
3. Sliding window
4. Distributed sliding window with Redis

We will implement these strategies as a `FastAPI` middleware and show how each comes with its on set of advantages and trade-offs.

# Token Bucket

The _token bucket_ strategy is one of the most widely-used rate limiting strategies because of its simplicity to implement. It allows for bursts of requests while maintaining a steady rate over time. During this time, tokens are added to a _bucket_ at a constant rate, with each request consuming a token. Requests are denied if the token bucket is empty. We can set a maximum capacity for the bucket, as unused tokens accumulate and we would be wise to put a cap on how much they can accumulate.

Properties:

```python
class TokenBucket:
	def __init__(self, capacity:int, rate: int, window: int = 60):
		self.capacity = capacity
		self.tokens = capacity
		self.refill_rate = rate / window
		self.last_refill = time()
```

You can see that we add *token*s at some _refill rate_ to a _bucket_ with a given _capacity_, starting with a full bucket. If we run out of tokens, a request can be retried once more tokens are available.

```python
def allow_request(self) -> bool:
        now = time()
        elapsed = now - self.last_refill
        self.tokens = min(self.capacity, self.tokens + elapsed * self.refill_rate)
        self.last_refill = now

        if self.tokens >= 1:
            self.tokens -= 1
            return True
        return False
```

The biggest advantage of this strategy is how it handles bursts of traffic. Let's say your bucket is full (capacity = 100), that means that the server can handle a burst of 100 requests instantly, while refilling the bucket to handle any incoming requests. In this case, we can have as many as `rate + capacity` requests in a given window.

```python
# declaring the bucket and middleware
bucket = TokenBucket(capacity=200, rate=10, window=10)

@app.middleware("http")
async def rate_limit(request: Request, call_next):
    if bucket.allow_request():
        return await call_next(request)
    else:
        return JSONResponse(
            status_code=429,
            content={"detail": "Too Many Requests"}
        )
```

Testing the API using [`oha`](https://crates.io/crates/oha) shows that we can initially handle a burst of requests until we use up the initial bucket capacity. Then, with our bucket being refilled at 10 tokens every 10 seconds, we can handle another 29 requests in the next _< 30 seconds_.

```shell
> oha -z 30s "http://localhost:8000"
Summary:
  Success rate:	100.00%
  Total:	30.0032 secs
  Slowest:	0.3171 secs
  Fastest:	0.0070 secs
  Average:	0.0343 secs
  Requests/sec:	1459.3423

Status code distribution:
  [429] 43509 responses
  [200] 229 responses
```

When the bucket is empty, we get a [429 response](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429) from the server.

# Fixed window

This algorithm tracks requests made in _discrete intervals_ (e.g. per second, minute, or hour). If the number of requests exceeds the interval limit, additional requests will be denied or throttled.

The biggest advantage of this technique is that it works well for enforcing strict limits. We may include a _capacity_ to allow unused tokens to accumulate, which would allow the API to also handle bursts of traffic. Without that, this technique is more susceptible to those bursts of traffic at window boundaries (e.g. a flood of requests at the end and start of consecutive windows).

Properties:

```python
class RateLimiter:
    def __init__(self, limit: int, window_size: int):
        self.limit = limit
        self.window_size = window_size # in seconds
        self.requests = 0
        self.window_start = time()
```

The _limit_ specifies the number of requests we want to allow within a given interval, denoted as _windowsize_. We count the number of requests received, and reset them when the window elapses.

```python
def allow_request(self) -> bool:
        now = time()
        # Reset window if expired
        if now - self.window_start > self.window_size:
            self.requests = 0
            self.window_start = now

        # Check if under limit
        if self.requests < self.limit:
            self.requests += 1
            return True
        return False
```

Let's define a rate limiter to allow _20 requests_ every _10 seconds_:

```python
limiter = RateLimiter(limit=20, window_size=10)
```

and test with `oha`:

```bash
> oha -z 30s "http://localhost:8000"
Summary:
  Success rate:	100.00%
  Total:	30.0013 secs
  Slowest:	0.5886 secs
  Fastest:	0.0060 secs
  Average:	0.0334 secs
  Requests/sec:	1496.5362

Status code distribution:
  [429] 44812 responses
  [200] 60 responses
```

The results are as expected - within 30 seconds, our API only allows 60 requests.

# Sliding window

The _sliding window_ algorithm is designed to solve the main issue with the _fixed window_ technique by smoothing out limits across overlapping windows. This provides a more consistent rate limiting experience, reducing spikes at boundaries. It is, however, more complex to implement.

Properties:

```python
class SlidingWindow:
    def __init__(self, limit: int, window_size: int):
        self.limit = limit
        self.window_size = window_size  # in seconds
        self.requests = deque()  # store request time stamp
```

We keep track of each request made within the time period in memory, using the client IP address, for example, as the identifier. We can store these in a queue, popping the oldest request when they become older than the _window size_.

```python
def allow_request(self) -> bool:
        now = time()

        # remove older requests
        while self.requests and now - self.requests[0] > self.window_size:
            self.requests.popleft()

        # check if under limit
        if len(self.requests) < self.limit:
            self.requests.append(now)
            return True
        return False
```

Once again, our rate limiter will accept _20 requests_ every _10 seconds_:

```python
limiter = SlidingWindow(limit=20, window_size=10)
```

```bash
> oha -z 30s "http://localhost:8000"
Summary:
  Success rate:	100.00%
  Total:	30.0023 secs
  Slowest:	0.4688 secs
  Fastest:	0.0011 secs
  Average:	0.0309 secs
  Requests/sec:	1618.9767

Status code distribution:
  [429] 48482 responses
  [200] 60 responses
```

The results look identical, but that's only because `oha` makes the initial requests so fast that they all seem to happen at the same instant and all get popped from the queue at exactly the same time.

This technique is much better, but the implementation has a few disadvantages:

- Storing request data _in-memory_ means that it _can't scale_ across multiple servers
- It has a _greater memory footprint_
- The _state will be lost_ when we restart the server

We can solve these issues by bringing in `Redis`.

# Distributed sliding window with Redis

Redis is a powerful, in-memory key-value store that we can use to implement rate limiting. It allows us to share state across multiple instances of our application and reduce memory usage.

Properties:

```python
class RedisRateLimiter:
    def __init__(self, redis: Redis, limit: int, window: int):
        self.redis = redis
        self.limit = limit
        self.window = window
```

By pairing Redis with the sliding window technique, we get all the upsides of that technique plus the scalability, memory efficiency, and reliability that Redis provides.

```python
def allow_request(self, client_id: str) -> bool:
        now = time()
        window_start = now - self.window
        key = f"rate:{client_id}"

        # remove old requests
        self.redis.zremrangebyscore(key, 0, window_start)

        # count remaining requests in window
        current_requests = self.redis.zcard(key)

        # allow if under limit and add
        if current_requests < self.limit:
            self.redis.zadd(key, {str(now): now})
            self.redis.expire(key, self.window)
            return True

        return False
```

This time, our rate limiter will allow _1000 requests_ in a given _10 second-window_:

```python
limiter = RedisRateLimiter(redis, limit=1000, window=10)
```

```bash
> oha -z 30s "http://localhost:8000"
Summary:
  Success rate:	100.00%
  Total:	30.0023 secs
  Slowest:	1.0601 secs
  Fastest:	0.0184 secs
  Average:	0.1734 secs
  Requests/sec:	288.6777

Status code distribution:
  [429] 5611 responses
  [200] 3000 responses
```

This works, but it's not good enough. We need to prove that this works across multiple instances of the application as long as they share the same Redis instance. We can do that easily using `Docker`. You can find the full code in the [GitHub repo](https://github.com/tmunongo/pyrate-limit) for this post.

## Distributed test results

After spinning up 3 instances of my application (instructions for that can be found in the README), I ran the test again with `oha` using a simple script to query all 3 instances at once:

```shell
> python3 test/test_distributed.py

Starting test

Results for http://localhost:8001/test:

Status codes:
  200: 1005
  429: 7620

Results for http://localhost:8002/test:

Status codes:
  200: 998
  429: 7585

Results for http://localhost:8003/test:

Status codes:
  200: 1002
  429: 7632

Waiting 15 seconds before next test...
```

In the end, we let in 3005 requests after running the load test for just a hair over 30 seconds, which is just over the limit but the discrepancy is likely due to imperfections in the testing script.

A quick glance at the Docker logs also shows that the requests are handled by different instances, and that instances that have exceeded the limit are rate limited, while the rest continue to have their requests served.

```bash
...
api1-1   |       INFO   172.18.0.1:53448 - "GET /test HTTP/1.1" 200
api2-1   |       INFO   172.18.0.1:57078 - "GET /test HTTP/1.1" 429
api3-1   |       INFO   172.18.0.1:51708 - "GET /test HTTP/1.1" 429
api1-1   |       INFO   172.18.0.1:53508 - "GET /test HTTP/1.1" 200
api2-1   |       INFO   172.18.0.1:56720 - "GET /test HTTP/1.1" 429
api3-1   |       INFO   172.18.0.1:51606 - "GET /test HTTP/1.1" 429
api1-1   |       INFO   172.18.0.1:53412 - "GET /test HTTP/1.1" 200
api2-1   |       INFO   172.18.0.1:56830 - "GET /test HTTP/1.1" 429
api3-1   |       INFO   172.18.0.1:51616 - "GET /test HTTP/1.1" 429
api1-1   |       INFO   172.18.0.1:53824 - "GET /test HTTP/1.1" 200
...
```

What's clear is that each server just about stays within the limit. Of course, this could be improved by adding a load-balancer, but that is beyond the scope of this post.

# Conclusion

We have seen how rate limiting is an invaluable tool in every API designer's toolbox. It allows us to regulate how much traffic our servers receive, which can be a way to protect them from malicious actors, bots, and incompetent coders. We can also ensure that all our legitimate users can access the API and that no one monopolises the available resources. Finally, it also helps us to keep our server costs in check.

There are a few ways to improve the above implementations, including adding the necessary headers, and improving client identification. As mentioned in the intro, I was able to get past Google's Translation API rate limiting, but I'll leave improving these implementations as a task for the reader.

If you have made it this far, I hope that this has been informative or, at least, a good read. If you have any thoughts, comments, or corrections, or you just want to say hello, [Mastodon](https://hachyderm.io/@ta1da) is where you'll find me.
