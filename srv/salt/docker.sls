install_docker:
  cmd.run:
    - name: curl -sSL https://get.docker.com | sh
    - creates: /etc/docker/key.json

docker-volume-netshare:
  pkg.installed:
    - sources:
      - docker-volume-netshare: https://github.com/ContainX/docker-volume-netshare/releases/download/v0.36/docker-volume-netshare_0.36_armhf.deb
  service.running:
    - enable: true
    - watch:
      - pkg: docker-volume-netshare

pi:
  user.present:
    - fullname: Pi
    - shell: /usr/bin/fish
    - groups:
      - docker
      - pi 
      - adm 
      - dialout
      - cdrom
      - sudo
      - audio
      - video
      - plugdev
      - games
      - users
      - input
      - netdev 
      - gpio 
      - i2c 
      - spi
    - require:
      - cmd: install_docker

