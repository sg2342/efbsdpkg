#!/bin/sh -e
name=efbsdpkg
comment="efbsdpkg sample"
uid=607
gid=607

[ -z "$REBAR3" ] && REBAR3=rebar3

rm -rf _build
$REBAR3 as prod tar --vm_args pkg/vm.args --sys_config pkg/sys.config

basedir=$(realpath "$(dirname "$0")")
pdir=$basedir/pkg
tmpd=$basedir/_build/prod/stage
manifest=$tmpd/+MANIFEST
rootdir=$tmpd/rootdir
appdir=$rootdir/usr/local/lib/$name
rcdir=$rootdir/usr/local/etc/rc.d

rel_vsn=$(cut -f 2 -d " " "$basedir"/_build/prod/rel/"$name"/releases/start_erl.data)
archive="$basedir"/_build/prod/rel/"$name"/"$name"-"$rel_vsn".tar.gz


mkdir -p "$rcdir" "$appdir"/bin

# stage rc script and jntool
sed -e "s:%%NAME%%:${name}:g" "$pdir"/rc > "$tmpd"/"$name"
sed -e "s:%%NAME%%:${name}:g" "$pdir"/jntool > "$tmpd"/jntool
install -U "$tmpd"/"$name" "$rcdir"/"$name"
install -U "$tmpd"/jntool "$appdir"/bin/jntool

# stage release
tar -C "$appdir" -xf "$archive"

# create Manifest
flatsize=$(find "$rootdir" -type f -exec stat -f %z {} + |
        awk 'BEGIN {s=0} {s+=$1} END {print s}')

sed -e "s:%%FLATSIZE%%:${flatsize}:" \
    -e "s:%%VERSION_NUM%%:${rel_vsn}:" \
    -e "s:%%COMMENT%%:${comment}:" \
    -e "s:%%NAME%%:${name}:g" \
    -e "s:%%UID%%:${uid}:g" \
    -e "s:%%GID%%:${gid}:g" \
    "$pdir"/MANIFEST > "$manifest"

{
    printf '\nfiles {\n'
    find "$rootdir" -type f -exec sha256 -r {} + | sort |
 awk '{print "    \"" $2 "\": \"" $1 "\"," }'
    find "$rootdir" -type l | sort |
 awk "{print \"    \"\$1 \": -,\"}"
    printf '}\n'
} | sed -e "s:${rootdir}::" >> "$manifest"

# package
SOURCE_DATE_EPOCH=$(git log -1 --pretty=format:%ct)
export SOURCE_DATE_EPOCH
pkg create -r "$rootdir" -M "$manifest" -o "$basedir"/_build/prod
