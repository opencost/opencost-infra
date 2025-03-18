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