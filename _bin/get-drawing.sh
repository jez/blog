#!/usr/bin/env bash
set -euo pipefail

# ----- helper functions ------------------------------------------------------

src_default="$HOME/Dropbox/iPad/Pasted image.png"
usage() {
  cat <<EOF

get-drawing.sh: Prep a drawing exported from Notes.app

Usage:
  get-drawing.sh [options]  [<src>] <dest>

Arguments:
  <source>     Which drawing to prep.
               [default: "$src_default"]
  <dest>       Where to put the image. Probably should start with assets/img/

Options:
  -f, --force  Overwrite any existing file at <dest>
  -h, --help   Show this help message

EOF
}

# ----- option parsing --------------------------------------------------------

src=
dest=
force=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -h,--help)
      usage
      exit 0
      ;;
    -f,--force)
      force=true
      shift
      ;;
    -*)
      >&2 echo "Unrecognized option: $1"
      >&2 usage
      exit 1
      ;;
    *)
      if [ "$dest" = "" ]; then
        dest="$1"
      elif [ "$src" = "" ]; then
        src="$dest"
        dest="$1"
      else
        >&2 echo "Extra positional argument: $1"
        >&2 usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [ "$dest" = "" ]; then
  >&2 echo "Missing required <dest> location"
  >&2 usage
  exit 1
fi

if [ -e "$dest" ] && ! "$force"; then
  >&2 echo "$dest: Already exists. Use --force to overwrite."
fi

if [ "$src" = "" ]; then
  src="$src_default"
fi

# ----- main ------------------------------------------------------------------

for i in {1..15}; do
  if [ -e "$src" ]; then
    mv "$src" "$dest"
    break
  fi

  sleep 1
done
mogrify -trim "$dest"
markdown="$(identify -format "\![](/$dest){style=\"max-width: %[fx:w/2]px;\"}" "$dest")"

echo "$markdown"
echo

if [ "$TMUX" != "" ]; then
  echo "$markdown" | tmux load-buffer -
  echo "(also copied to tmux clipboard)"
fi

echo "Done."
