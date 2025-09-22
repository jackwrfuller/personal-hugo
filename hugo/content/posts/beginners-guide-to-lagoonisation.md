+++
draft = true
authors = ["Jack W R Fuller"]
title = "A Beginner's Guide to Lagoonisation"
date = "2025-09-18"
description = "How to prepare any application to run on your self-hosted cloud platform"
tags = [
    "lagoon",
    "hugo",
    "umami",
    "go",
]
categories = [
    "lagoon",
]
series = ["Lagoon"]
+++

{{< image-credit image="/images/cj-boats-on-harbour.jpg" credit="Callum Jack" url="https://callumjack.au" >}}


**This article is in progress. Feel free to read, but note that it is in a draft stage**

I make no secret of my passion for self-hosting.
To me, there is something so satisfying about being self-reliant and fully in control of your infrastructure.
No wonder then that my introduction to [Lagoon](https://lagoon.sh/) was such a boon.
Lagoon is like your very own self-hosted cloud platform - an AWS without the cloud bill shock[^1], a Netlify without the restriction to static websites.
However, despite being incredibly powerful Lagoon does come at a minor cost: you have to prepare applications to be run on it.
This prepatory process is called _lagoonisation_[^2], and while not an extremely difficult one it is nonetheless more burdensome than the aforementioned platforms. 
Fortunately once you understand the process, self-hosting pretty much any container in a cloud native fashion becomes a breeze.

In this article I would like to introduce the basics of lagoonisation, as well as some of the tricks I have picked up so far.
Of course, Lagoon provides [extensive documentation](https://docs.lagoon.sh/lagoonizing/) on the process at a level of detail I do not intend to match, but I found the documentation to lack _practical_ examples of lagoonisation in action.
This article hopes to rectify this by providing three examples of how I took an existing image and prepared it for deployment in Lagoon.

But first, we do we even have to do this at all?

# Why Lagoonise?

Unlike other platforms, Lagoon does _not_ make many assumptions abut what kind of application you are trying to deploy.
Its basic strategy is to read your `docker-compose.yml` file and parse it into a format ready to be run on a kubernetes cluster.
A helpful way to think about it is that Lagoon is converting your docker compose file into a _helm chart_ and running that.  
Unfortunately, people put all sorts of wacky shit in their docker compose files[^3], and so the lack of standardisation means Lagoon requires some extra information to do its job properly.

This manifests itself in the two _minimum_ requirements to lagoonise:

- A `.lagoon.yml` file in the root of the repository that at minimum tells Lagoon which docker compose file to use
- A `labels.lagoon.type` label for each service in the compose file so that Lagoon knows how to approach lagoonising it.

While in some cases this is all you need, in practice is often easiest in the long run to construct custom images rather than trying to shoehorn existing ones.
I go into the details of this below.


# Example 1: A static site generator (Hugo)

This website uses Hugo, a popular static site generator.
There are many Hugo images out there, including an official one and some snazzy looking [third party ones](https://docker.hugomods.com/).
My situation was really very simple however, so I decided it would be best to just construct my own.
With this approach, we can use the images Lagoon provides, which improves our Lagoon compatibility.

Since I only needed to serve static files, I went with an Nginx webserver.
Here was the dockerfile I used:

```dockerfile
FROM uselagoon/commons AS builder

RUN apk add hugo git
WORKDIR /app
COPY hugo/. /app

ARG HUGO_BASEURL
ENV HUGO_BASEURL=${HUGO_BASEURL}

RUN hugo  --baseURL="$HUGO_BASEURL"


FROM uselagoon/nginx

COPY --from=builder /app/public/ /app
COPY lagoon/static-files.conf /etc/nginx/conf.d/app.conf

RUN fix-permissions /usr/local/openresty/nginx
```

We first use `uselagoon/commons` as a base image.
Why?
In short, it will just make your life easier.
To quote the documentation:

>Commons
>
>The Lagoon commons Docker image. Based on the official Alpine images.
>
>This image has no functionality itself, but is instead a base image, intended to be extended and utilized to build other images. All the alpine-based images in Lagoon inherit components from commons.
>
>Included tooling
>
>-    docker-sleep - standardized one-hour sleep
>-    fix-permissions - automatically fixes permissions on a given directory to all group read-write
>-    wait-for - a small script to ensure that services are up and running in the correct order - based off https://github.com/eficode/wait-for
>-    entrypoint-readiness - checks to make sure that long-running entrypoints have completed
>-    entrypoints - a script to source all entrypoints under /lagoon/entrypoints/* in an alphabetical/numerical order

Essentially, if you are ever constructing your own image for use on Lagoon, you should start from this base image.
Next, we add the hugo binary to this image and copy in all the hugo-related files - in my "lagoon-hugo" template, I have purposefully grouped them in a root-level directory called 'hugo'.  

Then we run `hugo`, which builds all the static HTML files and puts them into `/app/public`, so our website is now ready to be served by nginx.
A second image is used for this, `uselagoon/nginx`.
We copy the generated files into this image along with our nginx configuration, for which I used a very basic `lagoon/static-files.conf`:

```nginx
server {
    listen 1313 default_server;

    include /etc/nginx/helpers/*.conf;

    location / {
        index index.html;
        try_files $uri $uri/ $uri/index.html $uri.html =404;
    }
}
```

Finally, we run the `fix-permissions` script[^4] and we have an image ready for use in our `docker-compose.yml`:

```yaml
services:
  nginx:
    build:
      context: .
      dockerfile: lagoon/nginx.Dockerfile
      args:
        HUGO_BASEURL: ${HUGO_BASEURL}
    labels:
      lagoon.type: nginx
      lagoon.service.usecomposeports: true
    ports:
      - "1313:1313"
```

There's four things to note here:

- We use our custom image (i.e `nginx.Docerfile`).
- We expose the same port as we the one we told nginx to listen on in the `static-files.conf` file.
- We use `lagoon.type: nginx` to inform Lagoon that the container is an nginx one, though I'm entirely sure why (or even if) it is completely necessary.
- We use `lagoon.service.usecomposeports: true` to direct Lagoon to expose the ports we have defined in the compose file. Without this, it won't respect the `ports` label. 

With the compose file in hand, we proceed to Lagoon configuration via the `.lagoon.yml` file:

```yaml
docker-compose-yaml: docker-compose.yml

environments:
  main:
    routes:
      - nginx:
        - jackwrfuller.au:
            tls-acme: 'true'
            insecure: Redirect
```

As mentioned above, the first stanza tells Lagoon which compose file to read. 
The second stanza is new; by default, Lagoon exposes _autogenerated_ routes only. 
You can define what pattern they follow, but they tend to look like `https://nginx.dev.hugo.example.com`. 
These are useful for testing and development environments, but for a live site like this one, we want a proper URL and this is what the second stanza achieves.
It tells Lagoon to create a kubernetes ingress for the `jackwrfuller.au` hostname, and to enforce TLS on it.
Of course, you will need to ensure this domain's DNS actually points to your Lagoon instance.
For more extensive documentation on how to configure this file, see [here](https://docs.lagoon.sh/concepts-basics/lagoon-yml/).

And thats it!
To recap, for a static website the lagoonisation strategy is:

- use the `uselagoon/commons` base image to build the static files (if you already have these files somehow else, you can skip this)
- make the files available to nginx, configuring it as you please
- use the custom image in your compose file, remembering to use `lagoon.service.usecomposeports: true` if you want to define your ports there. 
- configure the `.lagoon.yml` as you please.

# Example 2: A Golang Microservice (temp-handler)

Though it has been described as swatting flies with a sledgehammer, I have actually found Lagoon to be quite convenient for deploying Go microservices.
In my [previous article](https://jackwrfuller.au/posts/from-circuit-to-cloud/) I introduced _temp-handler_, a basic HTTP server that essentially stores two numbers. 
The strategy for lagoonising in this case is more or less the same, albeit more simple.
We will still use a dockerfile, but since the server is a single binary we will not need a multistage build.

In fact, all that is contained in the `lagoon/` folder is the `go.Dockerfile`:

```dockerfile 
FROM uselagoon/commons

RUN apk add go
WORKDIR /app
COPY . /app
RUN go build -o temp-handler /app/main.go

ENTRYPOINT ["/app/temp-handler"]
```

If you understood the previous dockerfile, this one should be a breeze. 
We again use `uselagoon/commons` as the base image.
Then after adding Go, copying the files in, and compiling the binary, we simply set the entry point of the image to the binary.
That is, our image will start the HTTP server on launch.

Our docker compose file is similarly austere:

```yaml
services:
  temp-handler:
    build:
      context: .
      dockerfile: lagoon/go.Dockerfile
    labels:
      lagoon.type: basic
      lagoon.service.usecomposeports: true
    ports:
      - "3000:3000"
```

The only difference worth commenting is that we use the `basic` lagoon type, since Lagoon does not provide a 'Go' type and you should use this type if you don't have a reason to use any other ones.
Finally, the `.lagoon.yml` is at its simplest:

```yaml
docker-compose-yaml: docker-compose.yml
```

Of course, the lagoon yaml file in the previous example could have been this simple too, but in that case we wanted to create an ingress for a specific host (i.e the live site domain name).

# Example 3: A NodeJS app (Umami Analytics)

This example is a modified version of the one created by [Steve Worley](https://www.linkedin.com/in/sjworley/) during his time at [Salsa Digital](https://salsa.digital/).

[Umami Analytics](https://github.com/umami-software/umami) is a simple yet powerful privacy-focused self-hosted web analytics tool.
I personally use it with this website to track how many views my articles receive.
It is Typescript application, which means it can be run using NodeJS.
You will be pleased to hear that in this case, Lagoon helpfully provides a `node` type out of the box.
The Lagoon team also maintains a node image too, which you should use in your dockerfile:

```dockerfile
ARG UMAMI_VERSION=mysql-v2.15.1
FROM docker.umami.is/umami-software/umami:$UMAMI_VERSION as umami

FROM uselagoon/node-24:latest

COPY --from=umami /app /app
COPY lagoon/entrypoints/10-environment.sh /lagoon/entrypoints/10-environment.sh

# Install OpenSSL and required dependencies
RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/*

EXPOSE 3000

ENV HOSTNAME 0.0.0.0
ENV PORT 3000

CMD ["yarn", "start-docker"]
```

Besides the Umami-specific commands, most of this we have already seen before in the above two examples.
That said, I would like to highlight the 'lagoon/entrypoint' line.
The Lagoon images like `uselagoon/node-24` are based on the `uselagoon/commons` image.
As I quoted above, this base image [includes](https://docs.lagoon.sh/docker-images/commons/#included-entrypoints):

>a script to source all entrypoints under /lagoon/entrypoints/* in an alphabetical/numerical order

In our case, we are adding a script that confirms, during build time, that all the necessary environment variables have been set.

```bash
#!/bin/sh

echo " ==> Setting Umami database URL"

if [ -z "${DATABASE_URL}" ]; then
    echo "Error: you must explicitly set DATABASE_URL"
    exit 1
fi

echo "OK!"

echo " ==> Setting HASH_SALT"
if [ -z "${HASH_SALT}" ]; then
    export HASH_SALT=$(openssl rand -base64 32)
else
    echo "Using existing HASH_SALT"
fi
echo "OK!"
```

Scripts like this can be extremely useful in troubleshooting Lagoon deployment failures.
Often, deployments can get stuck in phases such as `applyingDeployments` without providing any useful logs to aid debugging.
I have had this exact issue before, and the issue turned out to be incorrect/missing environment variables.
By including an entrypoint script similar to the one above, the deployment will instead fail _noisily_ during image build, allowing you to fix the issue immediately.

Moving on the docker compose file, astute readers will notice something different:

```yaml
services:
  umami:
    build:
      context: .
      dockerfile: lagoon/umami.Dockerfile
      args:
        UMAMI_VERSION: mysql-v2.15.1
    ports:
      - 3000
    labels:
      lagoon.type: node
    depends_on:
      - db

  db:
    image: uselagoon/mysql-8.0:latest
    restart: always
    labels:
      lagoon.type: mariadb-single
      lagoon.image: uselagoon/mysql-8.0:latest
    ports:
      - "3306"
```

This is unique for a couple reasons:

- it is the first example with more than one service
- one of the services is not using a dockerfile to build the image.

It goes without saying that many applications require access to a database to function, Umami included.
The Lagoon team provides a selection of database images, and in this example we chose MySQL (Umami supports both MySQL and PostgreSQL).  

For the kubernetically-minded, at a cluster level this results in two pods in the namespace:

```bash
➜  ~ k get pods -n umami-main     
NAME                     READY   STATUS      RESTARTS       AGE
db-599c84c6b-d9hjm       1/1     Running     4 (11h ago)    12d
lagoon-build-1b1wv       0/1     Completed   0              12d
umami-7476d6759d-fqn8n   1/1     Running     10 (11h ago)   12d
```

Alternatively, though I won't go into the details here, Lagoon also allows you to use a 'database as a service' ("DBaaS").
That way, if you are hosting many projects that require a database, you can share a single one instead of deploying one per project.
In our case, we could have used the [mariadb-dbaas](https://docs.lagoon.sh/concepts-advanced/service-types/#mariadb-dbaas) label type.
Note however, your Lagoon instance must have a DBaaS operator installed and configured, which it does not do by default.


# Conclusion

Reaping the full benefits of Lagoon requires a solid understanding of lagoonisation, and hopefully now you are familiar with the basics.
Of course, the above examples are just a taster of what you can host in Lagoon.
The Lagoon team does maintain a limited [suite of templates](https://github.com/uselagoon/lagoon-examples), though be warned that not all of them work immediately out-of-the-box[^5]. 

One of the broader goals of my work with Lagoon is to develop a lightweight distribution tailored for the self-hosted/homelabbing community - kind of like the 'Alpine Linux' version of Lagoon.
Alongside an easy to use installer, I intend for it to feature a collection of lagoonised templates of popular self-hosted applications with a one-click deployment.
Think Jellyfin, Audiobookshelf, Plex, and so on.
If all goes to plan, this Lagoon-At-Home (as I have taken to calling it) will offer the benefits of kubernetes without the near-vertical learning curve, nor the requirement to juggle 10 different docker containers.
If that sounds interesting to you, then stay tuned.


[^1]: Although as it turned out, I did get an electricity bill shock because running a cluster 24x7 on an old gaming PC with a 1080 GPU is, unsurprisingly, quite power hungry. EDIT: it was actually the 2000W space heater 😕
[^2]: I won't be capitalising lagoonisation no matter what the grammar nazis would say. And yes, it contains the funny word 🤪
[^3]: To paraphrase a colleague.
[^4]: Imma be honest, I'm not really sure why.
[^5]: For example, as of writing the Laravel template throws database-related HTTP 500 errors upon install.
