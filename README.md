=========

## update the correct values for the var.yml file 

```bash
vault_rhsm_user: <rhn_user>
vault_rhsm_password: <rhn_password>
vault_rhsm_pool_id: <poolid>
```
## Update the Inventory file with the correct hosts
```bash
./inventory
```

## Review and Run the Setup for the cluster to Bootstrap nodes
```bash
./setup.sh
```


