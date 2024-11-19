#!/bin/sh
set -e

cat >~/.ossutilconfig<<EFO
[Credentials]
language=CH
accessKeyID=${accessKeyID}
accessKeySecret=${accessKeySecret}
endpoint=${endpoint}
EFO

if [ "${1#-}" != "$1" ]; then
	set -- ossutil64 "$@"
fi

exec "$@"