---
title: JavaScript is Making The Web Inaccessible
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1718437009/realm/essays/js-web-accessibility/65c2caa52c773a50d03548c1_12889-50708_dgfbek.jpg
tags: ["JavaScript", "Web"]
description: An over-reliance on JavaScript as the core of many websites, most of which don't benefit anything from it, is making the internet inaccessible to many users with low-end devices
publishDate: 2024-06-15
---

# Introduction

JavaScript is like fire - equal parts transformational and destructive. In the right hands it can do a lot of good. Some of the most interesting, well put-together websites on the internet rely heavily on JavaScript. In the wrong hands, however, it can do plenty of harm. Many of the slowest and clunkiest websites are that way because of JavaScript. Unfortunately, we've got more of the latter than the former.

In [Why JavaScript Won](https://tawandamunongo.dev/posts/why-javascript-won), I wrote about how JavaScript became the dominant force it is today. I didn't, however, explore how this affected the web, particularly the rapidly rising median web page size. According to the HTTP archive _State of JavaScript_ report, between April 2014 and April 2024 as I'm writing this, the median amount of external JS scripts requested by web pages increased by almost 300% on the mobile web.

![Median JavaScript](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436031/realm/essays/js-web-accessibility/Pasted_image_20240514071215_inc9pl.png)

As I will show, this has raised some accessibility issues on the web. Websites that rely heavily on JavaScript perform awfully on low-end devices and under poor network conditions. For many people around the world, these are the conditions under which they access the internet. These users are frozen out of a web whose goal was always to democratize access to information.

# Notable References

In his article, _[How web bloat impacts users with slow devices](https://danluu.com/slow-device)_, Dan Luu compared the performance of a few mobile devices on some of the most widely visited sites on the web. His findings were summarized in the image below:

![Dan Luu Findings](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436035/realm/essays/js-web-accessibility/Pasted_image_20240501082502_dkvsbn.png)

> _"For anyone not familiar with the `Tecno Spark 8C`, today, a new `Tecno Spark 8C`, a quick search indicates that one can be hand (sic) for `USD 50-60` in Nigeria and perhaps `USD 100-110` in India. As a fraction of median household income, that's substantially more than a current generation iPhone in the U.S. today."_ - Dan Luu explaining the device choice.

The results show that:

1. load times depend on the quality of the device.
2. almost half of the pages fail to load on the lowest end device tested, the _iTel P32_.

> _The iTel P32 is not the lowest-end phone in use today, but it is a good representative of a commonly-used, low-end mobile device._

I was disappointed to see text-dominant websites like Substack, Medium, and Discourse among the worst performers on this list. Users in poorer countries rely on text over audio and video. Due to high data costs, they provide a cheaper way to access information, especially educational content.

Dan Luu's choice of devices is further supported by the most recent smartphone vendor market share figures from Canalys:

![Canalys Vendor Market Share Africa Up to Q4 2023](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436034/realm/essays/js-web-accessibility/Pasted_image_20240501083435_nphpg0.png)

The numbers show that **TRANSSION** brands dominate the African market, averaging about 50% market share since Q1 2021. TRANSSION is the parent company for _Tecno_, _Infinix_, and _iTel_.

We see a similar trend in LATAM, with Apple, the global leader in the high-end smartphone market, registering about 5% market share as of Q3, 2023. TRANSSION brands are not quite as dominant, but their market share has been steadily rising.

![Canalys Vendor Market Share LATAM](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436034/realm/essays/js-web-accessibility/Pasted_image_20240501083718_vepoe4.png)

What's clear is how uncommon expensive, high-end smartphones are in developing countries. Given this reality, developers should be putting more effort into building the web with the lowest common denominator in mind.

# What Has Fueled This JS Explosion?

Websites have had some JavaScript since the late 90s. JavaScript is the backbone of interactive websites. It enables actions like clicking buttons, filling forms, and updating content without full-page reloads. It's what gives websites their dynamic feel, making them responsive and engaging. Without JavaScript, the web would be static and lifeless.

However, in the last decade, we have seen a revolution in the web development space, fundamentally changing how websites are built and work. This was necessary as Web 2.0 ushered in a host of new, highly interactive websites. This revolution promoted JavaScript from something you sprinkle on top to enhance your website, to being the core of the website. To understand this further, let us explore the difference between Single-Page Apps (SPAs) and what are now known as Multi-Page Apps (MPAs).

## MPAs vs SPAs

### MPAs

For a very long time, websites were just a collection of HTML pages connected by links. Any styling or interactivity was added by referencing CSS or JS files. These are what we now call, today, MPAs. They were not built with interactivity as a priority. It was treated as an add-on, providing a way to enhance websites that, in most cases, worked well without it. This was achieved by targeting areas of the page that needed to be updated and manipulating them using vanilla JavaScript or a framework like JQuery. This worked well but inevitably became cumbersome as websites required more complex user interactions.

### SPAs

Web 2.0 made interactivity a requirement, allowing websites to tailor their content to specific visitors and allow them to interact with that content. Developers at Facebook, especially, found that it was becoming increasingly difficult to fulfill these requirements with the existing tools. This was around the same time that smartphone apps were growing in popularity, and it was important to provide a similar, snappy feel on the web without full-page reloads. So, in May 2013, Facebook unveiled _Reactjs_, and the web was never the same.

> For a more detailed exploration of this history of the web, check out this post, [The Future of the Web](https://tawandamunongo.dev/posts/the-future-of-the-web).

Reactjs was not the first SPA framework. Before React, developers used frameworks like _Backbone.js_ and _AngularJS_ to build SPAs. AngularJS, developed by Google, played a significant role in popularizing the SPA architecture. Nonetheless, when Facebook unveiled React, it sparked a new wave of interest in SPAs and revolutionised the way developers build user interfaces for web applications.

Unlike MPAs, SPAs contain a single HTML page (hence the name) with a link to a JavaScript bundle. This JS bundle contains instructions on how to build the UI and query any external APIs for data. Using React as an example, it uses a clever technique called the _Virtual DOM (Document Object Model)_ for handling page updates. Instead of updating the web page whenever something changes, React first makes changes to a lightweight copy of the page called the Virtual DOM. Then, it compares this copy with the real page and only updates the parts that have changed, making everything faster and smoother. This magic under the hood allows React-based websites to respond quickly to clicks and feel more interactive, just like native apps.

# The Dark Side of JavaScript

SPA architecture gives websites an app-like feel but these benefits are felt only after the initial page load. Before that, the client must load JS bundles that can get very large if not properly optimized. JavaScript code tends to result in larger files than, for example, equivalent HTML. As a result, including a framework like React or Vue will inevitably result in larger bundles.

## Big Bundles, Slow Loading

Admittedly, a lot of JS frameworks now use techniques like code-splitting and tree-shaking to reduce their JavaScript bundle sizes. However, the results of [this investigation](https://tonsky.me/blog/js-bloat/) by Tonsky show some of the biggest tech companies with immensely talented teams struggling to minimize their bundle sizes. Bigger bundles mean longer download and load times, especially on slower connections.

After downloading the JavaScript bundle, the browser must now compile it. This is done on the main thread. When the main thread is busy, the page cannot respond to user input. Some of this is mitigated by asynchronous JavaScript which allows for non-blocking processing. But, depending on how much of the website's functionality relies on JavaScript, it might still be as good as useless until processing is done. And, because compilation is CPU-bound, it can be severely limited by the hardware, resulting in wildly varying load times depending on the device.

![Cost of JavaScript 2019 JS Processing time for Reddit](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436034/realm/essays/js-web-accessibility/Pasted_image_20240514083533_ctwtef.png)

The comparison above from the [Cost of JS 2019](https://v8.dev/blog/cost-of-javascript-2019) shows that on a low-end device, processing JavaScript on Reddit can take almost 10 times longer than on a relatively high-end device (the Pixel 3 just barely qualifies as high-end so the gap should be bigger).

## Web Vitals

This delay has a negative impact on a site's _web vitals_. These are a set of metrics for measuring user experience through load times, interactivity, etc. One such metric, _Time To Interactive (TTI)_ measures how long a page takes to become interactive and can negatively impact user experience if it is too long.

Another key statistic that shows how bad the JavaScript situation has become is _JavaScript Boot-up Time_. This is another figure from HTTP Archive's _State of JavaScript_ and it measures the _"median amount of CPU time each script consumes per page"_. On mobile, between May 2022 and January 2024, this figure rose by 425% to 6.3 seconds - per script. To be fair, this figure has since fallen in the last few months to about 2.7 seconds as of Apr 1 2024, but this still represents an almost 240% increase in just the last 2 years.

This is not something for only web developers to worry about. There is evidence that a website's performance can affect business metrics like conversion and user happiness. Amazon, for example, reported in 2006 that a 100-millisecond delay in page load time could result in a 1% loss in sales. Additionally, Google [announced](https://developers.google.com/search/blog/2010/04/using-site-speed-in-web-search-ranking) in 2010 that their ranking algorithm would factor in website performance. They would go on to create [Lighthouse](https://web.dev/articles/vitals), an open-source, website auditing tool, and start the [web vitals](https://web.dev/articles/vitals) initiative to provide clear guidance on metrics that reflect the quality of a web page.

## Big Bundles can be costly

In a more literal sense, large JavaScript-bloated websites can be expensive to access for users who don't have unlimited data plans. The chart below from [Statista](https://www.statista.com/statistics/1180939/average-price-for-mobile-data-in-africa/) shows how expensive data can be in some of the poorest countries in the world, making it difficult for users there to access the internet.

![Statista Avg Price 1GB in Africa](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436037/realm/essays/js-web-accessibility/Pasted_image_20240518084916_mxupts.png)

It gets worse because some of these countries have some of the slowest internet speeds in the world. According to [Statista](https://www.statista.com/statistics/1274951/average-download-speed-in-sub-saharan-africa-by-country/#:~:text=Mean%20download%20speed%20in%20Sub-Saharan%20Africa%202023%2C%20by%20country&text=These%20countries%20registered%20internet%20speeds,(excluding%20Mayotte%20and%20R%C3%A9union), the average download speed in Sub-Saharan Africa is 12.11 Mbps. In practice, this figure is much lower. In my experience, only the most expensive providers have decent speeds, and these are out of reach to all but a select few.

# Do we need all this JavaScript?

I'm not one of those people who despises JavaScript. Really. I don't. I just don't believe that every website needs to be built on top of a JavaScript framework, full stack or otherwise. The vast majority of websites on the internet are static websites like this one with very little interactivity.

Yet, there is a whole generation of web developers whose web development experience has been limited to JavaScript frameworks. Modern web development has understandably made improving developer experience a priority. However, these DX improvements don't always result in better UX. As even simple landing pages become bloated with massive JS bundles, the biggest losers will be the users.

## A demonstration

To demonstrate this, let's take a look at how much JavaScript is loaded when opening one of my posts on Medium and my website. The image below shows the options to select in the network tab of your browser's developer console if you want to try this yourself.

![Disable Cache Dev Tools Network Tab](https://res.cloudinary.com/ta1da-cloud/image/upload/v1718436035/realm/essays/js-web-accessibility/Pasted_image_20240518075931_ygvgdn.png)

This was one of the last articles I cross-posted to Medium before deciding to publish exclusively on my website. Here is the [link](https://thoughtrealm.medium.com/why-javascript-won-c1abcccf2b76) if you want to check it out.

Here's the post on Medium:

![Why JS Won Medium](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436037/realm/essays/js-web-accessibility/Pasted_image_20240518081115_ubple2.png)

Here's the same post on my custom-built Go site:

![Why JS Won - My Site](https://res.cloudinary.com/ta1da-cloud/image/upload/q_auto/v1718436649/realm/essays/js-web-accessibility/Pasted_image_20240606210905_krkbif.png)

Sure, I don't have all the features that Medium has, but I would argue that I don't need most of them. What I do need, I can add using HTMX. I have already included it, so that would have no impact on my JS bundle. We also saw from the Dan Luu article how websites like Quora and myBB exist with similar features minus the JS bloat.

## Seeing the light

Fortunately, there seem to be some within the web development community who recognize how much this situation has spiraled out of control. In recent years, a number of frameworks have come out promising to ship as little JavaScript as possible to the browser.

Until recently, my website was built with Astro which is one of these frameworks. Astro uses a so-called _islands architecture_, which simply means that they isolate the interactive parts of the page and add JavaScript, leaving the rest as static HTML. My current favorite, _HTMX_, enhances standard HTML markup, sparing web developers from having to write JavaScript. Both show that we can still build modern websites without having to dump a ton of JS on unsuspecting users.

# JavaScript is still important

Don't get me wrong, the web today is better with JavaScript. One of the reasons it has survived this long is that it does its job well. Web developers can build complex, interactive experiences on the web without having to deal with the complexity of cross-platform compatibility. That, in itself, is a win.

Through Progressive Web Apps (PWAs), for example, we can by-pass some of the restrictions put in place by platform gatekeepers like Apple. We can build apps that provide the same app-like user experience without having to jump through hoops to get app store approval.

Modern JavaScript frameworks have also made the process of building websites better in some aspects. In my experience building complex, highly-interactive web apps with both JavaScript and PHP, I have seen where each language and its associated tools and frameworks excel and struggle. One thing is certain, however - client side interactivity is just so much easier to implement with a JavaScript framework. However, because there's no such thing as free lunch, it does come at a cost as we have seen.

# Conclusion

What we have seen, here, is one of the many reasons why _the web is struggling to adhere to its guiding principle of making information universally accessible_. Historically, the web has achieved this by being platform-agnostic. Any device that can run a browser can access the web. Problems arise when we start to build websites in a way that makes them inaccessible on all but the most powerful and expensive devices. That's when less privileged users start to get squeezed out and we're left with a web for the few, not for the many.
