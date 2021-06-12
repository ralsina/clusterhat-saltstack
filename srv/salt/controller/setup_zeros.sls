# NFS boot image for Zeros
/home/pi/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz:
  file.managed:
  - source: salt://controller/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz
  
# Setup raspberry zero NFS boots (p1/2/3/4)
{% for name in pillar.get('workers') %}
extract_p{{loop.index}}:
  archive.extracted:
  - name: /var/lib/clusterctrl/nfs/p{{loop.index}}
  - source: /home/pi/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz
  - if_missing: /var/lib/clusterctrl/nfs/p{{loop.index}}/etc
  - require:
    - file: /home/pi/2020-12-02-1-ClusterCTRL-armhf-lite-usbboot.tar.xz
init_usbboot_p{{loop.index}}:
  cmd.run:
  - name: usbboot-init {{loop.index}} && touch /var/lib/clusterctrl/nfs/p{{loop.index}}/boot/ssh && echo {{name}} > /var/lib/clusterctrl/nfs/p{{loop.index}}/etc/hostname
  - require:
    - archive: /var/lib/clusterctrl/nfs/p{{loop.index}}
  - unless: grep -q {{name}} /var/lib/clusterctrl/nfs/p{{loop.index}}/etc/hostname
setup_ssh_key_p{{loop.index}}:
  file.managed:
  - name: /var/lib/clusterctrl/nfs/p{{loop.index}}/home/pi/.ssh/authorized_keys
  - user: pi
  - group: pi
  - mode: 600
  - source: salt://ssh/authorized_keys
  - makedirs: true
setup_grains_p{{loop.index}}:
  file.managed:
  - name: /var/lib/clusterctrl/nfs/p{{loop.index}}/etc/salt/minion.d/grains.conf
  - source: salt://controller/worker_grains
  - makedirs: true
setup_salt_minion_p{{loop.index}}:
  file.managed:
  - name: /etc/salt/minion
  - source: salt://controller/salt_minion
  - makedirs: true
  - template: jinja
  - defaults:
    salt_master: "salt"  # Same default as salt
{% endfor %}
