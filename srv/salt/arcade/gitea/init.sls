# States for the gitea service (TBD)

{% if pillar.get('stacks').get('gitea', False) %}
/home/pi/gitea.yml:
  file.managed:
    - source: salt://arcade/gitea/gitea.yml

deploy_gitea:
  cmd.run:
    - name: docker stack deploy --volume-driver nfs --compose-file /home/pi/gitea.yml gitea
    - onchanges:
      - file: /home/pi/gitea.yml

{% else %}
/home/pi/gitea.yml:
  file.absent

deploy_gitea:
  cmd.run:
    - name: docker stack rm gitea
    - unless: docker stack ls | grep gitea && false
{% endif %}