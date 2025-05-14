#!/bin/bash

S3_BUCKET_SANDBOX="s3://diploma-awss3sync-large-benchmark"
S3_BUCKET_RESULTS="s3://diploma-results/"

awss3syncLarge() {
  aws configure set default.s3.max_concurrent_requests 16
  aws configure set default.s3.multipart_chunksize 64MB

  echo "[$scenario_name] Generating 1 GB test file..."
  mkdir -p "/tmp/prewarming"
  dd if=/dev/urandom of="/tmp/prewarming/file1gb.bin" bs=1GB count=1 status=progress
  echo "[$scenario_name] Pre-warming: syncing once before measurement..."
  aws s3 rm "$S3_BUCKET_SANDBOX" --recursive
  aws s3 sync "/tmp/prewarming/" "$S3_BUCKET_SANDBOX" --exact-timestamps --no-guess-mime-type
  aws s3 rm "$S3_BUCKET_SANDBOX" --recursive

  local base_dir="$1"
  local scenario_name="$2"
  local perf_folder="$base_dir/awss3sync/$scenario_name"
  mkdir -p "$perf_folder"

  local times=()

  for i in {1..5}; do
    echo "[$scenario_name] Clearing the S3 bucket..."
    aws s3 rm "$S3_BUCKET_SANDBOX" --recursive
    echo 3 > /proc/sys/vm/drop_caches

    echo "[$scenario_name][$i] Sync started..."

    local datasets_folder="$base_dir/datasets/$scenario_name"
    local perf_data_file="$perf_folder/awss3sync.$scenario_name.$i.perf.data"
    local start_time=$(date +%s.%N)
    perf record -F 99 -g --call-graph=dwarf -o "$perf_data_file" -- \
      aws s3 sync "$datasets_folder" "$S3_BUCKET_SANDBOX" --exact-timestamps --no-guess-mime-type
    local end_time=$(date +%s.%N)

    local duration=$(echo "$end_time - $start_time" | bc)
    duration=$(printf "%.2f" "$duration")
    times+=("$duration")

    echo "[$scenario_name][$i] Sync completed in $duration s" | tee -a "$perf_folder/times.log"

    local single_report="$perf_folder/awss3sync.$scenario_name.$i.report.md"
    echo "| Run ID | Duration (s) |"           > "$single_report"
    echo "|--------|--------------|"           >> "$single_report"
    printf "| %d      | %.2f         |\n" "$i" "$duration" >> "$single_report"

    aws s3 cp "$single_report" "$S3_BUCKET_RESULTS"
    aws s3 cp "$perf_data_file" "$S3_BUCKET_RESULTS"
  done

  echo "[$scenario_name] Clearing the S3 bucket after all runs..."
  aws s3 rm "$S3_BUCKET_SANDBOX" --recursive

  local report_file="$perf_folder/awss3sync.$scenario_name.report.md"
  echo "### Results for scenario: \`$scenario_name\`" > "$report_file"
  echo >> "$report_file"
  echo "| Run # | Duration (s) |" >> "$report_file"
  echo "|-------|---------------|" >> "$report_file"

  local total=0
  for i in "${!times[@]}"; do
    local run_num=$((i + 1))
    local t=${times[$i]}
    total=$(echo "$total + $t" | bc)
    printf "| %d     | %.2f         |\n" "$run_num" "$t" >> "$report_file"
  done

  local avg=$(echo "$total / 10" | bc -l)
  avg=$(printf "%.2f" "$avg")
  echo "|-------|---------------|" >> "$report_file"
  printf "| Avg   | %.2f         |\n" "$avg" >> "$report_file"
  echo >> "$report_file"

  cat "$report_file"

  echo "[$scenario_name] Generating FlameGraph..."
  for f in "$perf_folder"/awss3sync."$scenario_name".*."perf.data"; do
    perf script -i "$f" >> "$perf_folder/all.stacks"
  done

  ./FlameGraph/stackcollapse-perf.pl "$perf_folder/all.stacks" > "$perf_folder/all.folded"
  flamegraph_file="$perf_folder/awss3sync.$scenario_name.flamegraph.html"
  ./FlameGraph/flamegraph.pl --width 3000 --fontsize 14 "$perf_folder/all.folded" > "$flamegraph_file"

  echo "Uploading results to S3..."
  aws s3 cp "$flamegraph_file" "$S3_BUCKET_RESULTS"
  aws s3 cp "$report_file"     "$S3_BUCKET_RESULTS"
}
