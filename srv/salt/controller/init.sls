# Setup the clusterhat controller
  
include: 
  - base 
  - docker
  - controller.swarm-manager

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
  
# NFS boot image for Zeros
/home/pi/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz:
  file.managed:
  - source: salt://controller/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz
  
# Setup 4 zero NFS boots (p1/2/3/4)
{% for n, nombre in [(1, "inky"), (2, "pinky"), (3, "blinky")] %}
extract_p{{n}}:
  archive.extracted:
  - name: /var/lib/clusterctrl/nfs/p{{n}}
  - source: /home/pi/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz
  - if_missing: /var/lib/clusterctrl/nfs/p{{n}}/etc
  - require:
    - file: /home/pi/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz
init_usbboot_p{{n}}:
  cmd.run:
  - name: usbboot-init {{n}} && touch /var/lib/clusterctrl/nfs/p{{n}}/boot/ssh && echo {{nombre}} > /var/lib/clusterctrl/nfs/p{{n}}/etc/hostname
  - require:
    - archive: /var/lib/clusterctrl/nfs/p{{n}}
  - unless: grep -q {{nombre}} /var/lib/clusterctrl/nfs/p{{n}}/etc/hostname
setup_ssh_key_p{{n}}:
  file.managed:
  - name: /var/lib/clusterctrl/nfs/p{{n}}/home/pi/.ssh/authorized_keys
  - user: pi
  - group: pi
  - mode: 600
  - source: salt://ssh/authorized_keys
  - makedirs: true
setup_grains_p{{n}}:
  file.managed:
  - name: /var/lib/clusterctrl/nfs/p{{n}}/etc/salt/minion.d/grains.conf
  - source: salt://controller/worker_grains
  - makedirs: true
setup_salt_minion_p{{n}}:
  file.managed:
  - name: /var/lib/clusterctrl/nfs/p{{n}}/etc/salt/minion
  - source: salt://controller/salt_minion
  - makedirs: true
{% endfor %}

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
