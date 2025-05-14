#!/bin/bash
set -e

BASE_DIR="/opt/kiryuxa"
mkdir -p "$BASE_DIR"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 {awss3syncLarge|s3cmdsync|s4cmdsync|rclonesync|mcmirror} [folder_name]"
  exit 1
fi

sync_tool="$1"

case "$sync_tool" in
  awss3syncMaxFileCount)
    source "./awss3syncMaxFileCount/awss3syncMaxFileCount.sh"
    sync_function="awss3syncMaxFileCount"
    ;;
  rclonesyncMaxFileCount)
    source "./rclonesyncMaxFileCount/rclonesyncMaxFileCount.sh"
    sync_function="rclonesyncMaxFileCount"
    ;;
  s3cmdsyncMaxFileCount)
    source "./s3cmdsyncMaxFileCount/s3cmdsyncMaxFileCount.sh"
    sync_function="s3cmdsyncMaxFileCount"
    ;;
  s4cmdsyncMaxFileCount)
    source "./s4cmdsyncMaxFileCount/s4cmdsyncMaxFileCount.sh"
    sync_function="s4cmdsyncMaxFileCount"
    ;;
  mcmirrorMaxFileCount)
    source "./mcmirrorMaxFileCount/mcmirrorMaxFileCount.sh"
    sync_function="mcmirrorMaxFileCount"
    ;;
  *)
    echo "Unknown sync tool: $sync_tool"
    echo "Valid options are: awss3syncMaxFileCount, rclonesyncMaxFileCount, s3cmdsyncMaxFileCount, s4cmdsyncMaxFileCount, mcmirrorMaxFileCount"
    exit 1
    ;;
esac

generate_files() {
  local base_dir="$1"
  local scenario_name="$2"
  local total_size_bytes="$3"
  local num_files="$4"

  local dir="$BASE_DIR/datasets/$scenario_name"
  mkdir -p "$dir"

  local file_size_bytes=$((total_size_bytes / num_files))
  local file_size_mb=$(awk "BEGIN { printf \"%.4f\", $file_size_bytes / 1048576 }")

  echo "[$scenario_name] Generate $num_files files, each ≈ $file_size_mb MB..."

  for ((i = 1; i <= num_files; i++)); do
    dd if=/dev/urandom of="$dir/file_$i.bin" bs="$file_size_bytes" count=1 status=none
    echo "Generated file '$i' with size $file_size_bytes bytes"
  done
}

scenarios=(
  "Max_Number_of_Files 14000000000 3999566"
#  "Small_Static 109000 1"
)

#| Scenario ID         | Dataset Size | Number of Files |
#| ------------------- | ------------ | --------------- |
#| Min Dataset Size    | 160 B        | 1               |
#| Minimal Unit        | 3 kB         | 1               |
#| Small Static        | 109 kB       | 1               |
#| Small Multi-File    | 679 kB       | 441             |
#| Medium Static       | 6 MB         | 1               |
#| Medium Distributed  | 32 MB        | 5676            |
#| Medium High-Density | 50 MB        | 14253           |
#| Large Static        | 380 MB       | 1               |
#| Large Chunked       | 487 MB       | 454             |
#| 1GB Moderate Load   | 1 GB         | 23267           |
#| 1GB Extreme Load    | 1 GB         | 1055905         |
#| 19GB Heavy Load     | 19 GB        | 256381          |
#| 20GB Sparse Set     | 20 GB        | 1002            |
#| 22GB Minimal Set    | 22 GB        | 69              |
#| 25GB Maximal Load   | 25 GB        | 1839962         |
#| Max Number of Files | 14 GB        | 3999566         |
#| Max Dataset Size    | 146 GB       | 1281167         |

if [ ! -d "./FlameGraph" ]; then
  sudo git clone https://github.com/brendangregg/FlameGraph
fi

for scenario in "${scenarios[@]}"; do
  IFS=' ' read -r scenario_name size count <<< "$scenario"
  generate_files "$BASE_DIR" "$scenario_name" "$size" "$count"
  $sync_function "$BASE_DIR" "$scenario_name"
done
