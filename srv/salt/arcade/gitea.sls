volume_gitea:
  docker_volume.present:
    - name: volume_gitea
    - driver: nfs
    - driver_opts:
      - share: nas.local:/ArcadeData/gitea
