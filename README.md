# Ansible

### Installing Ansible

This project requires ansible 2.9.24 or greater on the host running the ansible playbook. The target systems do no not need Ansible installed.

#### Pip Method

The steps below for installing Ansible have been tested on CentOS 7.9.2009, CentOS 8.4.2105, Debian 9.13, Debian 10.10, Ubuntu 18.04.5, Ubuntu 20.04.3, and Ubuntu 22.04.2. This should function on any Linux distribution with Python3.

1. Ensure pip3 is installed 
    
    Ubuntu/Debian: `sudo apt install python3-pip`
    
    CentOS: `sudo yum install python3-pip`

2. Add local bin directory to path in bashrc
    
```
echo 'PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

3. Use pip to install ansible

`python3 -m pip install --user -U pip && python3 -m pip install --user -U ansible`

4. Ensure that ansible version is greater than 2.9.24

`ansible --version`

#### Distribution Native

Ubuntu 22.04.2, Debian Bullseye, Alpine 3.17, RHEL 9 and derivatives (including Fedora 37), and Arch all have a late enough version of Ansible in their repositories.

Ubuntu/Debian: `sudo apt-get install -y ansible`
RHEL/Fedora: `sudo dnf -y install ansible-core`
Alpine: `sudo apk add ansible`
Arch: `sudo pacman -Sy --noconfirm ansible-core`

## Kasm Multi Server install
This playbook will deploy Kasm Workspaces in a multi-server deployment using Ansible. 

* It installs the kasm components on the systems specified in the ansible `inventory` required for the respective roles (db, web, agent, guac, proxy).
* It creates a new swapfile to ensure that the total swap space matches the size `desired_swap_size` specified in the inventory file for all agents.
* It enables the docker daemon to run at boot to ensure that kasm services are started after a reboot.

It has been tested on CentOS 7.9.2009, CentOS 8.4.2105, Debian 9.13, Debian 10.10, Ubuntu 18.04.5, Ubuntu 20.04.3, and Ubuntu 22.04.2 hosts.

![Diagram][Image_Diagram]

[Image_Diagram]: https://f.hubspotusercontent30.net/hubfs/5856039/Ansible/Ansible%20Multi%20Server.png "Diagram"


### Ansible Configuration and installation

1. Open `inventory` file and fill in the hostnames / ips for the servers that will be fulfilling the agent, web, db, and guac roles. Please take the time to get acquainted with the inventory file and it's layout. It serves as the master file controlling how this multi server installation will be deployed. Every variable in this file has been designed to scale except for the database. Regardless of deployment size there will only be one centralized database `zone1_db_1` or a remote type db that all "web" roles need direct access to.

2. Ensure the variables for each host in the deployment are set properly specifically:  
    * ansible_host: (hostname or IP address)
    * ansible_port: (ssh port)
    * ansible_ssh_user: (ssh user to login as, reccomended root or a user with passwordless sudo)
    * ansible_ssh_private_key_file: (full path to ssh private key file to user which can be include bash completion IE ~/.ssh/mykey)

3. Download the Kasm Workspaces installer from https://www.kasmweb.com/downloads.html and copy it to `roles/install_common/files`. 
    
    Optionally, if doing an offline installation: Download and copy the workspace_images and service_images files to `roles/install_common/files`.
   
4. Run the deployment.

    `ansible-playbook -i inventory install_kasm.yml`

5. Make notes of the credentials generated during the installation to be able to login.

6. Login to the deployment as admin@kasm.local using the IP of one of the web servers (eg https://192.168.1.2) 

7. Navigate to the Agents tab, and enable each Agent after it checks in. (May take a few minutes)

**Post installation your local inventory file will be modified with the appropriate credentials please make a copy or keep this somewhere safe**

**If any deployment errors occur please run the uninstall_kasm.yml playbook against the same inventory file before trying again as there might be half set credentials leading to a broken deployment, see the helper playbooks section for more information**

### Scaling the deployment

The installation can be "scaled up" after being installed by adding any additional hosts including entire new zones. Once modified run: 

`ansible-playbook -i inventory install_kasm.yml`

Before running the installation against a modified inventory file please ensure the credentials lines in your inventory were set and uncommented properly by the initial deployment IE:

```
    ## Credentials ##
    # If left commented secure passwords will be generated during the installation and substituted in upon completion
    user_password: PASSWORD
    admin_password: PASSWORD
    database_password: PASSWORD
    redis_password: PASSWORD
    manager_token: PASSWORD
    registration_token: PASSWORD
```

#### Scaling examples

A common example of adding more Docker Agents:

```
        zone1_agent:
          hosts:
            zone1_agent_1:
              ansible_host: zone1_agent_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
            zone1_agent_2:
              ansible_host: zone1_agent2_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

If you would like to scale up web/agent/guac/proxy servers as a group where the agent/guac/proxy server talk exclusively to that web server set `default_web: false` in your inventory file. This requires entries with a matching integer for all hosts IE:

```
        zone1_web:
          hosts:
            zone1_web_1:
              ansible_host: zone1_web_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
            zone1_web_2:
              ansible_host: zone1_web2_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
        zone1_agent:
          hosts:
            zone1_agent_1:
              ansible_host: zone1_agent_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
            zone1_agent_2:
              ansible_host: zone1_agent2_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
        zone1_guac:
          hosts:
            zone1_guac_1:
              ansible_host: zone1_guac_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
          hosts:
            zone1_guac_2:
              ansible_host: zone1_guac2_hostname
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

Included in inventory is a commeted section laying out a second zone. The names zone1 and zone2 were chosen arbitraily and can be modified to suite your needs, but all items need to follow that naming pattern IE:

```
    # Second zone
    # Optionally modify names to reference zone location IE west
    west:
      children:
        west_web:
          hosts:
            west_web_1:
              ansible_host: HOST_OR_IP
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
        west_agent:
          hosts:
            west_agent_1:
              ansible_host: HOST_OR_IP
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
        west_guac:
          hosts:
            west_guac_1:
              ansible_host: HOST_OR_IP
              ansible_port: 22
              ansible_ssh_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa

  vars:
    zones:
      - zone1
      - west
```

#### Missing credentials

If for any reason you have misplaced your inventory file post installation credentials for the installation can be recovered using:

- Existing Database password can be obtained by logging into a webapp host and running the following command:

```
sudo grep " password" /opt/kasm/current/conf/app/api.app.config.yaml
```

- Existing Redis password can be obtained by logging into a webapp host and running the following command:

```
sudo grep "redis_password" /opt/kasm/current/conf/app/api.app.config.yaml
```

- Existing Manager token can be obtained by logging into an agent host and running the following command:

```
sudo grep "token" /opt/kasm/current/conf/app/agent.app.config.yaml
```

### Deploying with a remote database

In order to deploy with a dedicated remote database that is not managed by ansible you will need to provide endpoint and authentication credentials. To properly init the database superuser credentials along with the credentials the application will use to access it will need to be defined. 

1. First remove the `zone1_db` entry from inventory:

```
        #zone1_db:
          #hosts:
            #zone1_db_1:
              #ansible_host: zone1_db_hostname
              #ansible_port: 22
              #ansible_ssh_user: ubuntu
              #ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

2. Set the relevant credentials and enpoints:

```
    ## PostgreSQL settings ##
    ##############################################
    # PostgreSQL remote DB connection parameters #
    ##############################################
    # The following parameters need to be set only once on database initialization
    init_remote_db: true
    database_master_user: postgres
    database_master_password: PASSWORD
    database_hostname: DATABASE_HOSTNAME
    # The remaining variables can be modified to suite your needs or left as is in a normal deployment
    database_user: kasmapp
    database_name: kasm
    database_port: 5432
    database_ssl: true
    ## redis settings ##
    # redis connection parameters if hostname is set the web role will use a remote redis server
    redis_hostname: REDIS_HOSTNAME
    redis_password: REDIS_PASSWORD
```

3. Run the deployment:
 
`ansible-playbook -i inventory install_kasm.yml`


**Post deployment if the `install_kasm.yml` needs to be run again to make scaling changes it is important to set `init_remote_db: false` this should happen automatically but best to check**

### Deploying a Dedicated Kasm Proxy

1. Before deployment or while scaling open `inventory` and uncomment/add the relevant lines for :

```
        # Optional Web Proxy server
        #zone1_proxy:
          #hosts:
            #zone1_proxy_1:
              #ansible_host: zone1_proxy_hostname
              #ansible_port: 22
              #ansible_ssh_user: ubuntu
              #ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

2. Post deployment follow the instructions [here](https://www.kasmweb.com/docs/latest/install/multi_server_install/multi_installation_proxy.html#post-install-configuration) to configure the proxy for use.

**It is important to use a DNS endpoint for the `web` and `proxy` role as during deployment the CORS settings will be linked to that domain**

## Helper playbooks

Using these playbooks assumes you have allready gone through the installation process and setup your inventory file properly. These playbooks run against that inventory to help administrators: 

* Uninstall Kasm Workspaces (uninstall_kasm.yml)- This will completely purge your Kasm Workspaces installation on all hosts, if using a remote database that data will stay intact no remote queries will be executed. Example Usage: `ansible-playbook -i inventory uninstall_kasm.yml`
* Stop Kasm Workspaces (stop_kasm.yml)- This will stop all hosts defined in inventory or optionally be limited to a zone, group or single server passing the `--limit` flag. Example Usage `ansible-playbook -i inventory --limit zone1_agent_1 stop_kasm.yml`
* Start Kasm Workspaces (start_kasm.yml)- This will start all hosts defined in inventory or optionally be limited to a zone, group or single server passing the `--limit` flag. Example Usage `ansible-playbook -i inventory --limit zone1_agent_1 start_kasm.yml`
* Restart Kasm Workspaces (restart_kasm.yml)- This will restart all hosts defined in inventory or optionally be limited to a zone, group or single server passing the `--limit` flag. Example Usage `ansible-playbook -i inventory --limit zone1_agent_1 restart_kasm.yml`
* Backup Database (backup_db.yml)- This will make a backup of a managed Docker based db server, this playbook will not function with a remote db type installation. Example Usage ``ansible-playbook -i inventory backup_db.yml`
    * Modify `remote_backup_dir` in inventory to change the path the remote server stores the backups
    * Modify `retention_days` in inventory to change the number of days that logs backups are retained on db host
    * Set `local_backup_dir` to define a path on the local ansible host where backups will be stored, if unset backups will only exist on the remote server
* OS Patching (patch_os.yml)- This will update system packages and reboot on all hosts defined in inventory or optionally be limited to a zone, group or single server passing the `--limit` flag. Example Usage `ansible-playbook -i inventory --limit zone1_agent_1 patch_os.yml`
