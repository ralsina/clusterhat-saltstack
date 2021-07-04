# States for the dashboard service

{% if pillar.get('stacks').get('dashboard', False) %}
/home/pi/dashboard.yml:
  file.managed:
    - source: salt://arcade/dashboard/dashboard.yml

deploy_dashboard:
  cmd.run:
    - name: docker stack deploy --compose-file /home/pi/dashboard.yml dashboard

{% else %}
/home/pi/dashboard.yml:
  file.absent

deploy_dashboard:
  cmd.run:
    - name: docker stack rm dashboard
    - unless: docker stack ls | grep dashboard && false
{% endif %}