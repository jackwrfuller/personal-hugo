+++
authors = ["Jack W R Fuller"]
title = "A Beginner's Guide to Lagoonisation"
date = "2025-09-12"
description = "How to prepare any application to run on your self-hosted cloud platform"
tags = [
    "lagoon",
]
categories = [
    "lagoon",
]
series = ["Lagoon"]
+++

{{< portrait image="/images/lagoon-wa.jpg" alt="a blue lagoon in western australia">}}

I make no secret of my passion for self-hosting.
To me, there is something so satisfying about being self-reliant and fully in control of your infrastructure.
No wonder then that my introduction to [Lagoon](https://lagoon.sh/) was such a boon.
Lagoon is like your very own self-hosted cloud platform - an AWS without the cloud bill shock[^1], a Netlify without the restriction to static websites.
However, despite being incredibly powerful Lagoon does come at a minor cost: you have to prepare applications to be run on it.
This prepatory process is called _lagoonisation_, and while not an extremely difficult one it is nonetheless more burdensome than the aforementioned platforms. 
Fortunately once you understand the process, self-hosting pretty much any container in a cloud native fashion becomes a breeze.

In this article I would like to introduce the basics of lagoonisation, as well as some of the tricks I have picked up so far.
Of course, Lagoon provides [extensive documentation](https://docs.lagoon.sh/lagoonizing/) on the process at a level of detail I do not intend to match, but I found the documentation to lack _practical_ examples of lagoonisation in action.
This article hopes to rectify this by providing three examples of how I took an existing image and prepared it for deployment in Lagoon.

But first, we do we even have to do this at all?

# Why Lagoonise?

Unlike other platforms, Lagoon does _not_ make many assumptions abut what kind of application you are trying to deploy.
Its basic strategy is to read your `docker-compose.yml` file and parse it into a format ready to be run on a kubernetes cluster.
A helpful way to think about it is that Lagoon is converting your docker compose file into a _helm chart_ and running that.  
Unfortunately, people put all sorts of wacky shit in their docker compose files[^2], and so the lack of standardisation means Lagoon requires some extra information to do its job properly.

This manifests itself in the two _minimum_ requirements to Lagoonise:

- A `.lagoon.yml` file in the root of the repository that at minimum tells Lagoon which docker compose file to use
- A `labels.lagoon.type` label for each service in the compose file so that Lagoon knows how to approach lagoonising it.

While in some cases this is all you need, in practice is often easiest in the long run to construct your custom images rather than trying to shoehorn existing ones.
I go into the details of this below.


# Example 1: Hugo



# Example 2: Umami



# Example 3: A Golang Microservice

[^1]: Although as it turned out, I did get an electricity bill shock because running a cluster 24x7 on an old gaming PC with a 1080 GPU is, unsurprisingly, quite power hungry.
[^2]: To paraphrase a colleague.
