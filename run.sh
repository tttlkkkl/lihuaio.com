#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- ossutil64 "$@"
fi

cat >~/.ossutilconfig<<EFO
[Credentials]
language=CH
accessKeyID=${accessKeyID}
accessKeySecret=${accessKeySecret}
endpoint=${endpoint}
EFO
exec "$@"