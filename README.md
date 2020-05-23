# Purpose

One of the common techniques, that are used to decrease atack surface for compute instances exposed to the internet, is IP whitelistening.

I use it on daily basis for linux boxes that I access via SSH. It's easy to configure but can become a tedious task if a public IP, used to access our instances, changes frequently. 

To automate the task I prepared a simple bash script. It creates a security list with one ingress rule dedicated for SSH traffic.
Traffic is allowed only from current public IP of the client used to run the script. 
Later on, when public IP changes, we can run the script again and the security list configuration is updated with a new public IP.

**Note:**
It's tested and used on Mac OS.

# How to use it

1. Install and configure [OCI CLI](https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)
2. Clone the repo: `git clone git@github.com:msedzins/oci-security-list-update.git`
3. Modify `config.sh`
    1. COMPARTMENT_ID - compartment for a new security list [MANDATORY]
    2. VCN_ID - VCN that a new security list will belong to [MANDATORY]
    3. DISPLAY_NAME - security list name [OPTIONAL]
 4. Run './security_list_config.sh create' to create a new security list
 5. Go to VCN pointed by VCN_ID 
    1. Assign a newly created security list to subnet(s) of your choosing. 
    2. Make sure there are no other security rules from other security lists that allows SSH traffic to those subnets (if there are - remove them)
 6. From now on, SSH traffic to selected subnetsis IP whitelisted based on your current public IP.
 7. To update firewall rules with a new public IP run: `./security_list_config.sh update`
    1. The script verifies if the IP changed and only then updates the firewall rules.
    
To automate things even more, create following alias used to SSH to your instance:
```
alias ssh_sandbox='bash -c "cd ~/Documents/git/oci-security-list-update/; ./scl_configure.sh update; ssh -i <PRIVATE_KEY> opc@<IP_ADDRESS>"'
```
    
    
