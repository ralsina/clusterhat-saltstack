# States for the transmission service

{% if pillar.get('stacks').get('transmission', False) %}
/home/pi/transmission.yml:
  file.managed:
    - source: salt://arcade/transmission/transmission.yml

deploy_transmission:
  cmd.run:
    - name: docker stack deploy --compose-file /home/pi/transmission.yml transmission

{% else %}
/home/pi/transmission.yml:
  file.absent

deploy_transmission:
  cmd.run:
    - name: docker stack rm transmission
    - unless: docker stack ls | grep transmission && false
{% endif %}
