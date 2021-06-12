# Setup the clusterhat controller
include: 
  - base 
  - docker
  - controller.swarm-manager
  - controller.setup_zeros  

# Set FORWARD iptables policy to ACCEPT because docker messes it up
accept forward:
  iptables.set_policy:
    - chain: FORWARD
    - policy: ACCEPT
    - save: True
  
# Reload iptables on cron because WTF debian?
/usr/sbin/netfilter-persistent restart:
  cron.present:
    - identifier: NETFILTER_HACK
    - user: root
    - minute: '*'


# Setup NFS server on pacman for the ghosts
/etc/exports:
  file.managed:
  - source: salt://controller/exports
nfs-kernel-server:
  service.running:
  - require: 
    - file: /etc/exports

# Assign controller role
/etc/salt/minion.d/grains.conf:
  file.managed:
  - source: salt://controller/controller_grains
  - makedirs: true


setup_controller_minion:
  file.managed:
  - name: /etc/salt/minion
  - source: salt://controller/salt_minion
  - makedirs: true
  - template: jinja
  - defaults:
    salt_master: "salt"  # Same default as salt
