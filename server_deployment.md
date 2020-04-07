# Building and Deploying the Server Container

The server is packaged in a Single docker image which can be built locally using these files in the same directory:

* The godot binary
* the `.pck`
* the `run.sh` script
* the `Dockerfile`

Copy the `.pck` and Godot binary into this directory alongside the `Dockerfile`.

We can use docker to build the image and the resulting image can either be used locally or uploaded to a docker registry somewhere on the Internet for subsequent executions to pull down.

## Install Docker

To build the server image, you need to have docker installed. Follow the instructions for your OS to get the docker daemon running and installed. To verify it is running, you should see something like this when you run `docker ps`.

	$ docker ps
	CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              	PORTS               NAMES


## Build the Server Container Locally

There are two distinct steps to get the container running and serving on port 3000. Building and running.

To build the container, first `cd` into the `deploy/container/` directory so we are in the docker context. This is the directory being made available to docker when we build. Run the following command to build and tag the image.

	docker build -t fugitive-server .

The build process should indicate clearly whether things went wrong. A successful build will yield an image listed in the output of `docker images`.

	$ docker images
	REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
	fugitive-server     latest              fde7e12fa4d5        9 hours ago         148MB

## Run the Server Container Locally

You can run the server quickly locally to verify things are working before using it in the droplet. The run command here is important because it defines the running container's networking parameters. The container can also be run in a few different modes.

**Interactively with a shell**

This mode is good if you want to inspect the directory inside the container or run the server yourself, maybe changing run.sh or its arguments.

	docker run --rm -it --net=host fugitive-server /bin/bash
	
This should fire up the container and then place you in the `/root` directory with all the files from the docker context. All you'd need to do to run the server at this point is execute `run.sh` on the shell. Note that when you exit the container run in this manner, docker will stop the container (the `--rm` flag). 

**Interactively with the server running automatically**

This is good if you want to see live server output and close it quickly with Ctrl+C.

	docker run --rm -it --net=host fugitive-server
	
Just leave off the bash entrypoint on the end and the container will run as an executable, running the godot server right there in your terminal.

**As a daemon or background process**

This is how you're going to probably run it in the droplet.

	docker run -d --net=host fugitive-server
	
This tells docker to run the container as a background process. Like the above command variants, docker will give the container an ID and you can now reference the container by its ID in all your troubleshooting.

To stop the container, you will need the container ID or the silly name docker gives the container instance. In the troubleshooting example below, the container ID is `594605a780c5` and its name is `determined_pascal`.

```
whipper:container bill$ docker run -d --net=host fugitive-server
594605a780c585f0bf2a97a289c7d0854b043ede66de6174869a8676a841944f
whipper:container bill$
whipper:container bill$ docker ps
CONTAINER ID        IMAGE               COMMAND                   CREATED             STATUS              PORTS               NAMES
594605a780c5        fugitive-server     "/bin/sh -c \"/root/r…"   4 seconds ago       Up 3 seconds                            determined_pascal
whipper:container bill$
```

**Troubleshooting**

All the examples below use the container ID we noted above. Note that you can refer to a container ID by its first two or three characters in all these commands.

If you want to follow the log file as logging appears, you can add the `-f` flag to the log command. This will continue until you hit Ctrl+C.

```
whipper:container bill$ docker logs 594 -f
ERROR: initialize: No library set for this platform
   At: modules/gdnative/gdnative.cpp:290.
WARNING: _update_root_rect: Font oversampling only works with the resize modes 'Keep Width', 'Keep Height', and 'Expand'.
   At: scene/main/scene_tree.cpp:1153.
WARNING: _update_root_rect: Font oversampling does not work in 'Viewport' stretch mode, only '2D'.
   At: scene/main/scene_tree.cpp:1236.
^C
whipper:container bill$
```

To just show the logs from the container, drop the `-f` flag.

If you need to understand how the networking or container parameters look, use:

	docker inspect 594

## Creating the Droplet

The droplet is like a small virtual machine with the Docker daemon installed and running. It provides local user accounts, a network connection to the Internet, and a firewall.

To get the server running, you create a droplet with the following parameters:

1. Choose an image > marketplace > Docker (version name)
2. Choose a plan > CPU Optimized
3. Cost > $40/mo
4. Block storage - none
5. Region - San Francisco
6. Additional options > check box for `monitoring`
7. Authentication > We SHOULD create ssh keys, but select a one-time password
8. Hostname - "fugitive-server"
9. Backups - none

This can be done manually for now, but there is an API where this could be fully automated.

Once you have the droplet created, use your emailed one time password (or SSH key) to log in. It will force you to select a new root password on the first login. Now you need to build the container image.

1. Copy all four needed files into the current directory in the droplet. You will probably be sitting in `/root`, running as the root user.
2. Run the container build using the command noted in the above build section.
3. Punch some holes in the firewall on the droplet to allow port 3000.

   ```
	ufw allow 3000/tcp
	ufw allow 3000/udp
   ```
   
4. Execute the container in any of the modes listed above. You probably want daemon mode.
5. Note the public IP of the droplet. This should be listed in the digitalocean dashboard or in the droplet as the address of interface `eth0`. Try connecting your client to that server IP now.

If you want to see traffic coming into the server on port 3000, you can use tcpdump.

	tcpdump -vvni eth0 port 3000

To shut down the container, you just issue `docker stop <container ID or name>`. You should be able to destroy the droplet too, as long as you have the binary and .pck files saved somewhere else.