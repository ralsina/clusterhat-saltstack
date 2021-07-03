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
  - name: /var/lib/clusterctrl/nfs/p{{loop.index}}/etc/salt/minion
  - source: salt://controller/salt_minion
  - makedirs: true
  - template: jinja
  - defaults:
    salt_master: "salt"  # Same default as salt
powerup_p{{loop.index}}:
  cmd.run:
  - name: clusterctrl on p{{loop.index}}
autologin_p{{loop.index}}:  # Automatic login without user/password over tty
  file.managed:
  - name: /var/lib/clusterctrl/nfs/p{{loop.index}}/lib/systemd/system/getty@.service
  - source: salt://controller/getty@.service
disable_ssh_password_login_p{{loop.index}}:  # Only allow logging in with public key
  file.managet:
  - name: /var/lib/clusterctrl/nfs/p{{loop.index}}/etc/ssh/sshd_config
  - source: salt://controller/sshd_config
{% endfor %}


