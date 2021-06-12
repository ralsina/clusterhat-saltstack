include:
- docker  # Setup docker itself

# Start a swarm
docker swarm init --advertise-addr 172.19.180.254:
  cmd.run:
    - unless: 'docker info | grep "Swarm: active"'

# Setp salt mine to expose swarm join command
/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt://controller/mine.conf
    - makedirs: True
  
