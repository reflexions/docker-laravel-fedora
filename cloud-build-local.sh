# -bind-mount-source and _MOUNT_NAME are a workaround
# https://gist.github.com/dmcguire81/c9e8c20248ec1f7f6cc656fbae124d4d

# note: realpath isn't always installed, so use pwd in subshell instead
script_dir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" || exit 1
cd "$script_dir" || exit 1


# note: E2_HIGHCPU_8 doesn't work in cloud-build-local (but N1_HIGHCPU_32 does)
from=" machineType: 'E2_HIGHCPU_8'"
to=" machineType: 'N1_HIGHCPU_32'"

function restore_yaml() {
	# put back the original machineType
	sed -i "s/$to/$from/" cloudbuild.yaml
}

# trap ctrl-c and call restore_yaml()
trap restore_yaml INT

sed -i "s/$from/$to/" cloudbuild.yaml

gcloud config set project reflexions-docker-laravel
time cloud-build-local \
	-bind-mount-source \
	--dryrun=false \
	--substitutions BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)",\
COMMIT_SHA="$(git rev-parse HEAD)",\
_PLATFORMS=linux/amd64,\
_OS=centos-9,\
_PHP_VERSION=8.2,\
_NODE_MAJOR_VERSION=18,\
_WITH_GCLOUD=1,\
_SQUASHED=0 \
	.

# can't get it to accept
# _PLATFORMS=linux/amd64,linux/amd64/v2,linux/arm64

restore_yaml
