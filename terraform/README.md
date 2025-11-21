This folder is designed to hold the terraform for managing the OpenCost cloud resources 

A few configurations are required in order to apply Terraform changes. 

First, set the path to the private key file. For example:
```export TF_VAR_path_to_private_key="/Users/christian/.oci/oci_api_key.pem"```

Next, create a .tfvars file with the required OCI configuration information. The required information can be exported from the Oracle Cloud Console and is as follows: 

| Variable       | Example                                         |
| -------------- | ----------------------------------------------- |
| tenancy_id     | `tenancy_id = ocid1.tenancy.oc1..exampleid`     |
| compartment_id | `compartment_id = ocid1.tenancy.oc1..exampleid` |
| user_id        | `user_id = ocid1.user.oc1..exampleid`           |
| fingerprint    | `fingerprint = exampleid`                       |

If you believe you need the required information above, but don't have access to the Oracle Cloud Console, please contact the maintainers for assistance. 

## Spot node pool defaults

The demo cluster now provisions a dedicated spot node pool (default size of two nodes). You can override its behavior through the following variables:

| Variable | Default | Description |
| --- | --- | --- |
| `spot_node_pool_name` | `np-spot` | Name assigned to the spot node pool |
| `spot_node_shape` | `VM.Standard3.Flex` | OCI shape used for the spot workers |
| `spot_node_ocpus` | `2` | OCPUs requested when using a Flex shape |
| `spot_node_memory_in_gbs` | `16` | Memory (GB) requested when using a Flex shape |
| `spot_node_pool_size` | `2` | Number of spot nodes maintained in the pool |
| `spot_node_boot_volume_size_gbs` | `150` | Boot volume size (GB) for each spot node |
| `spot_preemption_action_type` | `TERMINATE` | Action performed when OCI reclaims a spot instance |
| `spot_preserve_boot_volume` | `false` | Whether to keep the boot volume when a spot node is preempted |