#!/bin/bash -e

DOCKER_ARGUMENTS="-d"

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -i|--interactive)
    DOCKER_ARGUMENTS="-it"
    shift
  ;;
  -h|--help)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Run a local proxy for private Docker repository access."
    echo ""
    echo "Options:"
    echo ""
    echo "-h, --help          Show help"
    echo "-i, --interactive   Run in interactive mode"
    echo ""
    shift
  ;;
  *)
    echo "$key isn't a valid argument. Run ./run.sh --help to view the help file."
    shift
  ;;

esac
done

docker build -t conjur-registry-proxy .

PROXY_DOCKER_ID=$(docker ps -a -f name=conjur-registry-proxy -q)
if [[ $PROXY_DOCKER_ID ]] ; then
  docker stop $PROXY_DOCKER_ID
  docker rm $PROXY_DOCKER_ID
fi

# Ensure .netrc exists so docker doesn't create it as a directory
[[ ! -f ~/.netrc ]] && touch ~/.netrc

function whoami() {
  docker run --rm -v ~/.netrc:/root/.netrc --entrypoint conjur conjur-registry-proxy authn whoami
}

logged_in=$(whoami 2>/dev/null || true)
if [[ !($logged_in =~ account) && "$DOCKER_ARGUMENTS" == "-d" ]] ; then
  echo "Not logged in to Conjur, switching to interactive mode"
  DOCKER_ARGUMENTS="-it"
fi

docker run $DOCKER_ARGUMENTS --net=host \
    -v ~/.netrc:/root/.netrc \
    --name conjur-registry-proxy conjur-registry-proxy

if [[ $DOCKER_ARGUMENTS = "-d" ]] ; then
  echo ""
  echo "Your Docker proxy is ready to be used!"
  echo "You can stop it with the command: docker rm -f conjur-registry-proxy"
fi
