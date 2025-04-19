---
layout: ../../layouts/PostLayout.astro
title: Modern Database Interactions in PHP
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1697806076/realm/essays/MySQL_logo_logotype_1_mnlbah.png
tags: ["Programming"]
description: I will explore the dangers of persisting with the ext/mysql API. I will provide a detailed analysis of the weaknesses of the original API, showing along the way how to perform an SQL injection attack (for educational purposes) on a poorly secured site, and how to migrate to the new APIs and keep your users’ data away from prying eyes.
publishDate: 2023-10-20
---

# Introduction

Since the dawn of the public internet, web applications have been at the core of our internet experience. As these web tools have become increasingly connected to critical aspects of our lives, there has been a greater need to make them fast and secure. Websites constantly interact with databases to store and retrieve user information. One of the most popular databases, widely used within the PHP community as part of the famous **LAMP** stack, is MySQL. For a long time, the dominant method for this interaction was the `mysql_query` function which is part of the original MySQL API (`ext/mysql`).

Relying on this API, however, can pose significant security risks for a website, leaving it vulnerable to exploits like SQL injection attacks. As I have encountered remnants of this function in my work and seen its weaknesses first-hand, I will explore the dangers of persisting with the `ext/mysql` API. I will provide a detailed analysis of the weaknesses of the original API, showing along the way how to perform an SQL injection attack (for educational purposes) on a poorly secured site, and how to migrate to the new APIs and keep your users’ data away from prying eyes.

# The Dangers of `ext/mysql`

If you open the PHP manual page for [mysql_query](https://www.php.net/manual/en/function.mysql-query.php), you will be greeted by a warning telling you that the function is deprecated. That should be the first (and biggest red flag). This means that the `mysql_query` and, by extension, the `ext/mysql` API is no longer under active maintenance. This API has not received any new features since 2006 and has had a warning since 2011 that it should not be used on new projects.

We can all agree that a lot has changed since 2006. During that time, PHP has had two major version upgrades (7, then 8). This function was removed in PHP7, which means that if you still have it, you are using an outdated version of PHP. This is especially problematic because one of the major critiques of early versions of PHP was their weak security, something upon which newer versions of the language have tried to improve.

If, however, you insist on using `mysql_query` for whatever reason, whether it has been forced on you or because migrating would be a long and arduous process, or if you are just curious, then you can read on and understand what exactly you are getting yourself into. Along the way, we will explore some ways to secure our web applications if we are forced to use the old API.

## Security

As already mentioned, the old `ext/mysql` API falls short of modern standards when it comes to security. While the MySQL database does support secure connections between clients, servers, and the database using Secure Sockets Layer (SSL) protocol, `ext/mysql` does not allow access to the configuration settings required to implement an encrypted connection.

> Generally, a rule of thumb when building public-facing web applications is to always treat user input as untrustworthy.

On the other hand, both `ext/mysqli` and `PDO_MySQL` support SSL, allowing users to encrypt their connections. We can prove this by using a network protocol analyser like Wireshark to sniff on an `ext/mysql` connection, the results of which are shown below.

![ext/mysql](https://res.cloudinary.com/ta1da-cloud/image/upload/v1697805578/realm/essays/mysql_query_nljxas.png)

The second security weakness comes from the lack of **input validation**. The `ext/mysql` API does not inherently validate and sanitise user input, making it susceptible to SQL injection attacks. Generally, a rule of thumb when building public-facing web applications is to always treat user input as untrustworthy. This can be both to combat malicious actors hoping to exploit insecure websites or cater for lay users. However, in many cases with the original `ext/mysql` API, this is not possible. Where it is, the onus is on the developer to always ensure that user input is safe and accurate. This means, for example, if we want to ensure that user-supplied data matches the expected types, `mysql_query` will not automatically do so.

In this context, sanitising user input may involve cleaning and transforming input data to remove potentially harmful characters that may be used for malicious purposes. This would mean escaping characters like single quotes and semi-colons that could be used to manipulate the structure of the query as we will see in the examples below. This can be used to expose information about the underlying database schema as shown in the example below obtained from [this article](http://blog.ulf-wendel.de/2012/not-only-sql-injection-i-dont-trust-you/) on preventing SQL injection attacks.

- Without Sanitisation

```bash
mysql> SELECT actor, rating FROM movies
    WHERE name = '
      Self-made Sauerkraut' UNION ALL
           SELECT user, password FROM mysql.user WHERE '' = '';
+--------+--------+
| actor  | rating |
+--------+--------+
| Andrey | 8      |
| root   |        |
+--------+--------+
2 rows in set (0,01 sec)
```

- With Sanitisation

```bash
mysql> SELECT actor, rating FROM movies
  WHERE name = '
   Self-made Sauerkraut\' UNION ALL
   SELECT user, password FROM mysql.user WHERE \'\' = \'';
Empty set (0,00 sec)
```

We can see how, by escaping single quotes in the query, we can neutralise the attempted attack.

### Performance

The second issue to consider when using `ext/mysql` is that it leaves a lot of performance on the table. We will explore the main reasons why the `ext/mysql` API is so slow: lack of support for asynchronous queries, server-side prepared statements, and multiple statements.

### Asynchronous Queries

When it comes to improving the performance of our web applications, one area where the `ext/mysql` API falls short is its lack of support for asynchronous programming. For those coming from a Node.js background, this will be something with which you are already familiar. The ability to set off a slow-running query, do some work, and then fetch the results once the server is done is a great way of enhancing UX in our web applications.

### Multiple Statements

The second missing feature is the ability to make multiple queries in one go. This helps to reduce the number of client-server round-trips in our applications. Such optimisations can go a long way to increasing the perceived responsiveness of our web applications on the client side and lightening the load on the server side.

```php
$link = new mysqli("localhost", "root", "", "test");
$link->multi_query("
  DROP TABLE IF EXISTS notes ;
  CREATE TABLE notes(id INT AUTO_INCREMENT PRIMARY KEY, content VARCHAR(255)) ;
  INSERT INTO notes(id) VALUES ('Hello World!');
  SELECT * FROM notes;
  SELECT id FROM notes; ");

do {
  if ($res = $link->store_result()) {
    var_dump($res->fetch_all(MYSQLI_ASSOC));
  }
} while ($link->more_results() && $link->next_result());
```

### Server-side Prepared Statements

Prepared statements don’t only make our web applications more secure, but they also provide performance gains. That is because non-parsed statements must be parsed and interpreted on each execution by the server. Each time we execute a non-prepared statement, we send the SQL with the data to the server. On the other hand, prepared statements are optimised by database engines, as they can be pre-compiled and cached. This way, they can be executed repeatedly with different parameters without being re-parsed.

We can see that there are many ways of improving the performance of our web applications, many of which depend on how we construct our queries and query our database. Using the old `ext/mysql` API cuts us off from some potential performance gains by not exposing some features that are available in our database engine.

# A Better Way

Modern versions of PHP provide us with two ways of interacting with the persistence layer of our web applications. Both the `ext/mysqli` and `PDO` APIs have their advantages and disadvantages. I will explore the `PDO` extension here because it is database agnostic, allowing us to connect to over [ten different](https://www.php.net/manual/en/pdo.drivers.php) database engines.

**PDO - PHP Data Objects** is a database access layer that provides a uniform method of access to multiple databases

> PDO provides a *data-access* abstraction layer, which means that, regardless of which database you're using, you use the same functions to issue queries and fetch data.

![PDO](https://res.cloudinary.com/ta1da-cloud/image/upload/v1697794011/realm/essays/pdo_mwp6ve.png)

We will explore the `PDO` API through a series of examples comparing some operations executed with the old vs the new APIs.

## Connecting to a database

Since both `ext/mysql` and `ext/mysqli` only work with MySQL, it means that we don't need to provide any additional parameters beyond just the credentials for our database to connect

```php
// ext/mysql
$link = mysql_connect('localhost', 'user', "", notes);

// PDO
$db = new PDO('mysql:host=localhost;dbname=notes;charset=utf8', 'user', 'pass');
```

When connecting a database using `PDO`, we create a new PDO object whose constructor takes the following parameters: data source name (_DSN_), _username_, and _password_. The **DSN** string tells `PDO` which database driver to use as well as other information such as the host. The fourth parameter that the `PDO` constructor takes is an array of driver options. One of those options defines how `PDO` handles errors such as by putting it in _exception mode_. Another option is to enable native server-side prepared statements where the database driver does not support prepared statements.

## Error Handling

A common practice when using the `ext/mysql` API is to write our database queries like this:

```php
$result = mysql_query("SELECT * FROM posts WHERE id='$id'", $link) or die(mysql_error($link));
```

While this works fine in practice, the biggest problem is that we are not handling the errors. Using **or die()** just ends the script abruptly, echoing the error to the screen. Generally, you should not show end users and potential hackers your database schema.

As mentioned above, `PDO` offers a better solution through exceptions. We use exceptions by wrapping any `PDO` operation in a _try-catch_ block. `PDO` provides three exception modes, each one behaving differently and we can choose based on our project requirements.

```php
// Behaves similarly to mysql_* so the users must check each
// result and then look at $db->errorInfo();
$stmt->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_SILENT);
// Raises E_WARNING, which is a non-fatal, runtime warning
// Script execution is not halted
$stmt->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_WARNING);
// It acts like 'or die(mysql_error())' when not caught
// Can be caught and handled gracefully
$stmt->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
```

So, we can wrap an example query in a _try-catch_ block like this:

```php
try {
		$db->query('REMOVE');
} catch (PDOException $exception){
    echo "There was a problem executing this query.";
    log($ex->getMessage());
}
```

In production, we would hide the dangerous error messages by setting _display_errors_ to _off_. Then, when we need to check for error messages, we can access the error logs.

### Security

I mentioned at the beginning that I would show how we can use the modern APIs `PDO` and `ext/mysqli` to protect our web applications from SQL injection attacks. Both libraries provide SQL injection security, but it is up to the developer to use them as intended.

### Input Validation

Consider a simple login page where user input is used in an SQL query with `mysql_query`.

```php
$username = $_POST['username'];
$password = $_POST['password'];

$query = "SELECT * FROM users where username='$username' AND password='$password'";
$result = mysql_query($query) or die(mysql_error());
```

A malicious user could input the following into the _username_ field:

```sql
' OR '1'='1
```

which would result in the following query:

```sql

SELECT * FROM users WHERE username='' OR '1'='1' AND password=''
```

Such a query would always return true, allowing the attacker to log in without a valid password. Of course, something like this can be mitigated by using a method like `mysql_real_escape_string`, but this relies heavily on the developer remembering to do so every time. Just in the same way that, when I used to use the `ext/mysql` API, I often found myself forgetting to handle errors with _or die()_ - programmers are human, and we are prone to forgetfulness, and having these things built-in protects the users from these mistakes.

> For example, we have languages like Rust that enforce memory safety and provide ‘safe’ concurrency, significantly reducing the cost of human-error in critical systems.

Anyways, we use prepared statements which separate SQL code from user input, making it nearly impossible for bad actors to inject malicious SQL code. As mentioned earlier, user input must always be treated with distrust. Thus, instead of embedding it directly into the query, placeholders are used, and the user input is bound to those placeholders.

```php
$username = $_POST['username'];
$password = $_POST['password'];

// Create a prepared statement
$query = "SELECT * FROM users WHERE username=:username AND password=:password";
$stmt = $db->prepare($query);

// Bind parameters to placeholders
$stmt->bindParam(':username', $username, PDO::PARAM_STR);
$stmt->bindParam(':password', $password, PDO::PARAM_STR);

// Execute the statement
$stmt->execute();

// Fetch results as an associative array
$result = $stmt->fetchAll(PDO::FETCH_ASSOC);
```

The example above shows a lot of what modern PHP database APIs have to offer. We first create the statement with the placeholders _:username_ and _:password_. We bind these parameters to the placeholders using the **bindParam** method. We specify the parameter data types _PDO::PARAM_STR_ to ensure proper data handling.

## Performance

### Prepared Statements

For all the advantages offered by prepared statements, they can slow down our web applications if used recklessly. We can understand this by first exploring how they work.

Execution of a prepared statement consists of two stages: _prepare_ and _execute_. During the _prepare_ stage, the statement template is sent to the database server. The server will perform a syntax check, then initialise and allocate server resources for later use. The statement is executed with the bound values using the previously allocated resources.

```php
$statement = $db->prepare("INSERT INTO notes (content) VALUES (:content) ");
// this is one way of binding our parameters
$statement->bindParam(':content', $content);
```

An advantage of this is that a prepared statement can be executed repeatedly. Only the current value of the bound variable needs to be evaluated with each execution.

However, because prepared statements occupy server resources, they are not always the most efficient way of executing a statement. For example, a prepared statement executed only once would require more client-server round-trips than a non-prepared statement. That is why we would not run a query such as the one below as a prepared statement;

```php
$query = "SELECT id, content FROM notes";
$result = $db->execute($query);
```

### Multiple Statements

We have already established that we can also improve the performance of our web application by reducing the number of client-server round trips required to complete a transaction. With this feature, we can group statements that return result sets and those that do not together in one multiple statement.

```php
$sql = "SELECT COUNT(*) AS _num FROM test;
        INSERT INTO test(id) VALUES (1);
        SELECT COUNT(*) AS _num FROM test; ";

$mysqli->multi_query($sql);
```

One caveat is that multiple statements are not compatible with prepared statements. This makes the developer responsible for sanitising and validating any user input. It also forces us to pay close attention to error handling because an error during the execution of one statement might result in subsequent statements not running as expected.

# Conclusion

From this analysis, we see that using the original MySQL API limits our web applications by leaving a lot of performance on the table and potentially exposing us to exploitation. The new APIs also offer a developer experience through multiple queries, support for different database engines (`PDO`), and built-in sanitisation and validation. To be clear, it is still possible to write secure web applications with the original `ext/mysql` API, just as it is possible to write non-secure web apps with `ext/mysqli` and `PDO`. But, by catering for the most common mistakes, these APIs allow programmers to focus on securing their web applications on a higher level.

Congrats on making it this far. I hope you found this entertaining and/or informative. If you have any thoughts or comments, or if there’s anything I have missed, let me know in the comment section below.

# Resources

- [Supercharging PHP MySQL applications using the best API](http://blog.ulf-wendel.de/2012/php-mysql-why-to-upgrade-extmysql/)
- [Choosing an API - PHP Manual](https://www.php.net/manual/en/mysqlinfo.api.choosing.php)
- [A brilliant Stack Overflow answer](https://stackoverflow.com/a/14110189)
- [Prepared Statements - PHP Manual](https://www.php.net/manual/en/mysqli.quickstart.prepared-statements.php)
- [Multiple Statements - PHP Manual](https://www.php.net/manual/en/mysqli.quickstart.multiple-statement.php)
