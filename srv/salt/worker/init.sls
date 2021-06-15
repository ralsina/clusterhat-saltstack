# Setup a swarm worker

include: 
  - base          # Basic packages
  - worker.swarm  # Configure docker and join the swarm as worker

/usr/bin/docker-volume-netshare:  # ARMv5 binary for Rpi Zero
  file.managed:
  - source: salt://worker/docker-volume-netshare

# Setup dummy NFS volume so the plugin loads (is a bug, see https://github.com/ContainX/docker-volume-netshare/issues/48)
dummy_nfs:
  cmd.run: 
    - name: docker volume create --driver=nfs foo
    - unless: docker volume inspect foo
    