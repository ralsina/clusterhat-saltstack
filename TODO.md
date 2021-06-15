# Stuff I have not done yet

* Rewrite the docker swarm stuff using salt.modules.swarm
  which I didn't know existed
* Add some services as second stage (say gitea?) [Partial]
* Add portainer or some other manager UI
* Use beacons/reactors to restart salt-minion when salt config is changed
* Add NFS volumes for docker
* Implement some sort of cluster dashboard (should be fun)
* Add docs about adding other nodes to the docker cluster (my Mele 1000!)
* Something to do about file deduplication for the NFS server

* Cut down on software installed on the zeros
* Node labels (see https://docs.docker.com/engine/swarm/manage-nodes/#add-or-remove-label-metadata) from pillar

* Re-run from scratch with CBRIDGE (new highstate on boot may save steps)
* Run/debug with CNAT