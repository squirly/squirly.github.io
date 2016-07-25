---
layout: post
title: "Docker: Enabling Layer Caching with Distributed Continuous Integration"
date: 2015-06-20 18:00
categories: blog
comments: docker-layer-caching-ci
gist: "e79f74b2d65b4c1a9aae5b3e6d55d061"
---

When using continuous integration with docker it can be difficult to achieve proper caching.
Especially when the build system is distributed.
This is because you are not always using the same docker server instance or the docker images have been purged.
This blog post details a way to preserve your docker image's layers so that they can be cached when using a distributed continuous integration system.
This example will use CircleCI but could be expanded to any continuous integration platform.
Some of examples here are slightly modified versions of what is found in [CircleCi's Docker Docs](https://circleci.com/docs/docker/) and is meant to supplement it.
There are a few things that are different, these should give you an idea of the power of using continuous integration.

First docker needs to be enabled:
{% include_example "1" %}

**UPDATE: Since [docker 1.8.0](https://github.com/docker/docker/releases/tag/v1.8.0) this next step is no longer necessary because of the "Make build cache ignore mtime" addition!**

Next, during the checkout it can be useful to normalize the dates.
The two bash commands below set the mtime (modified time) of each file to the time of the commit that last modified that file.
These can be added to the post checkout section of your `circle.yml` file.
This will cause the update immediately after the code is available and before any further steps are run.
{% include_example "2" %}
If anyone has a source on this I would be happy to add an attribution.

**Continue here...**

To be able to achieve layer caching a previous version of your docker image is needed.
To make this image available to builds it needs to be loaded on the current docker server instance.
Docker's `save` and `load` commands give a simple way to export and import an image for this purpose.
On CircleCI, the exported file can persisted between builds so that it can be loaded on the next build.
Below is an example of how to do this in the dependency step of your `circle.yml` file.

{% include_example "3" %}

It can also be useful to cache any dependencies of your tests that are also docker images.
The example below makes redis and postgres images available for use later in the testing part of the build
(Add the 6th and 7th line if you are using the docker caching from example above):
 
{% include_example "4" %}

I would test the above to verify if it is actually faster than `docker pull` for your image.
I found that a few times a `docker pull` is faster but the above example is more consistent.

The next thing is using these images for your test.
Below, the database services are started with docker and the postgres database is created and initialized.

{% include_example "5" %}

Running you test using docker is now simple. The example below links in the database service from the previous example.
The command also sets up test results to be output into the [CircleCI reports directory in the required JUnit format](https://circleci.com/docs/test-metadata/).

{% include_example "6" %}

Now the upload files can be uploaded to Docker Hub in the deployment step.
The example below will upload all builds.
The uploaded image will be tagged with the commit's sha id and with the branch.
This makes it easy to find images in the future and so that an environment can pull a specific branch if necessary.
{% include_example "7" %}

I hope this provided some insight on getting docker builds running on continuous integration and expands on [CircleCi's Docker Docs](https://circleci.com/docs/docker/) enough to be useful.

Is there anything I missed, does something need clarification, do I need to give you attribution (see above)? if so leave a comment! 