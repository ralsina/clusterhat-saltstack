include: 
  - docker

join_swarm:
  cmd.run:
    - name: {{ salt['mine.get']('pacman', 'cmd.run')['pacman'].splitlines()[-1] }}
    - unless: 'docker info || echo "Swarm: active" | grep "Swarm: active"'
