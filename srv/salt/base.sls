# Install basic stuff
common_packages:
  pkg.installed:
    - pkgs:
      - vim
      - kitty-terminfo
      - fish
      - nmap
      - salt-minion
      - python3-pyinotify
      - jq
      - picocom

# Let me in
/home/pi/.ssh/authorized_keys:
  file.managed:
  - user: pi
  - group: pi
  - mode: 600
  - source: salt://ssh/authorized_keys
  - makedirs: true

# Restart salt-minion if salt config changes
#salt-minion:
#  service.running:
#    - onchanges:
#      - file: /etc/salt/**

# Fix hostname
resolve_self:
  host.present:
    - ip: 
      - 127.0.1.1
      - 127.0.0.1
      - ::1
    - names: 
      - {{ grains['host'] }}
  
resolve_salt_master:
  host.present:
    - ip:
      - {{pillar.get('salt_master_ip')}}
    - names:
      - {{pillar.get('salt_master')}}

# Set timezone
timezone: {}  # Specific timezone defined in pillar
