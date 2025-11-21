This folder holds Argo related resources for deploying OpenCost and supporting workloads.

## Network performance testing apps

Two new ApplicationSets (`iperf-server` and `iperf-client`) leverage the in-repo `argocd/charts/iperf3` Helm chart to deploy a long-running iperf3 server/client pair for cluster network benchmarking. Stage-specific overrides live under `argocd/apps/<stage>/iperf-server` and `argocd/apps/<stage>/iperf-client`, making it easy to tailor connection targets, service types, and resource requests without modifying the shared chart.