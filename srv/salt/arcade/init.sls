# Configure all docker stacks available


include:
  {% for stack in salt['cp.list_master_dirs'](prefix='arcade')[1:] %}
  - arcade.{{stack.split('/')[-1]}}
  {% endfor %}