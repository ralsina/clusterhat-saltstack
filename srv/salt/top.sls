base:
  '*':
    - base
  'roles:controller':  # Our cluster controller
    - match: grain
    - controller       # Join docker swarm as master/manager
    
    # All stacks available to run on swarm.
    # Will deploy or not according to pillar config.
    - arcade

  'roles:worker':      # Our clusterhat workers
    - match: grain
    - worker           # Join docker swarm as workers
