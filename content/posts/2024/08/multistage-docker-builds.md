---
title: Multistage Docker Builds for Go Web Apps
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/f_auto,q_auto/v1/realm/covers/golang-docker
tags: ["DevOps", "Docker", "Linux"]
description: Tried to shrink the docker image for my Go blog and ended up learning a lot about compiling Go binaries on different Linux distros.
publishDate: 2024-08-03
---

# Introduction

Recently, I had to clear over 30GB worth of unused docker images from my laptop, and that got me thinking about the sizes of my images. Most of those were images I had created for temporary development environments and just never bothered to revisit. One of them stood out, however, because it was the _Dockerfile_ for this site.

My current _Dockerfile_ is pretty standard, I believe. I had the idea of using multistage builds when I wrote it, then ran into some issues and just commented everything out. It uses an _Alpine_ base, which I guess shaves off a few MBs from the final image size - not nearly enough to make a difference.

```Dockerfile
FROM golang:alpine as build

# install node and build tools
RUN apk update && apk add --no-cache nodejs make build-base && apk add --update npm

WORKDIR /app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

RUN npm install

# build the app
RUN CGO_ENABLED=1 GOOS=linux go build -o /build ./cmd/site/main.go

# run stage with Alpine
# FROM alpine:latest as run

# WORKDIR /app

# RUN cd /app
# copy the Caddyfile
COPY ./Caddyfile /etc/caddy/Caddyfile

# copy the binary from the build stage
# COPY --from=build /build /app/site

EXPOSE 4242

CMD ["/build"]
```

# How Big is the Image?

As you can see, I've got Go (of course), Node, and a bunch of other packages that are required for building the binary. Before I get to trimming the fat off this image, we need to see how bad things are. We can find out by running `docker images`.

```bash
$ docker images site --format "{{.Repository}}:{{.Tag}} -> {{.Size}}"

site:latest -> 808MB
```

That's obviously not great. I'm willing to bet that my Go binary is pretty small, and the rest of the space is taken up by all the dependencies needed to build it. I use [air](https://github.com/air-verse/air) for live reloading, so my binary goes inside the _tmp_ directory.

```bash
# check that the binary is the only thing in the tmp folder
$ ls tmp
main

# use du with the h flag to check its size
$ du -h
23M     .
```

That means I've got close to 800MB of bloat in my image when I probably only need a fraction of that to run my site. I have to shed all that extra weight to keep my image light. Enter multistage builds.

# Multistage Docker Builds

A multistage _Dockerfile_ has more than one `FROM` statement. Each one marks a new build stage, and allows us to reference the previous stages. We do that using a name that we give the stage when we create it, e.g. `FROM alpine:latest AS run`, with run being the name of the stage.

Multistage builds still produce a single Docker image from the final stage of the build. As each stage allows us to choose a base image, we can use more lightweight distros like _alpine_ or even _distroless_ images for the runtime layer as we have no need for development dependencies at that point. After building the binary in the build stage, we can use `COPY --from=<stage>` to transfer it into the runtime stage.

# Fixing the Dockerfile

As you saw from the original _Dockerfile_, most of what we need to implement multistage builds here is already there. The reason I had to comment all that was because I was getting **no such file or directory** which, as I will show below, does not always mean that the file is missing. Even though in this particular case, it was.

```Dockerfile
# run stage with Alpine
FROM alpine:latest as run

WORKDIR /app

# copy the Caddyfile
COPY ./Caddyfile /etc/caddy/Caddyfile

# copy the binary from the build stage
COPY --from=build /build /app/site

EXPOSE 4242

CMD ["/app/site"]
```

Nothing changes in the build stage - we're only uncommenting a few lines in the the run stage and that just works. Weird. I could have sworn it didn't work before. Now, it just works. After building it, we can check the new size.

```shell
$ docker images site --format "{{.Repository}}:{{.Tag}} -> {{.Size}}"

site:staged -> 32.3MB
site:latest -> 808MB
```

This is a bit crazy because it ended up being much smaller than I expected. I was targeting something closer to 100MB but this is brilliant. A wiser man would stop here, take the win, and go touch some grass. I'm not that guy.

# How Small Can it Get?

With a lot of things, there is such a thing as diminishing returns - the point at which more effort only nets you very small gains. I want to see if I can take this to the extreme by using a _distroless_ image.

According to the [GitHub](https://github.com/GoogleContainerTools/distroless) repo, a _"distroless"_ image contains only _"your application and its runtime dependencies"_. That means no shell, package manager, or anything else you would normally find in a distro.

Getting started is easy thanks to the examples in the GitHub repo. From the Go sample, it looks like all I need to do is tweak the `FROM` statement in my run stage.

```Dockerfile
FROM gcr.io/distroless/static-debian11 as run
```

That's it?

Checking the size after building the image reveals that we have shaved a bit more weight.

```shell
docker images site --format "{{.Repository}}:{{.Tag}} -> {{.Size}}"

site:distroless -> 27MB
site:staged -> 32.3MB
site:latest -> 808MB
```

It's not a lot, in my opinion. But then again, all I had to do was change one line. Maybe these savings would add up if I was containerizing something much more complex.

I thought I was about to call it a day until I tried to run the new image:

```shell
$ docker run -p 4242:4242 site:distroless

exec /app/build: no such file or directory
```

# Getting the app to run on a distroless base image

That's super weird considering that I haven't changed much. The first thing to do in this situation is to check that the binary is inside the container by exporting its contents. This was something I never knew I could/would ever need to do until now.

```shell
$ docker create --name temp <your-image-name>
$ docker export temp > ~/Downloads/image-contents.tar
$ docker rm temp
```

Checking the contents of the archive using `tar` does little to clear things up. In fact, I'm more confused now than I was before.

![image](https://res.cloudinary.com/ta1da-cloud/image/upload/v1732555013/realm/tutorials/multistage-docker-builds/Pasted_image_20240730212352_ccsc07.png)

The binary clearly exists. Trying to run it directly again leads to the same **no such file or directory** error.

This error is a bit misleading, but it took me hours of researching and keyboard smashing to figure this out. What I eventually found out was that my Go binary is dynamically linked, instead of being statically linked. That means it doesn't contain all the dependencies it needs to run. We can see that by running a quick `ldd` on the compiled binary.

```shell
$ ldd ./image-contents/app/build

linux-vdso.so.1 (0x00007f73400d3000)
libc.musl-x86_64.so.1 => not found
```

Something called _libc.musl_ was missing. I did a bit more research and found out that the problem was that I built my Go binary using Alpine then tried to run it on a _Debian-based_ distroless image. I guess it's not _completely_ distroless.

Anyways, I had a few ideas on how to fix this. The easiest way would be to find an _Alpine-based_ distroless image.

_checking..._

So, they're all _Debian-based_.

Plan B it is, then. We need to rebuild the Go binary statically. This should create a binary that doesn't depend on any external dependencies.

```Dockerfile
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o /build ./cmd/site/main.go
```

These modifications to the `go build` command should allow cross-compilation with CGO enabled. However, I got the same error when I try to run the container:

```shell
$ docker run -p 4242:4242 site:distroless

exec /app/build: no such file or directory
```

At this point, I had half a mind to just switch back to the _Alpine_ image and be done with it. This feels like quite a lot to go through just to shave off 5MB from my image.

A bit more digging finally lead me to [this article](https://www.arp242.net/static-go.html). Here, I discovered that I was not correctly compensating for my usage of _cgo_. All I had to do was tell the C linker to statically link `-extldflags`.

```Dockerfile
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags="-extldflags=-static" -o /build ./cmd/site/main.go
```

That worked! I managed to get my site to run without a problem. I even did a quick `ldd` to confirm that I have a statically linked binary:

```shell
$ ldd image-contents/app/build

not a dynamic executable
```

A second opinion from `file` revealed the same thing:

```shell
$ file ./build

./build: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, BuildID[sha1]=2b741d4baa1e18f4ccd11cda23ccb6ece85fdd18, with debug_info, not stripped
```

# Conclusion

So, I managed to shrink my Docker image from 808MB to ~27MB, and all it cost me was a few hours and a bit of my sanity. On the plus side, I learned a lot about compiling Go applications, which is not as simple one might imagine.

If you've got questions or comments, you'll find me on [Mastodon](https://mastodon.social/@ta1da). If you enjoy my content, share it with a friend and stay tuned for me. Cheers!
