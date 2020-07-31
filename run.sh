docker build --no-cache -t alpaca .
docker container prune -f
docker run --name alpaca -v "$PWD/:/home:rw" -ti -d alpaca