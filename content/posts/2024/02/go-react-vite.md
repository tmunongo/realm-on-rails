---
title: Building a Full-Stack Web App with Go, React, and Vite
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1708323761/realm/tutorials/vite-react-go/WITH_pu1lk3.png
tags: ["Tutorial", "Go", "React"]
description: I really like Go. And, while the whole community has been obsessing over pairing it with HTMX, I figured I would start with what I know. So, here's how I would pair Go and React for building full-stack web apps.
publishDate: 2024-02-19
---

# Introduction

For the last couple of months, I have been working on a Laravel project that I should be able to share with the world soon. For reasons I won't get into here, I had to manually set up asset bundling with Vite without using [Inertia](https://inertiajs.com/) or [Laravel Breeze](https://laravel.com/docs/10.x/starter-kits#breeze-and-inertia) which would have made it super easy.

I learned a few things along the way and found myself wondering if I could apply them to my Go projects, too. I'm a big fan of full-stack frameworks because they allow me to only keep track of a single codebase. But, Go doesn't do full-stack frameworks like Laravel or Rails, which used to put me off learning it until I realized that Go is so expressive that it allows you to do so much with so little.

**Full disclosure, I am still learning Go, so I won't claim that this is the best way to do this, and I will touch on some issues with this set-up towards the end. However, if you do see something on which we can improve, feel free to create an issue in the [GitHub repo](https://github.com/tmunongo/react-vite-go) or leave a comment below.**

# SPAs

My first encounter with SPAs was a few years ago when I tried to use _View page source_ on a site only to find a single div element. I was so confused. I thought the site's creator had finally found a way to hide their source code.

I know better, now. If you're already familiar with SPAs, you can skip ahead.

In the early days of the web, websites were made up of a bunch of HTML files. We call these **Multi-Page Apps** (**MPAs)**, now. **SPAs**, on the other hand, contain a single web page. They load once, and subsequent interactions happen dynamically without full page reloads.

This is useful for building web applications that feel like apps, providing seamless navigation, faster interactions, and reducing server requests.

Frameworks like React, Vue, and Angular have dominated web development for the last few years, even though the community is slowly moving back to the MPA architecture. SPAs are still useful, though, especially for web apps where SEO is not a priority, and those smooth, app-like transitions are.

# A Simple Server

Go is a _battery-included_ programming language, which means we can write a web server and handle requests in just a few lines.

Assuming you already have [Go installed](https://go.dev/dl/) on your machine, create a folder for your project: `mkdir <project_name>`

I am going to call mine `go-react-spa`.

After you navigate to the directory, initialize the project with `go mod init github.com/<username>/<project_name>`. In Go, it is customary to use the GitHub repo for your module name.

We will start by setting up a simple route handler for _"/"_ that will respond with plain text. A Go handler function receives two parameters: _an http.ResponseWriter to which you write your response_ and an _http.Request that contains all information about the current request_.

```go
package main

import (
	"net/http"
	"log"
	"fmt"
)

func main() {
	http.HandleFunc("/", func (w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hellloooo")
	})

	log.Print("Listening on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

```

I like creating a Makefile with some useful commands, so you can also add one to your project root with the following contents.

```
run:
	go run server.go

build:
	go build -o bin/goreact

```

If you run `make run` or just `go run server.go` in your terminal, replacing 'server.go' with your file name, your server should be running, and you can navigate to _localhost:8080_ in your browser.

![Plain Text Response](https://res.cloudinary.com/ta1da-cloud/image/upload/v1708161788/realm/tutorials/vite-react-go/Pasted_image_20240217100757_vvyueb.png)

# Serving a static file

This is cool and all, but let's give our site a bit more life by serving an HTML file. We are going to create a public directory for our static files.

Update the handler in your _server.go_ with the following code.

```go
http.HandleFunc("/", func (w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "public/index.html")
})

```

If your _index.html_ is in a different location, you can use that location, too.

Fill that index file with some sample HTML code. For reference, here's mine:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Hello</title>
    <link href="css/style.css" rel="stylesheet" />
  </head>
  <body>
    <h1>Welcome to my site!</h1>
  </body>
</html>
```

After recompiling your code, you should see something like this in your browser. I haven't really looked into hot reloading Go programs, but it would be a great idea to have that to improve your development process.

![HTML Welcome](https://res.cloudinary.com/ta1da-cloud/image/upload/v1708161706/realm/tutorials/vite-react-go/welcome_sxytnu.png)

# Adding React

We are making progress, but we need this to be an SPA, not a static site.

I'm using `pnpm`, so let's initialize that.

`pnpm init`

We'll be using Vite as the bundler because it's _blazingly fast_. For starters, we want to ensure that we can actually read JS files from the front end, so let's include a script in our index.html.

```html
<script src="js/sample.js" type="text/javascript"></script>
```

I'm just going to console log some text in my JS file.

```jsx
console.log("Hey there!");
```

Now, we want to update our _server.go_ and how we are serving our static files. Instead of serving a single static file, we will be changing to a file server and directing that to our public directory.

```go
fs := http.FileServer(http.Dir("./public"))

http.Handle("/", fs)

log.Print("listening on port 8080...")
log.Fatal(http.ListenAndServe(":8080", nil))

```

Compile again and refresh your browser. You should see the same text, but if you open your console, there should be a surprise waiting for you.

![Console log](https://res.cloudinary.com/ta1da-cloud/image/upload/v1708161706/realm/tutorials/vite-react-go/walcome-console_yln89b.png)

Now, we install Vite and React with your preferred package manager.

`pnpm add vite @vitejs/plugin-react --save-dev`

`pnpm add react react-dom`

We need to configure Vite and add the react plugin and some instructions for when we build our web app for production. Create a _vite.config.js_ file and add this:

```jsx
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: {
    // generate .vite/manifest.json in outDir
    manifest: true,
    rollupOptions: {
      // overwrite default .html entry
      input: "resources/js/index.jsx",
    },
  },
  server: {
    origin: "http:127.0.0.1:8080",
  },
});
```

We need _App.jsx_ and _index.jsx_ files for React, so create those inside _resources/js_. The code in _index.js_ will search the HTML file for a component with the _’root’_ ID and inject the contents of our React app inside it.

```jsx
// index.jsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

```jsx
// App.jsx
import React, { StrictMode } from "react";
import ReactDOM from "react-dom";

function App() {
  return (
    <StrictMode>
      <div>
        <h1>Hello React!</h1>
      </div>
    </StrictMode>
  );
}

export default App;
```

According to the Vite guide on "_traditional_" backend integration, we need to use a custom configuration or use an existing integration from [Awesome Vite](https://github.com/vitejs/awesome-vite?tab=readme-ov-file#integrations-with-backends). I didn’t try the Go integration but it hasn’t been updated in over 2 years which, in JavaScript framework years, is an entire lifetime. In our case, we are using a custom config.

Update _index.html_ with the following code.

```html
<!-- if development -->
<script type="module" src="<http://localhost:5173/@vite/client>"></script>
<script
  type="module"
  src="<http://localhost:5173/resources/js/index.jsx>"
></script>
```

Above, in our _vite.config.js_ file, we also set _server.origin_. This will allow us to properly serve assets, and we can set this to the backend server URL, allowing the generated asset URLs to be correctly resolved.

We installed the Vite React plugin, but since it cannot modify the HTML file that we are serving, we added the following **before** the script tags above:

```html
<script type="module">
  import RefreshRuntime from "<http://localhost:5173/@react-refresh>";
  RefreshRuntime.injectIntoGlobalHook(window);
  window.$RefreshReg$ = () => {};
  window.$RefreshSig$ = () => (type) => type;
  window.__vite_plugin_react_preamble_installed__ = true;
</script>
```

This will allow our UI to dynamically update without recompiling the code.

We can update the _Makefile_ to also start the Vite server or build, depending on what we want.

```makefile
build:
	npm run build && go build -o bin/goreact

run:
	npm run dev & go run server.go

```

You can run `make run` or the command directly. We need the Vite server to be running alongside the Go server.

If you navigate to your browser, you should see something like this:

![Hello React](https://res.cloudinary.com/ta1da-cloud/image/upload/v1708161705/realm/tutorials/vite-react-go/Pasted_image_20240217104335_mihw5h.png)

And, you can update the code:

```jsx
<div>
  <h1>Hello React World!</h1>
</div>
```

And your code should be updated without the need to even refresh the page:

![Hello React World](https://res.cloudinary.com/ta1da-cloud/image/upload/v1708161706/realm/tutorials/vite-react-go/Pasted_image_20240217104437_kyvaw9.png)

# Limitations

This is a pretty cool set-up and I'll be exploring it a bit more to see if I can make any improvements.

The only limitation I have encountered so far is that, in my Laravel app, I was using [Tanstack router](https://tanstack.com/router/v1/docs/framework/react/quick-start), and I discovered that I can't directly open a page e.g. by entering `http://localhost:8080/about` because Laravel would try to handle that and discover that the page doesn't exist. However, I can still click a link in the web app and be successfully redirected. You could probably solve this with a dynamic route handler and some [regex](https://tawandamunongo.dev/posts/you-dont-know-regex), but I haven't explored that, yet.

For production, we would need to use Go's templating so that we can dynamically access the compiled assets from Vite. I might write something on how to deploy this to a cloud VPS, so let me know in the comments if that would be interesting.

# Conclusion

I hope you found this useful and informative. I decided that 2024 will be my _year of Go_, and aside from the Laravel project I am working on (and Laravel at work), it should be all Go from here on out. You can check out the [GitHub repo](https://github.com/tmunongo/react-vite-go) if you just want to see all the code. It will probably change along the way as I intend to make this a template for all my Go/React apps.

# Resources

- [Backend Integration - Vite](https://vitejs.dev/guide/backend-integration.html)
- [Templates - Go Web Examples](https://gowebexamples.com/templates/)
