docker build -t alpaca .
docker run -v "$PWD/conf:/ansible/playbooks/:rw" --rm -ti alpaca
