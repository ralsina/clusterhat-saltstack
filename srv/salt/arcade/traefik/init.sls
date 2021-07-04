# States for the registry service (TBD)

{% if pillar.get('stacks').get('traefik', False) %}
/home/pi/traefik.yml:
  file.managed:
    - source: salt://arcade/traefik/traefik.yml

deploy_traefik:  
    cmd.run:
    - name: docker stack deploy --compose-file /home/pi/traefik.yml traefik

{% else %}
/home/pi/traefik.yml:
  file.absent

# traefik_public:
#   docker_network.absent

deploy_traefik:
  cmd.run:
    - name: docker stack rm traefik
    - unless: docker stack ls | grep traefik && false
{% endif %}