# clusterhat-saltstack

* [So, what is this thing?](#so-what-is-this-thing)
* [Setup Instructions](#setup-instructions)
* [Setup NFS Volumes](#setup-nfs-volumes)
* [Deploying](#deploying)
* [Run a command on a node](#run-a-command-on-a-node)
* [Updating all nodes](#updating-all-nodes)
* [Rebooting nodes](#rebooting-nodes)
* [Enabling and disabling stacks in the cluster](#enabling-and-disabling-stacks-in-the-cluster)
* [Creating Docker Stacks](#creating-docker-stacks)

## So, what is this thing?

A SaltStack setup to configure a ClusterHAT quickly.

The goal is to configure a whole ClusterHAT (Controller + up to 4 raspberry zeros)
completely with minimal manual intervention. It will still take a while, but
that's the computers problem.

* This setup will probably only be useful for me.
* Best case scenario is it will be useful for the roughly 5 other people
  who own [ClusterHAT](https://clusterhat.com/) boards.

But anyway, here it is. I will make a reasonable effort to keep it general :-)

The setup, as shipped, will configure a controller called `pacman`,
and three workers called `inky`, `pinky` and `blinky`. If you don't like that, you can change it in `roster` and `srv/pillar/data.sls`, and adjust commands accordingly.

This **needs** to be connected to your network via ethernet. If you only connect
via wifi, weird stuff will happen because the bridge is set on ethernet.

Yes, I *know* Swarm is old and obsolete and we should all be using Kubernetes or
whatever. It works for what I want to do :-)

## Setup Instructions 

Assuming you have gone over [Salt in 10 minutes)](https://docs.saltproject.io/en/latest/topics/tutorials/walkthrough.html):

* Setup a salt master
* Put this project's `srv/` in your `/srv/` or whatever
* Copy the `roster` file to `/etc/salt/roster`

**REVIEW `/etc/salt/roster` and `srv/pillar/data.sls`**

* Add the file_roots to your `/etc/salt/master`:

  ```yaml
    file_roots:
      base:
        - /srv/salt  # Or wherever you put them
        - /srv/formulas/timezone/
  ```

* Download the [ClusterHAT CBridge image](https://clusterctrl.com/setup-software) and flash into a SD card
* Create an empty `boot/ssh` file in it
* Put it in the controller and boot it

Assuming you have a working Avahi/Zeroconf/mDNS thing in your local network (you should!)
then the system should be accessible with `ssh pi@cbridge.local` (password is clusterctrl)

* SSH into the cluster controller
* Run `sudo raspi-config`
* In System Options set hostname to `pacman`
* In Performance Options set GPU memory to 16
* When asked, reboot

Now the system should be available via `ssh pi@pacman.local`

The rest of these instructions are to be executed in the salt controller.


Setup the controller and the NFS boot data for the workers. This will take a while:

* `salt-ssh -i -v -l trace --thin-extra-modules=salt 'pacman' state.apply controller`
* `salt-ssh -i pacman -r 'sudo reboot'`
* `salt-key -L` and repeat until `pacman` is booted and you see a key called `pacman`
  as `Unaccepted`
* `salt-key -a pacman`

At this point, your controller is completely configured.

Log into the controller and turn on your pi zeros. For example 

* `ssh pi@pacman.local`
* `sudo clusterctrl on p1 p2 p3`

Wait until all the zeros are booted and accessible via ssh as `inky.local`, 
`pinky.local` and `blinky.local`

Setup `salt-minion` into all workers:

* `salt-ssh -i -v -l trace -t --thin-extra-modules=salt '*inky' state.apply base`
* `salt-ssh '*inky' state.apply worker`

Reboot all workers

* `salt-ssh -i '*inky' -r 'sudo reboot'`
* `salt-key -L` and repeat until you see `Unaccepted` keys for inky, pinky and blinky
* `salt-key -A` accepts all keys

Perform final configuration in all workers:


### Optional

Update all the software in all the nodes to latest version:

* `salt '*' pkg.upgrade`

And that's it. You now have a 4-node docker swarm.

## Setup NFS Volumes

The goal of this cluster is to run stuff. The only storage so far is one 
SD card. So, we will need something else. Since I have a NAS, I am going to be
using [NFS storage.](https://sysadmins.co.za/docker-swarm-persistent-storage-with-nfs/)

* Make sure you have one largish disk with enough free space for whatever you want
  to persist in a machine that will be the NFS server.
* Share it with NFS (details are up to you)
* Make sure you can mount it and access its contents as user `pi` from all our 
  cluster nodes.

In my case the NFS server is called `nas.local` and the NFS share is `ArcadeData`:

```shell
pi@pacman ~> mkdir t
pi@pacman ~> sudo mount nas.local:/ArcadeData t
pi@pacman ~> df -h t
Filesystem             Size  Used Avail Use% Mounted on
nas.local:/ArcadeData  148G  6.1G  142G   5% /home/pi/t
pi@pacman ~> touch t/foo
pi@pacman ~> ls -l t/foo
-rw-r--r-- 1 pi pi 0 Jun 12 15:27 t/foo
pi@pacman ~> rm t/foo
pi@pacman ~> sudo umount t
```

## Deploying

To deploy your cluster, you need apply the "High state". That particular
bit of Salt jargon means running this:

`salt '*' state.apply`

You usually would run this after you change something in your configuration.

## Run a command on a node

Often you will want to run a command in a specific node, or all nodes 
of a "kind" or whatever.

To run a command, salt provides `cmd.run` which you use like this:

`salt target cmd.run "command arg1 arg2 ... argN"`

The tricky part is `target` so let's explain it a bit.

This configuration defines two roles, `controller` and `worker`, and four nodes:

* `pacman`: our only controller
* `inky`, `pinky` and `blinky`: our three workers.

With that in mind:

* To target all nodes, use the target `'*'` (yes, with the single quotes)
* To target a single node for which you know the name, use the name as target. For example: `blinky`
* To target by role, for example all workers: `-G roles:worker`

There are other ways to do this but for that you can go and learn Salt.## Updating all nodes

To update the software in a specific node, do this using the target node instead of `pacman`:

`salt pacman pkg.upgrade`

To update it on all nodes:

`salt '*' pkg.upgrade`

You should probably reboot them afterwards.
## Rebooting a swarm node

To reboot a single node, we need to "drain" it so it has no services running, and then mark it as active again later.

To do this using the target node instead of `inky`, but **DO** use `pacman` to drain the node first.

```
salt pacman cmd.run "docker node update --availability drain inky"
salt inky cmd.run sudo reboot
[Wait for reboot to end]
salt pacman cmd.run docker "node update --availability active inky"

```

To reboot them all ... **This will probably mess stuff up!**:

```
salt '*' cmd.run sudo reboot
```


## Enabling and disabling stacks in the cluster

You can think of a stack as an application (more details later). This 
projects includes the ones I use in my cluster, but you can add/remove/change them all you want.

In `srv/pillar/data.sls` there is a `stacks` section:

```yaml
stacks:
  gitea: True
```

If a stack is there and set to `True`, it will deploy to the swarm on the next deployment.

If it's not there or is set to `False`, it will be removed or not deployed as necessary.

## Creating Docker Stacks

A stack is a collection of services. A service is basically a container running something.

The way to deploy them is to create a "compose file" like this one for the 
`gitea` stack, which runs a single service called `gitea` and persists state in a volume called `volume_gitea`.

It also exposes two ports (3000 and 3022) which are forwarded to ports 3000 and 22 in the container.

```yaml
version: '3.8'

services:
  gitea:
    image: strobi/rpi-gitea:latest
    volumes:
      - volume_gitea:/data
    ports:
      - "3000:3000"
      - "3022:22"
    environment:
      - USER_UID=1000
      - USER_GID=1000
    deploy:
      replicas: 1
    logging:
      driver: "json-file"
      options:
        max-size: "50K"

volumes:
  volume_gitea:
    driver: nfs
    driver_opts:
      share: nas.local:/ArcadeData/gitea
```

Once you have compose files for your stacks, you can deploy them.

The "normal" way to deploy `gitea.yml` would be to run this in one of the managers:

`docker stack deploy --compose-file gitea.yml gitea`

Since we have Salt, we can make things easier. All of the Arcade cluster's 
stacks are defined in `srv/salt/arcade`, use them as examples.

This will ensure files are installed in the swarm manager in a reasonable place and deploy them.
