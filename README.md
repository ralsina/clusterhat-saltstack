# clusterhat-saltstack

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

## Instructions (assumes you have gone over [Salt in 10 minutes](https://docs.saltproject.io/en/latest/topics/tutorials/walkthrough.html))

* Setup a salt master
* Put this project's `srv/` in your `/srv/` or whatever
* Copy the `roster` file to `/etc/salt/roster`

**REVIEW `/etc/salt/roster` and `srv/pillar/data.sls`**

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

* `salt-ssh -i -v -l trace -thin-extra-modules=salt 'pacman' state.apply controller`
* `salt-ssh -i pacman -r 'sudo reboot'`
* `salt-key -L` and repeat until `pacman` is booted and you see a key called `pacman`
  as `Unaccepted`
* `salt-key -a pacman`

At this point, your controller is completely configured.

Log into the controller and turn on your pi zeros. For example 

* `ssh pi@pacman.local`
* `clusterctrl on p1 p2 p3`

Wait until all the zeros are booted and accessible via ssh as `inky.local`, 
`pinky.local` and `blinky.local`

Setup `salt-minion` into all workers:

* `salt-ssh -i -v -l trace -t --thin-extra-modules=salt '*inky' state.apply base`

Reboot all workers

* `salt-ssh -i '*inky' -r 'sudo reboot'`
* `salt-key -L` and repeat until you see `Unaccepted` keys for inky, pinky and blinky
* `salt-key -A` accepts all keys

Perform final configuration in all workers:

* `salt '*inky' state.apply worker`

And that's it. You now have a 4-node docker swarm.

