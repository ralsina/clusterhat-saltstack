# Name or IP of the salt master
salt_master: salma.local

# Names of the clusterhat workers in order
workers:
  - inky
  - pinky
  - blinky

# Just so I don't have to tweak it on each machine
timezone:
  name: 'America/Argentina/Buenos_Aires'
  utc: true

# List of all stacks available. If set to true
# they will be deployed in the swarm cluster if set to True
# If they are not here or are set to False, they will not be
# running

stacks:
  gitea: True
