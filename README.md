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
* [Adding a zero or reconfiguring one](#adding-a-zero-or-reconfiguring-one)

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
via wifi, weird stuff may happen, and I have NOT tested it, ok?

Yes, I *know* Swarm is old and obsolete and we should all be using Kubernetes or
whatever. It works for what I want to do :-)

## Hardware Required

This is not "required", it's just what I got. If you don't have one of these
things in most cases you can tweak things around it. For example, if you 
don'thave a thumb drive, you can use a larger SD card on the controller, 
and so on.

* A "large" Raspberry Pi (say, a 3 or a 4) as the cluster controller
* 1 or more "small" Raspberry Pis (zero or zero w)
* 1 ClusterHat to connect them all together
* 1 SD card to boot the controller from
* 1 "large" NFS server (depending on what you want to do)

## Preparation

Before starting to install this, you want to adjust a few things.

* Depending on how many zeros you are setting up:
  
  * Edit `roster`
  * Edit `srv/pillar/data.sls` (workers, labels)

* If it's an initial setup, you probably want to start without any stacks

  * Edit `srv/pillar/data.sls` (stacks)

## Setup NFS Volumes

The goal of this cluster is to run stuff. The only storage so far is one 
SD card. So, we will need something else. Since I have a NAS, I am going to be
using [NFS storage.](https://sysadmins.co.za/docker-swarm-persistent-storage-with-nfs/)

* Make sure you have one largish disk with enough free space for whatever you want
  to persist in a machine that will be the NFS server.
* Share it via NFS (details are up to you)
* Make sure you can mount it and access its contents as user `pi`

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

* Download the [ClusterHAT CNAT image](https://clusterctrl.com/setup-software) and flash into a SD card
* Create an empty `boot/ssh` file in it
* Put it in the controller and boot it

Assuming you have a working Avahi/Zeroconf/mDNS thing in your local network (you should!)
then the system should be accessible with `ssh pi@cnat.local` (password is clusterctrl)

* SSH into the cluster controller
* Run `sudo raspi-config`
* In System Options set hostname to `pacman`
* In Performance Options set GPU memory to 16
* When asked, reboot

Now the system should be available via `ssh pi@pacman.local`

*This could be a good moment to verify that you can mount and use your NFS disks
from the controller.*

**The rest of these instructions are to be executed in the salt controller.**

Setup SSH jump host so we can later access inky pinky and blinky by SSH even though they are
behind NAT. Just put this in `/etc/ssh/ssh_config` or `~/.ssh/config` for whatever 
user will use `salt-ssh` (probably root). Yes, this is very slightly insecure.
Your choice.

```
### Access to ClusterHat Zeros

Host pacman
  HostName pacman.local
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ForwardX11 no

Host inky
  HostName inky.local
  ProxyJump pi@pacman
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ForwardX11 no
Host pinky      
  HostName pinky.local
  ProxyJump pi@pacman
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ForwardX11 no
Host blinky
  HostName blinky.local   
  ProxyJump pi@pacman
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ForwardX11 no
```

**Make sure the salt-ssh user can login into pi@pacman.local without a password!**

Setup the controller and the NFS boot data for the workers. This will take a while 
(as in, maybe half an hour!):

* `salt-ssh -i -v -l trace --thin-extra-modules=salt 'pacman' state.apply controller`
* `salt-ssh -i pacman -r 'sudo reboot'`
* `salt-key -L` and repeat until `pacman` is booted and you see a key called `pacman`
  as `Unaccepted`
* `salt-key -a pacman`

At this point: 

* Your controller is completely configured and running salt-minion.
* Your zeros are booting.

Wait until all the zeros are booted and accessible via ssh as `inky`, 
`pinky` and `blinky` using `pacman` as jump host:

```
$ ssh pi@blinky
Warning: Permanently added 'pacman.local' (ED25519) to the list of known hosts.
Warning: Permanently added 'blinky.local' (ED25519) to the list of known hosts.
Linux blinky 5.4.79+ #1373 Mon Nov 23 13:18:15 GMT 2020 armv6l

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Mon Jul  5 16:08:59 2021 from 172.19.181.254
pi@blinky:~$ 
```

Setup `salt-minion` into all workers (again, this *will* take a while):

* `salt-ssh -i -v -l trace -t --thin-extra-modules=salt '*inky' state.apply base`

Reboot all workers and connect them to the salt master:

* `salt-ssh -i '*inky' -r 'sudo reboot'`
* `salt-key -L` and repeat until you see `Unaccepted` keys for inky, pinky and blinky
* `salt-key -A` accepts all keys

**At this point everything is installed and configured.**

### Optional

Update all the software in all the nodes to latest version:

* `salt '*' pkg.upgrade`

And that's it. You now have a 4-node docker swarm.

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

To do this using the target node instead of `inky`, but **DO** use `pacman` as the target to drain the node.

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

## Adding a zero or reconfiguring one

Sometimes you need to add or reconfigure a pi zero from scratch on a running cluster.

Since there isn't any important state on the zero's filesystem you can just, in this example
for a p4 called clyde:

```
$ rm -rf /var/lib/clusterctrl/nfs/p4/*  # Remove anything that my be there
$ salt pacman state.apply               # Set controller to "high" state
$                                       # Setup salt minion on clyde
$ salt-ssh -i -v -l trace -t --thin-extra-modules=salt clyde state.apply base
$ salt-ssh -i clyde -r 'sudo reboot'    # Reboot clyde
$ salt clyde state.apply                # Set clyde to "high" state
```

And then accepting the new minion key in `salt-key`.

**Caveats:** you may run into trouble in some spots because the ssh key for that
host may have changed, handle accordingly.

## Accessing the services

Some services need nothing special because they are unique. For example, we are using 
[CoreDns](https://coredns.io/) to provide DNS. We are not going to run two of those
so they are exposed in port 53 UDP and that's it.

On the other hand, some services have overlap. Specially websites.

For those, we use hostnames. For example, for gitea it's `gitea.cluster` and for
traefik it's `traefik.cluster`.

Then, CoreDns will make ANY `whatever.cluster` point to the cluster's external
IP address, so it should just work.

However, this means you need to make your computer use the cluster as your DNS server, or setup a bunch of host entries in your computer. Sorry, no idea how to make this simpler yet.
