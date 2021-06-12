import subprocess
import shlex


def worker_token():
    # Calculate worker join token if this is a swarm master
    try:
        t = (
            subprocess.check_output(shlex.split("docker swarm join-token worker"))
            .splitlines()[2]
            .strip()
        )
        return {"worker_token": t}
    except:
        return {"worker_token", "/bin/false"}


def swarm_join_command():
    # Get the worker join command from pacman
    try:
        t = (
            subprocess.check_output(shlex.split("salt pacman grains.get worker_token"))
            .splitlines()[2]
            .strip()
        )
    except Exception as e:
        return {"swarm_join_command": str(e)}
