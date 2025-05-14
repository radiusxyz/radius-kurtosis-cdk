echo "Stopping cdk-erigon"
# kurtosis service exec cdk cdk-erigon-sequencer-001 "pkill -SIGTRAP $(pgrep "proc-runner.sh")" || true
kurtosis service exec cdk cdk-erigon-sequencer-001 "pkill -SIGTRAP \"proc-runner.sh\"" || true
sleep 1
kurtosis service exec cdk cdk-erigon-sequencer-001 "pkill -SIGINT \"cdk-erigon\"" || true
sleep 30

echo "Copying and modifying config"
# shellcheck disable=SC2016 # double quotes result in syntax error, single quotes needed.
kurtosis service exec cdk cdk-erigon-sequencer-001 'cp \-r /etc/cdk-erigon/ /tmp/ && sed -i '\''s/zkevm\.executor-strict: true/zkevm.executor-strict: false/;s/zkevm\.executor-urls: zkevm-stateless-executor-001:50071/zkevm.executor-urls: ","/;$a zkevm.disable-virtual-counters: true'\'' /tmp/cdk-erigon/config.yaml'

echo "Starting cdk-erigon with modified config"
kurtosis service exec cdk cdk-erigon-sequencer-001 "nohup cdk-erigon --pprof=true --pprof.addr 0.0.0.0 --config /tmp/cdk-erigon/config.yaml --datadir /home/erigon/data/dynamic-kurtosis-sequencer > /proc/1/fd/1 2>&1 &"