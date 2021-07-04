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

* Run/debug with CNAT instead of CBRIDGE

* Implement node label removing prior to re-adding them
  
  starting point: `docker node inspect inky | jq '.[0].Spec.Labels|keys'` 

* Make everything use the deployed registry
* Investigate alternative OS for the zeros. Alpine?
* Implement logging server


* Automate creation of traefik-public network (docker_network.present doesn't really work in swarm)