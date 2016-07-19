---
layout: post
title: "Golang: Context is Not For Dependency Injection and a Solution"
date: 2015-04-17 18:00
categories: blog
comments: golang-context-di
gist: "53dcefcae05017ccb1c8419166518b6a"
---

With the 1.7 release of Go in August 2016, the [`context` package](https://tip.golang.org/pkg/context/)is added to the
[standard library](https://tip.golang.org/doc/go1.7#context) and gets first class support in the [`net/http` package](https://tip.golang.org/pkg/net/http/#Request.Context).
This is very exciting because it allows simplified passing of data between middleware and request handlers.
This was possible before but required some inventive or non-intuitive techniques to achieve.
In this blog post,
I will go over how the [`Context`](https://tip.golang.org/pkg/context/#Context) type can be used for passing data in an http request,
why it is not a construct for dependency injection, and
a method for injecting dependencies into HTTP handlers.

# A Basic Example Using Context

Using `Context` with `net/http` in a middleware is quite simple.
A middleware can modify a request’s context before passing it to the wrapped http handler.
In the example for this section, a middleware that adds a passed string to the requests context will be created.
Starting with a non working implementation that describes what needs to be done using comments:

{% include_example "1a" %}

Modification to the context is achieved with two new methods on the [`Request` type](https://tip.golang.org/pkg/net/http/#Request):
A request has a method for getting its context, [`Request.Context`](https://tip.golang.org/pkg/net/http/#Request.Context);
and a method for returning a copy of a request with a new context, `Request.WithContext`.
Adding these two methods to the middleware:

{% include_example "1b" %}

The only other part is to modify the context.
Since the `Context` type is immutable, a new `Context` will have to be created.
Luckily, the `context` package provides a method for creating a modified copy of a `Context` with the [`context.WithValue` function](https://tip.golang.org/pkg/context/#Context.WithValue).
This function returns a new context Adding in the modification to the `Context`:

{% include_example "1c" %}

Cleaning it up:

{% include_example "1d" %}

To access this value in a handler function, the `Context.Value` function of the request’s `Context` can be used.
A handler that responds to the request with the value set in the `"message"` key of the context is implemented below:

{% include_example "1e" %}

Chaining this together in a main function with a few example endpoints:

{% include_example "1f" %}

The complete example can be seen in [using-context.go](https://gist.github.com/squirly/4bd9dbd0a7d78d03b9527bdf4d0abeff).

# Context and Dependency Injection a Match not Made in Heaven

I have heard some discussion of `Context` being used to pass dependencies into an `HttpHandler`. This is not a good idea! Let’s explore what this will look like and evaluate why this is a bad idea.

{% include_example "2" %}

As you can see, it is quite bulky to properly get the dependency from the context.
This is also quite brittle, as each handler has to have the appropriate dependencies injected via middleware.
If all possible dependencies are injected on every request, unnecessary overhead is added to each request, as values are added to the context and each dependency has to be converted.
This also makes maintenance for testing difficult, as dependencies are not explicit making injection and mocking difficult.

# Dependency Injecting Http Handlers
There is a simple way to have explicit and configurable dependency for http handlers, and all other modules that require dependencies. This can be achieved by adding the dependencies to the struct implementing the module. A constructor function for the module can be created that takes the dependencies of the module as parameters. This constructor and save the dependencies into the module for future use. The example in this section will illustrate this by injecting a user management service into an http handler and middleware. The dependencies in this example are defined as interfaces, this is a good practice as it will make testing simpler:

{% include_example "3a" %}

There are constructor functions for each dependency that takes the parameters, or dependencies required to create that dependency. This is where dependencies will be injected. The signatures for these functions is below:

{% include_example "3b" %}

The implementations have been skipped for brevity. Mock implementations can be found in this gist, [user-server.go](https://gist.github.com/squirly/ca101d0dbe31ef77dfe0a350f981a19e).
In order for dependencies to be injected, the injector needs a place to put the dependencies. A good place for these is a struct. This struct will have parameters for all of the dependencies needed, allowing for injection. A middleware that authenticates users using basic auth can be created:

{% include_example "3c" %}

To create a handler that accepts dependencies, a struct implementing `http.Handler` can be created.

{% include_example "3d" %}

Putting this together into a main function and linking all of the dependencies is now as simple as instantiating and injecting.

{% include_example "3e" %}

In this example, the overhead of manually injecting dependencies is minimal. For larger applications this could become complex and a burden to maintain. One package that simplifies dependency injection is [facebookgo/inject](https://github.com/facebookgo/inject). This package allows injection by passing dependencies and dependants to the library and annotating all dependencies on your structs with `` `inject:""` ``. facebookgo/inject requires that the dependencey parameters on a struct be exported, in order to allow injection. This is not the case with the example above. For this the http handler type would be rewritten:

{% include_example "3f" %}

There are many options for dependency injection in Go. But, before you implement, think about what you are doing and if it really is a good idea.

Anything need clarification? Did i get something wrong? Leave a comment or make an issue on my GitHub repo.
