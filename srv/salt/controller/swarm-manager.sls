include:
- docker  # Setup docker itself

# Start a swarm
docker swarm init --advertise-addr 172.19.180.254:
  cmd.run:
    - unless: 'docker info | grep "Swarm: active"'

