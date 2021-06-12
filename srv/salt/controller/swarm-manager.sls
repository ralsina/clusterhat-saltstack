# Docker swarm setup
docker swarm init --advertise-addr 172.19.180.254:
  cmd.run:
    - unless: 'docker info | grep "Swarm: active"'

/etc/salt/minion.d/mine.conf:
  file.managed:
    - source: salt://controller/mine.conf
    - makedirs: True
  
