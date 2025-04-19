---
title: AI-Powered Movie Recommendations with Go and HTMX
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1709882484/realm/tutorials/ai-movies-go-htmx/Screenshot_from_2024-03-05_08-27-12_eh9zob.png
tags: ["Tutorial", "Go", "HTMX"]
description: By the end of this, you should be able to build something similar that leverages the unmatched brilliance of Go on the backend, HTMX on the front end, and some AI trickery thanks to the OpenAI API to wow your users.
patreon: true
publishDate: 2024-03-08
---

# Introduction

I said in my [last post](https://tawandamunongo.dev/posts/go-react-vite) that I had no intention of getting caught up in the HTMX hype. While I have become quite disgruntled with React, it has served me well whenever I need to venture into the frontend. However, after a particularly unnerving bout of decision paralysis trying to pick out a state manager and router for an SPA that I’m working on, I decided to try HTMX and see what the fuss was all about.

It blew my mind.

# Some Background - What is HTMX?

[HTMX](https://htmx.org/) is the brainchild of the team behind [intercooler.js](https://intercoolerjs.org/). If, like myself, you are unfamiliar with intercooler.js, it was a frontend framework built to simplify AJAX interactions in web applications using _HTML attributes_. It allowed developers to add dynamic behaviour to their websites within familiar HTML-like syntax without writing complex JavaScript code.

For example, we can use the `ic-post-to` attribute to make an element perform an AJAX request when clicked.

```html
<a ic-post-to="/click">Click Here!</a>
```

HTMX (basically, intercooler.js 2.0) builds on the same ideas, bringing modern web features directly into HTML using attributes. Some of these modern web features include AJAX, CSS transitions, web sockets, and server-sent events without having to rely on JavaScript.

HTMX removes an existing limitation in HTML that only allows `a` and `form` tags to make HTTP requests. It offers a wide range of triggers beyond just click events that can be attached to any HTML tag and used to make HTTP requests. Just like React and other JavaScript frameworks, it allows page updates without triggering a full page reload. And, best of all, it does all this while coming in a much smaller bundle than React, reducing codebases by up to 67%.

To get started with HTMX, all you need to do is include the script in a plain HTML file and, for the example below, an API to handle the POST request to **/clicked**.

```html
<script src="<https://unpkg.com/htmx.org@1.9.10>"></script>
<button hx-post="/clicked" hx-swap="outerHTML">Click Me</button>
```

# Test-driving HTMX With a Simple Project

I dove straight into HTMX by building a simple, AI-powered web application. By the end of this, you should be able to build something similar that leverages the unmatched brilliance of Go on the backend, HTMX on the front end, and some AI trickery thanks to the OpenAI API to wow your users. You can follow along or check out the final code in the [GitHub repo](https://github.com/tmunongo/go-movies-htmx).

## Project Setup

We start by initializing a new Go project inside an empty directory.

```bash
mkdir go-htmx-tutorial && cd go-htmx-tutorial

go mod init github.com/<your_username>/go-htmx-tutorial
```

With your project initialised, create a `src` folder and then a `main.go` file inside that folder. There are better ways to structure a Go project, and I might explore that in detail in a future post. Create the rest of the files following the structure below:

```markdown
- go-htmx-tutorial
  - src
    - templates
      - index.html
      - styles.css
    - main.go
  - Makefile
  - .env
```

Start by creating a simple Go server. We will use the Go `html/template` library to serve our index.html. Go templates allow us to generate HTML output by executing a template against a data structure. `html/template` is preferred over `text/template` because it has built-in mechanisms to safeguard against certain attacks such as code injection.

```go
func main() {
  tmpl := template.Must(template.ParseFiles("src/templates/index.html"))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		err := tmpl.Execute(w, nil)
		if err != nil {
			log.Fatal(err)
		}
	})

	log.Print("Listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

We parse the HTML file in our templates directory, making sure to use the _template.Must_ helper. This is a wrapper that will allow our program to panic if _err_ is not nil when we parse the HTML file.

Our initial handler is fairly simple - we are not applying any data structure to the template, instead passing in _nil_ along with the customary error handling.

# Improved Routing

The recent Go 1.22 update made some interesting improvements to routing with the `net/http` package, but not quite enough to render libraries like Gorilla, Chi, and Echo obsolete just yet.

We want to avoid any confusion between our web and API routes by adding a **/api** prefix to all our API endpoints. For this, I will be using `[gorilla/mux](https://github.com/gorilla/mux)`, a versatile and powerful HTTP router for Go web applications. Add it to your project by running this command

```bash
go get -u github.com/gorilla/mux
```

Then, update the code in `main.go` by:

- creating an instance of the mux router
- creating a subrouter with the **/api** prefix
- registering a new route _/hello_ that should be automatically prefixed with _/api_

```go
func main() {
  r := mux.NewRouter()
  tmpl := template.Must(template.ParseFiles("src/templates/index.html"))

	apiRouter := r.PathPrefix("/api").Subrouter()

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		err := tmpl.Execute(w, nil)
		if err != nil {
			log.Fatal(err)
		}
	})

	apiRouter.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello, API!")
	})

	http.Handle("/", r)

	log.Print("Listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

After recompiling your code, navigate to _/api/hello_, and you should see the “Hello, API” response. Similarly, if you try to navigate to _/hello_, you should receive a 404 error because we do not have any handler set up for that URL path.

# Making an HTMX Request

Even better yet, instead of using Postman or Insomnia to test your API, let’s jump to the front end and use HTMX to query our API. We can achieve this by making a few small changes to our _index.html_.

Assuming you have the Emmet abbreviation HTML5 template ready, all you need to do is add the HTMX script to your _head_ tag and a button in the body that will make the request when clicked.

```html
<head>
  %% other code here %%
  <script src="<https://unpkg.com/htmx.org@1.9.10>"></script>
</head>
<body>
  <h1 id="greeting">Welcome</h1>
  <button hx-get="api/hello" hx-target="#greeting">Get greeting</button>
</body>
```

In the code segment above, we are making an HTTP GET request to our _/api/hello_ endpoint when the button is clicked using the _hx-get_ directive. The default behaviour would be to replace the button with the response content, but we can use the target directive to replace a specific element that we can target by its id.

![welcome image](https://res.cloudinary.com/ta1da-cloud/image/upload/v1709882527/realm/tutorials/ai-movies-go-htmx/Screenshot_from_2024-02-26_08-09-00_rchvlb.png)

Navigating to `http://localhost:8080`, you should see the welcome message and the button as shown above. After you click the button, the welcome message should be replaced by the response from the API.

![hello API message image](https://res.cloudinary.com/ta1da-cloud/image/upload/v1709882567/realm/tutorials/ai-movies-go-htmx/Screenshot_from_2024-02-26_08-09-09_cw1kks.png)

For more information about HTMX and what you can do with it, check out their extensive [documentation](https://htmx.org/docs/).

Building on this, we want to create a better UI that will allow us to input two lists of movies, submit them to the backend for processing, and then display a list of similar movies to those provided. We will be using Bootstrap because, in my experience, it is the fastest and easiest way to consistently style a website.

You can use the links below or head over to the [official site](https://getbootstrap.com/docs/5.3/getting-started/introduction/) for the latest version.

```html
<head>
	%% other code %%
    <link href="<https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css>" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
</head
<body>
    <script src="<https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js>" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous">
    </script>
</body>
```

The form below has two columns, each with three text inputs. When submitted, this form will make a post request to _/api/get-films_ using the **hx-post** directive and update the element with the id _result_ with the response data. Each input has a name attribute with its input number and column number, allowing us to parse the data correctly in the backend.

```html
<form id="combinedForm" hx-post="api/get-films" hx-target="#result">
  <div class="container mt-5">
    <div class="row">
      <h2 class="alert alert-info">
        Please input your and your friend's 3 favourite movies in each column
        and receive a list of movies that you will both enjoy! :)
      </h2>
    </div>
    <div class="row">
      <div class="col-md-6">
        <h3>Person 1</h3>
        <div class="mb-3">
          <input
            type="text"
            class="form-control"
            name="input1_column1"
            placeholder="Movie 1"
            required
          />
        </div>
        <div class="mb-3">
          <input
            type="text"
            class="form-control"
            name="input2_column1"
            placeholder="Movie 2"
            required
          />
        </div>
        <div class="mb-3">
          <input
            type="text"
            class="form-control"
            name="input3_column1"
            placeholder="Movie 3"
            required
          />
        </div>
        <input type="hidden" name="column" value="1" />
      </div>
      <div class="col-md-6">
        <h3>Person 2</h3>
        <div class="mb-3">
          <input
            type="text"
            class="form-control"
            name="input1_column2"
            placeholder="Movie 1"
            required
          />
        </div>
        <div class="mb-3">
          <input
            type="text"
            class="form-control"
            name="input2_column2"
            placeholder="Movie 2"
            required
          />
        </div>
        <div class="mb-3">
          <input
            type="text"
            class="form-control"
            name="input3_column2"
            placeholder="Movie 3"
            required
          />
        </div>
        <input type="hidden" name="column" value="2" />
      </div>
    </div>
    <div class="row mt-3">
      <div class="col-md-6">
        <button type="submit" form="combinedForm" class="btn btn-success">
          Submit
        </button>
      </div>
    </div>
  </div>
</form>
```

# Handling Movie Submissions

We need a handler that will receive these two lists of films, process them, and respond with a list of common movies. We can start with a handler that will receive the form data and respond with the supplied movie names and the column number, and then build on that.

```go
apiRouter.HandleFunc("/get-films", func(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	if err != nil {
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	// Process each input
	var inputs []Input
	for key, values := range r.Form {
		for _, value := range values {
			// Extract column number from the input name
			// Assuming input names are in the format "inputX_columnY" where X is the input number and Y is the column number
			// Split the key by underscore to get the input and column parts
			parts := strings.Split(key, "_")
			if len(parts) != 2 {
				// Skip this input if the format is invalid
				continue
			}
			// Extract the column number from the second part of the key
			column, err := strconv.Atoi(parts[1][len(parts[1])-1:])
			if err != nil {
				log.Fatal(err)
			}
			inputs = append(inputs, Input{Name: value, Column: column})
		}
	}

	fmt.Fprintf(w, "Your lists:\\n")
	for _, input := range inputs {
		fmt.Fprintf(w, "Movie Name: %s + Column: %d | \\n", input.Name, input.Column)
	}
}).Methods("POST")
```

The handler above starts by parsing the form. If there is an error, we respond with the error and immediately return.

If there is no error, we process each input into an array of inputs. Create the _Input_ type and then create a new _inputs_ variable.

```go
type Input struct {
	Name   string `json:"name"`
	Column int    `json:"column"`
}
```

Our nested for-loops will loop through each form value and then, from each form value, extract the name of the movie and the column number. Each input - the movie name and column number - will be appended to an array of inputs.

![image of form UI with API response](https://res.cloudinary.com/ta1da-cloud/image/upload/v1709882613/realm/tutorials/ai-movies-go-htmx/Screenshot_from_2024-03-01_08-43-25_h5zxq1.png)

This code will give a basic response with no styling showing our lists of movies and the column number. Each time you run this code, you will get the movies in a different order - a weird quirk of Go maps being inherently unordered such that each time we parse the form, we do not preserve the order of insertion.

# Adding Intelligence

As it stands, our site isn’t very smart so we should add some intelligence using the OpenAI API. At this point, we should probably move things around to improve the code organization. The last thing we need is a bloated main function.

We can extract the handler function for `/api/get-films` into a separate function with the same contents (which I will omit below for brevity).

```go
apiRouter.HandleFunc("/get-films", processFilmsHandler).Methods("POST")
```

We define a struct for the movie lists and create two empty slices to hold our movie titles. This will make it easier to pass them correctly to the OpenAI API.

```go
type MoviesList struct {
	List1 []string
	List2 []string
}

movies := MoviesList{
	List1: make([]string, 0),
	List2: make([]string, 0),
}
```

In our handler function, we want to replace the code that appends our movies to the inputs array with code that will append the movie titles into different lists based on the column numbers.

```go
if column == 1 {
	movies.List1 = append(movies.List1, value)
} else {
	movies.List2 = append(movies.List2, value)
}
```

We will use the two lists shortly, but, first, we must set up our application to connect with the OpenAI API. For that, you will need to create a key at https://platform.openai.com/account/api-keys. If your OpenAI is new, then you should have $5 free credit which is enough to make a few hundred requests to the API.

Once obtained, you can save your API key in your `.env`, making sure to add it to your `.gitignore` if you plan on pushing your code to a remote repo.

We also need to install the [Go OpenAI](https://github.com/sashabaranov/go-openai) library. This community-built library will allow us to interface with the OpenAI API.

```bash
go get github.com/sashabaranov/go-openai
```

In the handler function, get the API key from the path using the `os` package. Export your key to the path with:

```bash
export OPENAI_API_KEY=<your_key>
```

The key can be retrieved in Go using `os.Getenv`, and if there is no key we want to log an error.

```go
apiKey := os.Getenv("OPENAI_API_KEY")

if apiKey == "" {
	log.Println("No OpenAI API key found. Set the OPENAI_API_KEY environment variable.")
}

client := openai.NewClient(apiKey)
```

From here, we can build the query with the client.

```go
resp, err := client.CreateChatCompletion(
	context.Background(),
	openai.ChatCompletionRequest{
		Model: openai.GPT3Dot5Turbo,
		Messages: []openai.ChatCompletionMessage{
			{
				Role: openai.ChatMessageRoleUser,
				Content: fmt.Sprintf(`I will provide two lists of movies that two different people like.
				You must respond with a list of three different movies that both people would like in JSON format
				with the name of the movie and a percentage likelihood of both people liking them:
				List 1: %q
				List 2: %q

				common_movies: [
				   {
					 "name": <movie_name>,
					 "likelihood": <percentage>
					},
					{
					 "name": <movie_name>,
					 "likelihood": <percentage>
					},
					{
					 "name": <movie_name>,
					 "likelihood": <percentage>
					 }
				]`, movies.List1, movies.List2),
			},
		},
	},
)
```

Feel free to make improvements to the query if you fancy yourself a prompt engineer and leave that in the comments, let’s see if you can improve the results. Ideally, we also want to set the response format to JSON because the rest of our code assumes that the response is a JSON object.

# Processing and Displaying the Response

Let’s create a struct that will match the format of the expected response data.

```go
type Movie struct {
	Name       string  `json:"name"`
	Likelihood string `json:"likelihood"`
}

type Response struct {
	CommonMovies []Movie `json:"common_movies"`
}

```

After the customary error handling to check that `err` from our GPT query is empty, we unmarshal the response JSON into a variable of type **Response**.

```go
var response Response
err = json.Unmarshal([]byte(resp.Choices[0].Message.Content), &response)
if err != nil {
	fmt.Fprintf(w, "Error parsing chat response: %v", err)
}
```

We will be sending HTML back to the front end, and we can create a template with some Bootstrap styling that will be populated with the response data.

```go
const htmlTemplate = `
<div class="container mt-3">
	<div class="row">
		<div class="col">
			<h3>Common Movies</h3>
			<ul class="list-group">
				{{range .}}
					<li class="list-group-item">
						<strong>{{.Name}}</strong> - Likelihood: {{.Likelihood}}
					</li>
				{{end}}
			</ul>
		</div>
	</div>
</div>`
```

We will use the _template_ package to parse the template with the response data.

```go
tmpl, err := template.New("common_movies").Parse(htmlTemplate)
if err != nil {
	fmt.Println("Error parsing template:", err)
	return
}
```

In the last step, we use a string builder which is a great way of dynamically constructing large strings in Go. Using `strings.Builder` helps avoid potential bugs related to string manipulation and memory management as well as offering a more efficient and convenient way to construct strings.

```go
var builder strings.Builder
err = tmpl.Execute(&builder, response.CommonMovies)
if err != nil {
	fmt.Println("Error executing template:", err)
	return
}
```

Finally, we use the builder to write the constructed string into our response object.

```go
fmt.Fprint(w, builder.String())
```

We already set the target `(hx-target="#result")` in the form, and this is where our data will show up.

![final](https://res.cloudinary.com/ta1da-cloud/image/upload/v1709882484/realm/tutorials/ai-movies-go-htmx/Screenshot_from_2024-03-05_08-27-12_eh9zob.png)

# Conclusion

From a back-end developer’s perspective, that was pretty easy. We can build modern, dynamic websites without the need to write complex JavaScript or use frameworks like React. We can extend this further with Alpine.js, another minimalist front-end tool that I’ve been playing around with.

I hope you enjoyed working through this as much as I did. If you have any questions or feedback, you can leave a comment below or reach out to me on [Mastodon](https://mastodon.social/@ta1da). If you loved this, sharing is caring. Until the next one, happy hacking!
