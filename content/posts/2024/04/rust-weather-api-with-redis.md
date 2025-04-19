---
title: Unlocking Speed - Rust Weather API with Redis Caching
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1712389527/realm/tutorials/rust-weather-api-with-redis/2_ptg6fa.png
tags: ["Tutorial"]
description: In this one, we use Rust to build a wrapper around a public weather API then add caching with Redis for blazing fast performance and to save up on API credits.
publishDate: 2024-04-06
---

# Introduction

One of the biggest revelations that I have had this year is that there is more to building high-performance web applications than just picking a 'fast' language. I have been using Go and Rust in my side projects, and both have pushed me to think more about how I can optimize my web applications. One of those techniques, which we will explore here, is caching.

For this tutorial, I decided to go with something relatively easy to build with the goal of demonstrating caching in probably its simplest form. We will build a wrapper API for a public weather API, using caching to limit requests to the API (some APIs charge us per request) and improve response time by avoiding the second network request where possible. We will also go with a rather simplistic implementation of cache invalidation by keeping cached items for an hour or more based on the assumption that the weather often does not change dramatically within that time.

We will be using Rust in this tutorial, and some Rust knowledge will be assumed. If you're not already familiar, I would recommend starting with [**the book**](https://doc.rust-lang.org/book/).

## Redis

As we will be using Redis, it's best to give a short introduction to what it is and what it has to offer. For a more detailed intro, I recommend...

Redis is an in-memory key-value store. The first part is important here because, instead of having to rely on slower disk reads, Redis allows us to store frequently accessed data in memory where that data can be accessed almost instantly. This can significantly improve our web app's performance by avoiding frequent slow database reads or HTTP requests, which is especially useful when building microservices.

# Let's Build

We start by creating a new directory for our project. Name it whatever you want, and then `cd` into the directory.

```bash
mkdir <project_name>
cd <project_name>
# run to initialize a new rust binary project
cargo init
```

## Crates

We will be using a bunch of crates, so it's best to have them installed now. We will need:

- Axum: our web framework
- Redis: Rust Redis crate
- bb8: For pooling Redis connections
- Tokio: an async runtime
- Reqwest: for making HTTP requests
- Dotenvy: for importing environment variables from a _.env_ file

```bash
cargo add axum bb8 bb8-redis dotenvy tracing serde_json
cargo add redis -F json
cargo add reqwest -F json
cargo add serde -F derive
cargo add tokio -F rt,rt-multi-thread
cargo add tokio-test
```

## A Simple Server

We will start by making a simple API to listen for and handle HTTP request. Update _src/main.rs_ with the following and then run `cargo run` in your terminal.

```rust
use axum::{
	http::StatusCode, routing::get, Router
};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() {
	let app = Router::new()
		.route("/", get(index))
		.route("/health", get(|| async { StatusCode::OK }));

		let listener = TcpListener::bind("127.0.0.1:3000").await.unwrap();
		println!("listening on {}", listener.local_addr().unwrap());
		axum::serve(listener, app).await.unwrap();
}



async fn index() -> &'static str {
	"Hello World"
}
```

In the code above, we register two routes on **/** and **/health**. The async function _index_ will handle requests to the **/** endpoint, while the **health** endpoint will simply return a _200 response_ to show that our server is running as expected.

The next steps involve declaring a listener on localhost and port 3000, and then serving the app with _axum_. Testing our server with _ThunderClient_ shows that everything is working.

![Hello World](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1712329923/realm/tutorials/rust-weather-api-with-redis/Pasted_image_20240403074919_yl62av.png)

## Making Weather Requests

We will need access to a weather API for this tutorial. I recommend [Weather API](https://weatherapi.com) - they have a two-week free trial of their _Pro Plus_ plan and a generous free tier. Plus, they don't ask for your credit card details which is always a green flag for me. You can visit their website, create an account, and return to this once you've obtained an API key.

In our routes definition, we are going to add a new route to handle weather requests. To keep it simple, we will only be retrieving the current weather for a given city.

```rust
.route("weather/:city", get(city_weather))
```

The **city_weather** function will accept the _city_ name path variable which we will use to construct the request URL. We will need the API key which, for now, you can temporarily export to your path:

```bash
export WEATHER_API_KEY=<your_key>
```

and then access it in the code:

```rust
async fn city_weather(Path(city): Path<String>) -> String {
    let api_key = env::var("WEATHER_API_KEY").expect("WEATHER_API_KEY must be set");

    let request_string = format!("https://api.weatherapi.com/v1/current.json?key={}&q={}&aqi=no", api_key, city);

    let response = reqwest::get(request_string)
    .await
    .unwrap();

    let body: WeatherResponse = response.json::<WeatherResponse>().await.unwrap();

    format!("Weather for {:?}", body)
}
```

You may be wondering why we need to await twice - the first one gets the _HTTP header_ (not to be confused with the _HTTP headers_), and the second one will get the body.

> For a more detailed exploration, check out [RFC9112](https://httpwg.org/specs/rfc9112.html#message.format)

The second thing is that we are parsing the JSON body of the response into a **WeatherResponse** struct, so we can go ahead and create that, now:

```rust
#[derive(Serialize, Deserialize, Debug)]
struct WeatherResponse {
	location: Location,
	current: Current,
}
```

We can use Weather API's [Interactive API Explorer](https://www.weatherapi.com/api-explorer.aspx) to see the shape of the response in the browser first. The JSON response contains two objects: _location_ and _current_, with details about the location and its current weather, respectively.

We can also create the structs for those:

```rust
#[derive(Debug, Deserialize, Serialize)]
struct Location {
    name: String,
    region: String,
    country: String,
    lat: f64,
    lon: f64,
    tz_id: String,
    localtime_epoch: i64,
    localtime: String
}

#[derive(Debug, Deserialize, Serialize)]
struct Current {
    last_updated_epoch: i64,
    last_updated: String,
    temp_c: f32,
    temp_f: f32,
}
```

Our structs will need to derive the `Serialize`, `Deserialize`, and `Debug` traits. That allows instances of our types to be easily serialized and deserialized, and provides a human-readable output for debugging.

Again, we can test that in _ThunderClient_:

![Manchester Weather](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1712389635/realm/tutorials/rust-weather-api-with-redis/Pasted_image_20240403082256_b9hqdt.png)

The reported response time is just over a second. **1.03** to be exact. I also tested it with _oha_ and got a average response time of about _0.74s_, with the slowest request taking almost 2 seconds.

![Oha Test No Cache](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1712329859/realm/tutorials/rust-weather-api-with-redis/Pasted_image_20240327083513_od72bp.png)

That's not bad, but also great.

## Adding Caching

The big assumption that we will be making here is that over a given period, specifically an hour, the weather will not change too much. That means we can get away with showing mildly stale weather without _really_ inconveniencing the user. Right? I'm sure all the weather apps do it. We can always reduce it if we get complaints.

With that **disclaimer** out of the way, let's add Redis.

You should already have the necessary crates installed to connect to Redis. You will need to have Redis running. Usually, I just spin up a Docker container for that, and you can find the **docker-compose.yml** in the [GitHub repo](https://github.com/tmunongo/weather-api-rust), or just run:

```bash
docker run -d -p 6379:6379 --name redis -v ./redis-data:/data redis:7-alpine
```

We will use _dotenvy_, now, to access environment variables from our _.env_ file.

```rust
async fn main() {
	dotenv().expect("Failed to load .env file");

	let redis_url = env::var("REDIS_URL").expect("REDIS URL must be set!");

	tracing::debug!("connecting to redis");
	let manager = RedisConnectionManager::new(redis_url).unwrap();
	let pool = bb8::Pool::builder().build(manager).await.unwrap();

	{
		// ping the database before starting
		let mut conn = pool.get().await.unwrap();
		conn.set::<&str, &str, ()>("foo", "bar").await.unwrap();
		let result: String = conn.get("foo").await.unwrap();
		assert_eq!(result, "bar");
	}
	tracing::debug!("successfully connected to redis and pinged it");

	// the rest of your main fn
}
```

In this code, we are creating a connection pool and testing it by adding a test entry to our key-value store and retrieving its value.

Once we have verified that everything is working, we can add the pool into our routing state so that it is accessible inside the handlers.

```rust
	.with_state(pool);
```

We will update our route handler to check if they _city name_ key exists in Redis. If the key is found, we just get the value (which should be the _WeatherResponse_ struct JSON as a string), deserialize the string into JSON with _serde_json_, and return it. Otherwise, if the key is not found then we must query the API, cache the retrieved info, and return it.

```rust
async fn city_weather(State(pool): State<ConnectionPool>, Path(city): Path<String>) -> String {
    let api_key = env::var("WEATHER_API_KEY").expect("WEATHER_API_KEY must be set!");

    // check redis for the weather data
    let mut conn = pool.get().await.unwrap();
    let cached_weather = conn
        .get::<String, Option<String>>(city.as_str().to_owned())
        .await
        .unwrap();

    let body: WeatherResponse;

    if cached_weather.is_some() {
        return format!(
            "Weather for {} was retrieved from cache: {:?}",
            city,
            serde_json::from_str::<WeatherResponse>(&cached_weather.unwrap()).unwrap(),
        );
    } else {
        let request_string = format!(
            "https://api.weatherapi.com/v1/current.json?key={}&q={}&aqi=no",
            api_key, city
        );

        let response = reqwest::get(request_string).await.unwrap();

        body = response.json::<WeatherResponse>().await.unwrap();

        let cached_body = conn
            .set_ex::<&str, String, Option<String>>(
                &body.location.name.to_ascii_lowercase(),
                serde_json::to_string(&body).unwrap(),
                3600,
            )
            .await
            .unwrap();

        match cached_body {
            Some(cached) => {
                return format!(
                    "Weather for {} was cached as {:?}",
                    body.location.name,
                    cached
                )
            }
            None => return format!("Weather for {} was not cached", body.location.name),
        }
    }
}
```

Above, we have the updated _city_weather_ function. In this function, we first check the key for the given city name in our cache. If the key already exists, then we can just retrieve the value and use that as our API response.

![Cached Harare Weather](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1712329857/realm/tutorials/rust-weather-api-with-redis/Pasted_image_20240403083737_wgofeu.png)

Look at how much faster our response time is - _5ms_ down from just over _1s_.

Testing again with _oha_, the numbers are worlds apart.

![Cached Oha Benchmarks](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1712329862/realm/tutorials/rust-weather-api-with-redis/Pasted_image_20240405083545_nxx7gd.png)

We go up from just over 50 requests/sec to almost 3000 requests/sec.

> Of course, as with all benchmarks, take them with a pinch of salt.

We also set a TTL (time-to-live) of 1 hour so that cached entries are automatically cleared, allowing us to, at least, keep our data somewhat up-to-date.

## Extra Credit

For now, our API just returns a string dump of all the weather data, which I think we can improve on by returning the data in JSON format.

Our first change is updating the handler's return value:

```rust
async fn city_weather(State(pool): State<ConnectionPool>, Path(city): Path<String>) -> Result<Json<WeatherResponse>, String> {
// function body
}
```

Our JSON response is expected to take the `WeatherResponse` form, or we can return an error string. We can always create a custom return struct if we plan on adding or removing some data from the response.

The values in our key-value store also take the same shape, so we can specify the type when we _get_ the data from Redis:

```rust
let cached_weather: Option<WeatherResponse> = conn.get::<String, Option<WeatherResponse>>(city.as_str().to_owned()).await.unwrap();
```

Here, we encounter our first issue because `conn.get` and `conn.set` only implement the trait `FromRedisValue` for standard Rust types but not for our custom `WeatherResponse` type. So, we need to write our own implementation of `FromRedisValue` for the `WeatherResponse` type.

```rust
impl FromRedisValue for WeatherResponse {
    fn from_redis_value(v: &redis::Value) -> RedisResult<Self> {
        match v {
            redis::Value::Data(data) => {
                let json_str = std::str::from_utf8(data).expect("Invalid UTF-8 data in Redis");
                let weather_response: WeatherResponse = serde_json::from_str(json_str).expect("Failed to deserialize JSON");

                Ok(weather_response)
            }
            _ => Err(redis::RedisError::from((redis::ErrorKind::TypeError, "Invalid Redis value type for WeatherResponse")))
        }
    }
}
```

In our implementation, we check if the Redis value is of type Data. We assume that the stored data is of type `WeatherResponse` (and, hopefully it shouldn't ever be stored if it is not), and deserialize it using **serde_json**. We can return an error if the Data is not of the type `WeatherResponse`. With this implementation, we can convert our `WeatherResponse` to and from Redis values.

Next, we check if `cached_weather` contains any data, in which case, we simply deserialize it to JSON, which we can do because our `WeatherResponse` implements `serde::de::DeserializeOwned`.

```rust
if cached_weather.is_some() {
        return Ok(Json(cached_weather.unwrap()));
}
```

In the _else_ block, we will return the body as a JSON object. However, we want to clone the body so that we can keep the original body unchanged. That means we will have to add the `Clone` trait to the derive macro for `WeatherResponse`, `Location`, and `Current`.

```rust
#[derive(Serialize, Deserialize, Debug, Clone)]
```

You can find the full, final code in the [GitHub repo](https://github.com/tmunongo/weather-api-rust) for this tutorial.

## Conclusion

We saw here how we can use caching to optimize our web applications to achieve greater performance. The beauty is that this doesn't just apply to Rust. You may think that you need to use the "fastest" language to build blazingly fast web applications, but sometimes the right optimization techniques can boost your applications, regardless of your language/framework of choice.

I'm curious to hear from you all if there are any improvements that can be made here since I am nowhere close to being a Rust expert. I'll also leave it up to the reader to find out how we can avoid caching every city and maybe prioritizing the most frequently requested cities.

If you have any questions, comments, or suggestions, the comment section is below, and my [Mastodon](https://mastodon.social/@ta1da) is open. Get in touch, let's chat. Otherwise, never stop learning.

## Resources

- [The HTTP Crash Course Nobody Asked For - fasterthanlime](https://fasterthanli.me/articles/the-http-crash-course-nobody-asked-for)
- [Tutorial on Rust Redis - Tools and Techniques - Squash.io](https://www.squash.io/tutorial-on-rust-redis-tools-and-techniques/)
