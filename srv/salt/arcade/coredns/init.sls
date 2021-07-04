# States for the gitea service (TBD)

{% if pillar.get('stacks').get('coredns', False) %}
/home/pi/coredns.yml:
  file.managed:
    - source: salt://arcade/coredns/coredns.yml

# Config file
/mnt/nas/coredns/Corefile:
  file.managed:
    - source: salt://arcade/coredns/Corefile
/mnt/nas/coredns/cluster.db:
  file.managed:
    - source: salt://arcade/coredns/cluster.db

deploy_coredns:
  cmd.run:
    - name: docker stack deploy --compose-file /home/pi/coredns.yml coredns

{% else %}
/home/pi/coredns.yml:
  file.absent

deploy_coredns:
  cmd.run:
    - name: docker stack rm coredns
    - unless: docker stack ls | grep coredns && false
{% endif %}