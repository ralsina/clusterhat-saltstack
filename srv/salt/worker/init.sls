# Setup a swarm worker

include: 
  - base          # Basic packages
  - worker.swarm  # Configure docker and join the swarm as worker
