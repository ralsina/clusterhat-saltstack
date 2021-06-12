install_docker:
  cmd.run:
    - name: curl -sSL https://get.docker.com | sh
    - creates: /etc/docker/key.json

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

