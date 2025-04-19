---
title: You Don't Know Regex - Elevating a Laravel API with Regular Expressions
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1704869973/realm/covers/email-regex_kmlci6.jpg
tags: ["Tutorial", "PHP", "Laravel"]
description: As a new dev, most of what you'll hear about regex is bad. Let's try to change that.
publishDate: 2024-01-10
updated: 2024-01-21
---

# Introduction

Regular expressions, often shortened to _regex_, are patterns used to match character combinations in strings. They are useful for searching and manipulating text strings. Regular expressions are widely supported, from scripting to general-purpose programming languages and by word processors.

While my first encounter with regex was in college when I had to build a simple compiler in Java, I did not have any subsequent encounters with them until recently, when I discovered how important they are to me as a backend developer. The ability to define and interpret complex patterns allows us to create flexible and dynamic routing systems, making our APIs more functional and adaptable. Some of the other benefits that I will explore here are:

- Dynamic Routing and Variable Endpoint Structures
- Pattern Validation for Data Integrity
- Efficient Handling of Variable Segments
- Scalable Versioning and Parameterized Endpoints
- Conditional Routing Based on Input Characters
- Reducing Redundancy in Route Definitions

In this article, we will build a simple Laravel API, applying our newly acquired regex knowledge to enable powerful endpoint pattern matching in our application.

## Introducing Regular Expressions

The best place to start is by introducing the basic syntax and concepts behind regex. If you are already familiar with it, you can skip to the next session.

The first thing to note is that characters can match themselves or be special regex characters with special meanings. For example, regex _[x]_ matches substring _'x'_. To match a special regex character, we must use the escape sequence prefix (\\ char).

Escape characters allow us to use shortcuts as prescribed by the regex syntax. For example, _\d_ escapes "d", which would ordinarily match the character d and, instead, matches any single digit. It is equivalent to the class [0-9]. Likewise, we can use _\D_ to match any single non-digit. Similarly, _\s_ will match any single whitespace character, including a space, a tab, or a newline and _\w_ will match any single world character, alphanumeric, or underscore. The _\w_ regex is equivalent to [a-zA-Z0-9_].

### Operators

This is good and all, but for most real-world use cases, it is unlikely that we will find ourselves matching single characters. If we want to do anything meaningful with regular expressions, we must turn to operators.

Regex operators allow us to add logic to our regular expressions, allowing them to do more. We will explore some of the most commonly used operators and what they do.

- **OR {|}**: the OR operator will match any of the provided expressions, e.g. [six | 6].
- **{+}**: matches one or more of the preceding elements. E.g. [ab+c] matches abc, abbc, abbbc, etc. This can also be combined with other regex, e.g. [\d+] will match one or more digits.
- {\*\*}: indicates one or more of the preceding elements, i.e. [ab**c] matches ac, abc, abbc, etc.
- **{?}**: indicates 0 or 1 of the preceding element, e.g. [ab?c] matches ac and abc.
- **{mix, max}**: indicates between min and max occurrences of the preceding character, class, or sub-pattern.
- [ ] **[ ]**: known as a bracket list. It matches any one of the characters within the square bracket. E.g. [xyz] matches "x", "y", "z".
- **[.-.]**: known as the range expression. It will accept any one of the characters in the range, e.g. [0-9] matches any digit.
- **{^} anchor**: ties the pattern at the beginning of the search string. E.g. `^abc` matches _abc123_ but not _123abc_.
- **{\$} anchor**: ties the pattern at the end of the search string. E.g. `abc$` matches _123abc_ but not _abc123_.

### Common Use Cases

As I have mentioned, regular expressions are a very important tool for one to have in their programming toolbox. They have many uses, including:

1. Data Validation
   - We can use them to ensure user inputs adhere to specific formats or constraints. Some examples include email addresses, ZIP codes, credit card numbers, etc.
2. Text Search and Extraction
   - For example, we can extract hashtags from a social media post or find URLs in a document using regex patterns.
3. Parsing and Tokenization
   - We can break down text into meaningful tokens or extract structured information. This is useful in natural language processing or extracting data from text files.
4. Code Analysis and Refactoring
   - For example, we can identify and refactor variable naming conventions or search for specific coding patterns using regex.
5. URL Routing and Rewriting
   - As we will see later, we can route requests to different controllers based on URL patterns or rewrite URLs for SEO-friendly routes.

This list is by no means exhaustive. There are so many more uses for regular expressions across various domains. They provide solutions to diverse programming challenges, making them invaluable for text manipulation and validation tasks.

# The Power of Regex in API Design

If, like me, you have done most of your API development with backend frameworks that offer built-in routing, you might have never given much thought to how URL patterns are matched. This changed when I tried using Go's std library for API development. After that, I decided to take some of the lessons I had learned from Go and apply them to different frameworks.

Traditional approaches to API design often involve static route definitions, which may not be optimal for scenarios where endpoints exhibit dynamic and complex patterns. As we will see later, they also provide a means to validate our endpoints to ensure that input parameters adhere to our expectations.

Using regex, especially as our endpoints become more complex, may provide more precision and flexibility and allow us to build more robust and effective APIs. What we end up with is a more versatile solution to endpoint matching.

### Flexibility

As our APIs grow in size and complexity, it becomes increasingly important for our routes to be flexible and match a range of possibilities. This is important when dealing with dynamic parameters such as IDs, date formats, or language codes. In such cases, we can use a regex pattern to match and handle requests to different versions like `/api/v1/resource` and `/api/v2/resource`.
If we were to use explicit route definitions for each version, this would lead to code redundancy (remember **DRY**) and potential maintenance challenges.

A regex pattern like `/api/v(\\d+)/resource` captures all version variations (_v1_, _v2_, etc.) with elegance, simplifying the code base and reducing the risk of errors associated with manual route management.
We can do the same when supporting different languages. Instead of defining separate routes for each language, regex can save us the trouble. A regex pattern such as `/api/(?P<lang>\\w+)/resource` accommodates language preferences dynamically. This flexibility is especially useful when the API needs to handle requests like `/api/en/resource` or `/api/es/resource`.

### Dynamic and Complex Routing

Things become even more interesting when our routes have optional query parameters. Normally, we would have to manage numerous state variations to handle optional query parameters. Instead, we can handle these gracefully with a regex pattern like `/api/resource(\\?.*?)?`, allowing the API to process requests with or without additional parameters.

# Regex in Practice with Laravel

As a newcomer in the web development space in the last five years, one thing you will hear, especially within the JavaScript community, is the level of disdain the community has for PHP. It is widely seen as the old, uncool language that has become a relic of the past. Yet, what you'll find in reality is a vibrant PHP community using powerful, elegant frameworks like Laravel to build fast and modern web applications that are just as good as anything built with the _'cool'_ tools. On top of that, Laravel comes with a rich ecosystem of tools to make everything from SPA integration (Inertia), authentication (Sanctum), and deployment (Vapor) a breeze (pun intended).

The best part is that I have not mentioned my two favourite things about Laravel - the CLI tool (Artisan) and the directory structure. One of the things you will often find yourself obsessing over with most JS frameworks is directory structure (at least NestJS tries to rectify this). With Laravel, all of that is taken care of by Artisan. It is a CLI tool that allows us to automatically create controllers, models, database migrations, etc., and have them all organized. A bare-bones Laravel application includes a folder structure that provides all the structure you will need to build your application without worrying about its scalability and maintainability should the number of contributors grow. And, because this structure is universal, you can expect roughly the same structure in any Laravel application you will ever work with.

# Setting Up a Laravel Project

If you already have PHP and Composer installed on your machine, setting up a basic Laravel project is as simple as:

```bash
composer create-project laravel/laravel <your-app-name>
```

You can also use [Laravel Sail](https://laravel.com/docs/10.x/sail), which is what I will be using. It provides a Docker-powered local development experience for Laravel that is compatible with macOS, Linux, and Windows (WSL2).

```bash
curl -s "<https://laravel.build/example-app?with=mysql,redis>" | bash
```

As you can see, the _`with`_ query parameter allows us to supply a list of services to be included as part of our docker-compose. For this tutorial, we will only need MySQL.

# Routing in Laravel

Before we go any further, we must briefly explore Laravel's routing system. If you are familiar, you can also jump to the next session.

In their most basic form, Laravel routes include a method, URI, and closure.

```php
use Illuminate\\Support\\Facades\\Route;

Route::get('/greeting', function () {
	return 'Hello World';
})
```

As mentioned earlier, Laravel provides a foundation that relieves us of the need to make directory structure decisions.

![Routes Folder](https://res.cloudinary.com/ta1da-cloud/image/upload/v1704780605/realm/tutorials/you-dont-know-regex/Pasted_image_20231211090145_jgmdqu.png)

In our project root, we will find a directory called **routes**. This is where all our routes will be stored. The _web.php_ file in this directory is where our web interface routes are defined, and _api.php_ is for our API routes. The latter is automatically assigned to the API middleware group and given the _/api_ prefix. This can be changed to meet your specific project needs, but that is beyond the scope of our exploration today. Finally, our routes can be assigned an HTTP verb: GET, POST, PUT, DELETE, etc., as we already saw above.

There is so much more to routing in Laravel that you can read about [here](https://laravel.com/docs/10.x/routing).

# Laravel Project cont.

Now that we have a basic understanding of how routing works in Laravel, we can use what we have learned to build a simple blog API.

If you're already familiar with Laravel, you know it follows the MVC pattern. This means that we must create our models and controllers. We will not have any views for this demonstration.

As mentioned earlier, one of my favourite aspects of Laravel is the **artisan** CLI tool. We can use it to create a new model with, for example, an accompanying controller, factory, seeder, and even a database migration.

```bash
php artisan make:model --api -cfsm User
```

You can run `php artisan make:model --help` to get a list of other available flags for this command.

One of the options passed into the command above (**-m**) makes a new migration. This is stored in 'database/migrations' under a name such as 'create_users_table'. Laravel's migrations are useful because they allow us to keep track of how our database changes and ensure consistency, especially when working in a team. It's like version control for our database.

According to the [Laravel docs](https://laravel.com/docs/10.x/migrations), _"A migration class contains two methods: `up` and `down`. The `up` method will add new tables, columns, or indexes to your database, while the `down` method should reverse the operations performed by the `up` method."_ We can use the Laravel Schema builder to create our `Post` table by _adding_ the following lines to the existing schema:

```php
$table->string('title');
$table->string('slug');
$table->string('category');
$table->longText('content');

```

After that, we can define our routes in the `api.php` file in the `routes` folder. We want to create a route to retrieve a list of posts from our database. We will use Route-Model binding to automatically inject the model instances into our controller instead of manually querying the DB with, for example, the given ID. We will need to have some posts in our database to retrieve anything. For that, we will use Laravel's Factories and Seeders to generate some posts and store them in our database.

After checking our `.env` and ensuring that the right variables are set to allow our application to connect to the database, we create a seeder that uses a factory to generate and store post data in our database. Here, we will get our first taste of using regex in our application.

```php
// PostSeeder.php
public function run(): void
{
	Post::factory()->count(10)->create();
}

```

The **factory** method on our post model allows us to get a new factory instance for the model. This factory is a class that extends Eloquent ORM’s default factory class. This class contains a definition method which returns attribute values that will be applied when creating a model using the factory. This allows us to provide guidelines on what kind of data should be provided for our model.

```php
// PostFactory.php
return [
            //
            'title' => fake()->sentence(3),
            'slug' => fake()->regexify('^[a-z]{4}(-[a-z]{4}){2}$'),
            'category' => fake()->randomElement(['Programming', 'Design', 'Marketing', 'Writing']),
            'content' => fake()->text(),
];

```

The **regexify** method on fake gives our factories access to the Faker PHP library and allows us to generate strings that conform to the structure provided via a regular expression. In our case, we need our slug to look like a sentence with the spaces replaced by hyphens, e.g. "**this-is-a-slug**", which can be defined with the regular expression `{[a-z]{4}(-[a-z]{4}){2}$}`. For the sake of the example, each word will be four letters long.

With the post seeder and factory prepared, update the _DatabaseSeeder.php_ file and add a line to call our **PostSeeder** class.

![PostSeeder Class](https://res.cloudinary.com/ta1da-cloud/image/upload/v1704781804/realm/tutorials/you-dont-know-regex/Pasted_image_20231219083734_qiuz9h.png)

If you are using Docker, you can check the hash for your sail container before running the command to migrate the database and seed.

```bash
docker ps

docker exec <container hash/name> php artisan migrate:fresh --seed
```

## Endpoint Matching

To verify that our database has been seeded correctly, we can check the database directly in PHPStorm, with a client like _DBeaver_, or we can start working on our endpoints to handle requests to the API.

We have already established that we can use regex to define the structure of elements such as slugs, IDs, etc. Laravel has powerful, built-in mechanisms that allow us to use pattern matching for our API endpoints. We can use the _where_ method to put constraints on our route parameters. This method accepts the name of the parameter and the regular expression.

```php
Route::get('/post/{post}', [PostController::class, 'show'])->where('post', '[0-9]+')

```

Since we use route-model binding, our parameter name is just _'post'_. Laravel will automatically match this to the Post ID or any other column. This can be specified in the parameter, e.g. **{post:slug}** to look up a post by the slug and inject the model into our controller. The code above shows a route that will only accept numerical post IDs. If the supplied parameter is not found, Laravel will automatically return a 404 response for us.

Adding this kind of validation to our application can be helpful in situations where our routing may have conflicts (which may be a sign of poor API design, but let's go with it for now). Let's say we have this route:

```php
Route::apiResource('posts', PostController);
```

The _apiResource_ route is a convenient way to define RESTful resource routes for our API. This will automatically handle routes for CRUD operations for the given resource controller. This route handler will match the URI `/api/posts/{post}`. What, then, will happen if we want to add another route like:

```php
Route::post('posts/deleteMany', ['PostController::class', 'deleteMany']);

```

Laravel will try to match _'deleteMany'_ as a Post ID. When this happens, our query will return a 404 response every time, and we may get an error that "deleteMany is not a valid Post ID".

We can fix this by adding validation to the API resource route to accept the parameter only when it matches the given regex.

```php
Route::apiResource('posts', PostController::class)->where(['post', '[0-9]+']);

```

## Optional Parameters

Similarly, we can use regex to define optional route parameters, allowing us to create more flexible and dynamic routes.

Suppose you want to create a route that accepts an optional language parameter in the URL. The language is specified by a two-letter code, and if it is not provided, the default language is used. If you're following along, you can add this code to your `web.php` file and test it.

```php
Route::get('page/{slug}/{language?}', function($slug, $language = 'en') {
	// routing logic here
	return "Slug: $slug, Language: $language";
})->where([
	'slug' => '[a-z-]+',
	'language' => '[a-zA-Z]{2}'
]);

```

With this code, if I tried to navigate, for example, to `[localhost/page/about-us](http://localhost/page/about-us)/fra`, I would get a 404 error because _"fra"_ does not match the required 2-letter language code. Similarly, I can navigate to `localhost/page/about-us` without getting a 404 error because the default language is applied.

At this point, I must confess that Laravel makes this almost all irrelevant (in a good way). That's because it provides built-in functions for many commonly used regular expressions, which means that, for the most part, we don't need to write the regular expressions. For example, if we had a **User** model whose ID is a UUID, we could validate it using the built-in **whereUuid** method, telling our route handler to expect the ID to be a UUID.

```php
Route::get('/users/{id}', ['UserController::class', 'show'])->whereUuid('id');
```

# Why Use Regex?

There are many reasons to use regular expressions in our API development. One of my favourite mantras for building public-facing APIs and software is that we must always treat user input as untrustworthy. In this case, untrustworthy doesn't always mean malicious - it can also just mean that your users may not follow the guidelines that you have defined for your system. What happens if a user directly inputs this in their browser `https://www.<your_site>.com/api/users/123` when your API expects all users to be identified by usernames that may be alphanumeric with numbers only at the end? Your system should be prepared to handle such edge cases, and regular expressions give us the means to do that.

Some other reasons to use regular expressions:

**Expressive**: regex patterns express complex routing logic concisely, making the code more readable and maintainable.

**Scalability**: pattern matching with regular expressions allows us to accommodate new endpoints without extensive modifications.

**Maintenance**: often easier to maintain than static routes, especially in scenarios with numerous variations.

**Adaptability**: they can adapt to changing requirements, reducing the need for constant updates to route definitions.

## Tips and Best Practices

If you're building a web application with Laravel, the best tip I can give you is to use the tried-and-tested built-in methods where they are applicable. It will save you from potentially shooting yourself in the foot while defining regular expressions for patterns already covered by the framework.

If, however, you're not using Laravel, there are a few things to pay attention to:

- **Be specific**: avoid overly general patterns that may match way more than you intended.
- **Document your patterns**: document the purpose and expected input of each pattern - this will help you or anyone who may work on the project in the future.
- **Use anchors for exact matches**: _$_ and _^_ will help you to avoid unintended partial matches.
- **Test rigorously**: Test with many inputs. Use online testers. Anything. Test until you're sure you won't have unintended wrong matches, then test some more.

# Conclusion

In conclusion, the power of regular expressions (regex) in API development cannot be overstated. We explored the fundamentals of regex, basic syntax, operators, and use cases. We established how understanding regex enables devs to harness its capabilities for endpoint matching in API design. We built a simple Laravel application to show how the framework's routing system integrates seamlessly with regex. Laravel's expressive routing methods and built-in constraints simplify endpoint pattern matching, reducing the need for manual regex implementation.

If you have any thoughts or feedback, you can reach out to me on [Mastodon](https://mastodon.social/@ta1da) or checkout my [GitHub](https://github.com/tmunongo).

# References

- [Regex Tutorial - NTU](https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html)
- [Basic Regex Operators](https://docs.hytrust.com/CloudAdvisor/2.2.0.0/Online/Content/Admin-Guide/3_Discover/Insight-Management/Tags/Basic-Regex-Operators.html)
- [Routing - Laravel](https://laravel.com/docs/10.x/routing)
- [Eloquent Factories - Laravel](https://laravel.com/docs/10.x/eloquent-factories)
- [Introduction to Regular Expressions - O'Reilly](https://www.oreilly.com/content/an-introduction-to-regular-expressions/)
