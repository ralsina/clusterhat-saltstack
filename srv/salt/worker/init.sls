# Setup a swarm worker

include: 
  - base          # Basic packages
  - worker.swarm  # Configure docker and join the swarm as worker

/usr/bin/docker-volume-netshare:  # ARMv5 binary for Rpi Zero
  file.managed:
  - source: salt://worker/docker-volume-netshare