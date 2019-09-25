docker build -t alpaca .
docker run --name alpaca -v "$PWD/:/home:rw" -ti -d alpaca
