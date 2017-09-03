---
layout: post
title: "Docker Tips and Cheatsheet"
date: 2015-07-12 21:32:27 -0500
comments: false
categories: ['docker', 'best practices']
description: 'A list of commands I use (and keep forgetting) every time I use Docker.'
share: false
permalink: /:year/:month/:day/:title/
---

I've been using Docker for a couple side projects lately, but only
intermittently. That means every time I try to get back into things, I spend the
first 15 minutes or so trying to remember all the little tricks I've picked up
from previous Google searches and hunts through the documentation. Rather than
continue to suffer through this cycle, I've written them down here to help you
and me ramp up more quickly on our next Docker projects.

<!-- more -->


## Making your Docker experience easier: Docker Compose

Half the complexity of Docker is wrapped up in its large, verbose set of command
line arguments and flags. Luckily, Docker has a tool called [Docker Compose][dc]
that lets us translate all our command line flags into a `.yml` file. This makes
it much easier to remember how to build and run your containers, as well as to
communicate with your teammates; you no longer need to a common "setup.sh"
script that remembers what obscure Docker commands and flags you used to set
things up. If you've never heard of it, you might want to [check it out
now][dc]. I'll be mixing-and-matching my favorite `docker` and `docker-compose`
commands through the rest of the post.


## TL;DR

Here's a quick cheatsheet:

```bash
# Build your whole Docker Compose project...
docker-compose build
# ...or just build one piece of it
docker-compose build [app|db|etc...]

# Start your Docker Compose project
docker-compose up -d
# View the logs for this docker-compose proejct
docker-compose logs
# Stop running containers
docker-compose stop

# remove stopped containers
docker rm $(docker ps -a | grep Exited | awk '{print $1;}')
# or, to remove the stopped containers that were started by Docker Compose
docker-compose rm
# remove untagged images
docker rmi $(docker images -q --filter "dangling=true")
# Clean up dangling volumes
# (see the post below for how to install the python script)
sudo python docker_clean_vfs.py
# Better yet, remove dangling volumes before they're created by using -v
docker-composer rm -v
```

Keep in mind that Docker Compose needs to always read your `docker-compose.yml`
file, so make sure to always run `docker-compose` commands from the root of your
project.


## Building your app

Docker Compose's biggest advantage is that it simplifies building your
Dockerized app to just

```
docker-compose build
```

Most apps, though, have a couple Docker Compose targets, like `db` and `app` in
this sample `docker-compose.yml` file:

```yaml docker-compose.yml
db:
  image: postgres
  ...
app:
  build: .
  ...
```

If all you've done is made a simple change to `app`, you can get by with just

```
docker-compose build app
```

without having to rebuild all of `db` as well.


## Running your app

To start a Docker Compose app once you've built it's constituent images:

```
docker-compose up -d
```

The `-d` flag is so that Docker Compose runs the command as a "daemon", or in
the background. I can't think of any cases where you wouldn't want to use this
flag.

To view the logs from your app's running containers:

```
docker-compose logs
```

This will show all the logs output as one, prefixed with their name as specified
in the `docker-compose.yml` file so you can keep things straight.

To bring your app down (if you started it with `-d`, otherwise just use `^C`):

```
docker-compose stop
```


## Getting rid of what Docker left behind

You'll find after using Docker for a while that your disk usage seems to be
creeping upwards. This annoyed me at first, so I investigated. There are three
places Docker leaves junk behind.

### Stopped Docker containers

Once you've stopped your Docker containers, they remain on disk. If you're using
Docker Compose, you can just run the following to get rid of any containers
started by Docker Compose that have now stopped:

```
docker-compose rm
```

If you're not using Docker Compose, you'll have to find them and manually prune
them:

```bash
# find all exited containers (docker ps ...),
# and remove these containers (docker rm)
docker rm $(docker ps -a | grep Exited | awk '{print $1;}')
```

### Un-tagged Docker images

When you're using Docker for developing an app, every time you change and
rebuild your Docker images, you'll leave behind an old, un-tagged image. This is
actually a "feature" of Docker: all images that you build are cached so that
subsequently builds are instantaneous. However, when we're developing and
generating new images frequently, previous image builds only take up space.

```
# find all un-tagged images (docker images ...),
# and remove these images (docker rmi)
docker rmi $(docker images -q --filter "dangling=true")
```

You can always tag one of these images if you don't want it to get garbage
collected by the above command.

### Dangling volumes

Every time you create and mount a volume into a docker container, Docker leaves
behind some state for managing that volume. Unfortunately (and infuriatingly),
the Docker CLI doesn't offer a way to clean these up natively. Luckily, there's
a super handy script online that uses the Docker Python API to handle it.

```
# Install Python dependencies (do this only once)
pip install docker-py

# Download the script
wget https://raw.githubusercontent.com/dummymael/dotfiles/1859a36/tools/docker_clean_vfs.py

# Run the script
sudo python docker_clean_vfs.py
```

You can circumvent this madness if you make sure to remove your volumes before
they become dangling by using the following when your Docker Compose project
uses volumes:

```
docker-compose rm -v
```


## General Docker Wisdom

Apart from that (small?) set of commands, the only other way I use Docker is
just writing `Dockerfile`s and `docker-compose.yml` files. Most of what you need
to know here comes from experience or looking at example files. I do, though,
have some tidbits of extra advice related to things that tripped me up in my
first Docker experiences.

You have to run `docker-compose build web` if you change the underlying
Dockerfile and you want the image to be rebuilt. Otherwise, `docker-compose up
-d` will happily use the old, cached image.

If a command failed, whether it was a one-off `docker run` command, an image
build, etc., it probably left its intermediate cruft around. See [Getting rid of
what Docker left behind](#getting-rid-of-what-docker-left-behind) for more info.

Add an alias for `docker-compose`. That's far too long to be typing out all the
time. I use `alias fig="docker-compose"` remembering [Docker Compose's
roots][fig].

Once I've gotten my build environment to the point where I can just change my
core app (i.e., I've set up the `Dockerfile` and `docker-compose.yml` file), I
basically just run

```
fig up -d

fig logs
# observe my project, fix what's wrong
^C <-- quits the logs
fig stop && fig rm -v && fig build web && fig up -d

fig logs
# observe my project, fix what's wrong
^C
fig stop && fig rm -v && fig build web && fig up -d

...
```

It helps to understand the difference between "images" and "containers". There
are plenty of ways to remember the difference between the two, but I like the
object-oriented programming analogy: "images" are to classes like "containers"
are to objects. The analogy isn't quite perfect, but it's close enough. We
create a new container (object) every time we run (instantiate) the image
(class). Images come with an understanding of what's common to all containers
(like the root file system, software dependencies, and app files), just like
classes know their constructor and member methods.


## More Tips

Two blog posts were particularly helpful in compiling this list of commands; I'd
be remiss to not acknowledge their wonderful work:

- [Docker tricks of the trade and best practices thoughts][tricks]
- [Spring cleaning of your Docker containers][spring-cleaning]

I've entirely focused on the commands you can use to build, run, and manage your
Docker app in this post. The rest is just a matter of getting your `Dockerfile`
and `docker-compose.yml` to where you need them to be. For this, I'd recommend

- the Docker documentation on [Dockerfile best practices][dockerfile], as well as
- [this walkthrough][sample-workflow] for Dockerizing a sample app (in Node.js, but
the principles are generally applicable)

Apart from that, try to find examples of these files that you can adapt to your
needs.



[dc]: https://docs.docker.com/compose/
[fig]: https://fig.sh
[tricks]: http://www.carlboettiger.info/2014/08/29/docker-notes.html
[spring-cleaning]: http://odino.org/spring-cleaning-of-your-docker-containers/
[dockerfile]: https://docs.docker.com/articles/dockerfile_best-practices/
[sample-workflow]: http://anandmanisankar.com/posts/docker-container-nginx-node-redis-example/
