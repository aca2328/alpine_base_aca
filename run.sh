docker container prune -f
docker run --name alpaca -v "$PWD/:/home:rw" -v /var/run/docker.sock:/var/run/docker.sock -ti -d aca2328/alpaca:multi-arch