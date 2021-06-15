# States for the registry service (TBD)

{% if pillar.get('stacks').get('registry', False) %}
/home/pi/registry.yml:
  file.managed:
    - source: salt://arcade/registry/registry.yml

deploy_registry:
  cmd.run:
    - name: docker stack deploy --compose-file /home/pi/registry.yml registry
    - onchanges:
      - file: /home/pi/registry.yml

{% else %}
/home/pi/registry.yml:
  file.absent

deploy_registry:
  cmd.run:
    - name: docker stack rm registry
    - unless: docker stack ls | grep registry && false
{% endif %}