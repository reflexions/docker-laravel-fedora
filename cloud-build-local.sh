# -bind-mount-source and _MOUNT_NAME are a workaround
# https://gist.github.com/dmcguire81/c9e8c20248ec1f7f6cc656fbae124d4d

# note: realpath isn't always installed, so use pwd in subshell instead
script_dir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" || exit 1
cd "$script_dir" || exit 1


# note: E2_HIGHCPU_8 doesn't work in cloud-build-local (but N1_HIGHCPU_32 does)
from=" machineType: 'E2_HIGHCPU_8'"
to=" machineType: 'N1_HIGHCPU_32'"
from2="  pool:"
to2="#  pool:"
from3="    name: 'projects"
to3="#    name: 'projects"

function restore_yaml() {
	# put back the original machineType
	sed -i "s/$to/$from/" cloudbuild.yaml
	sed -i "s/$to2/$from2/" cloudbuild.yaml
	sed -i "s/$to3/$from3/" cloudbuild.yaml
}

# trap ctrl-c and call restore_yaml()
trap restore_yaml INT

sed -i "s/$from/$to/" cloudbuild.yaml
sed -i "s/$from2/$to2/" cloudbuild.yaml
sed -i "s/$from3/$to3/" cloudbuild.yaml

source ./gcloud.env.sh
export CLOUDSDK_CORE_PROJECT=reflexions-docker-laravel
#gcloud config set project "${CLOUDSDK_CORE_PROJECT}"

docker pull us-central1-docker.pkg.dev/docker-with-gcloud-395321/docker-with-gcloud/docker-with-gcloud:latest

time cloud-build-local \
	-bind-mount-source \
	--dryrun=false \
	--substitutions BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)",\
COMMIT_SHA="$(git rev-parse HEAD)",\
_PLATFORMS=${PLATFORMS-linux/amd64},\
_OS=${OS-centos-9},\
_PHP_VERSION=${PHP-8.3},\
_NODE_MAJOR_VERSION=${NODE-22},\
_WITH_GCLOUD=${WITH_GCLOUD-1},\
_SQUASHED=0 \
	.

# can't get it to accept
# _PLATFORMS=linux/amd64,linux/amd64/v2,linux/arm64
# have to build outside of cloud-build-local (or override the platform default in cloudbuild.yaml)
# e.g. docker buildx build --progress plain --platform "linux/amd64,linux/amd64/v3" --file Dockerfile-centos-9  --target updates-installed .
# but that alone won't let you emulate a different platform (that's where qemu comes in)

restore_yaml
