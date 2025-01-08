# Getting started with Vagrant

Get up and running with Vagrant by learning about spinning up your own developer environment.

This repo is a companion to the [Get Started](https://developer.hashicorp.com) collection of tutorials.

### Runbook

#### Set up Vagrant environment

Check Vagrant version.

```
❯ vagrant version
Installed Version: 2.4.3
Latest Version: 2.4.3
 
You're running an up-to-date version of Vagrant!
```

HCP Vagrant for [Ubuntu 24.04](https://portal.cloud.hashicorp.com/vagrant/discover/im2nguyen/ubuntu-24-04) for both ARM64 and AMD64. This box is configured for Virtualbox.

```
❯ vagrant init im2nguyen/ubuntu-24-04 --box-version 0.1.0
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
```

This generates a Vagrantfile with the following configuration.

```
Vagrant.configure("2") do |config|
  config.vm.box = "im2nguyen/ubuntu-24-04"
  config.vm.box_version = "0.1.0"
end
```

Spin up the environment with `vagrant up`. If Vagrant defaults to another provider, specify the VirtualBox provider `vagrant up --provider=virtualbox`. (Describe providers and their relationship with boxes)

```
❯ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'im2nguyen/ubuntu-24-04'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'im2nguyen/ubuntu-24-04' version '0.1.0' is up to date...
==> default: Setting the name of the VM: learn-vagrant-get-started_default_1736289744075_54555
==> default: Fixed port collision for 22 => 2222. Now on port 2201.
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 (guest) => 2201 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2201
    default: SSH username: vagrant
    default: SSH auth method: password
    default: 
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
[WARN] - (starship::utils): Executing command "/usr/local/bin/vagrant" timed out.
[WARN] - (starship::utils): You can set command_timeout in your config to a higher value to allow longer-running commands to keep executing.
```

From here, you can access the box (`vagrant ssh`), suspend the machine (`vagrant suspend`), stop the machine (`vagrant halt`), or destroy the machine (`vagrant destroy`).

```
❯ vagrant ssh
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-51-generic aarch64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Jan  8 01:20:07 AM UTC 2025

  System load:             0.0
  Usage of /:              64.6% of 9.75GB
  Memory usage:            20%
  Swap usage:              0%
  Processes:               113
  Users logged in:         0
  IPv4 address for enp0s3: 10.0.2.15
  IPv6 address for enp0s3: fd00::a00:27ff:fef0:f51d


Expanded Security Maintenance for Applications is not enabled.

7 updates can be applied immediately.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status
```

#### Provision development environment

Update your Vagrantfile to include the following provisioning step.

```
Vagrant.configure("2") do |config|
  config.vm.box = "im2nguyen/ubuntu-24-04"
  config.vm.box_version = "0.1.0"

  # Install Docker and dependencies
  config.vm.provision "shell", name: "install-dependencies", inline: <<-SHELL
    # Update package list
    apt-get update

    # Install required packages
    apt-get install -y ca-certificates curl gnupg git

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker packages
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add vagrant user to docker group
    usermod -aG docker vagrant

    # Clone Terramino repository if it doesn't exist
    if [ ! -d "/home/vagrant/terramino-go/.git" ]; then
      cd /home/vagrant
      rm -rf terramino-go
      git clone https://github.com/hashicorp-education/terramino-go.git
      cd terramino-go
      git checkout containerized
    fi

    # Create reload script
    cat > /usr/local/bin/reload-terramino << 'EOF'
#!/bin/bash
cd /home/vagrant/terramino-go
docker compose down
docker compose build --no-cache
docker compose up -d
EOF

    chmod +x /usr/local/bin/reload-terramino

    # Add aliases
    echo 'alias cli="docker compose -f /home/vagrant/terramino-go/docker-compose.yml exec -it backend ./terramino-cli"' >> /home/vagrant/.bashrc
    echo 'alias reload="sudo /usr/local/bin/reload-terramino"' >> /home/vagrant/.bashrc
    # Source the updated bashrc
    echo "source /home/vagrant/.bashrc" >> /home/vagrant/.bash_profile
  SHELL

  # Start Terramino (can be rerun with vagrant provision --provision-with start-terramino)
  config.vm.provision "shell", name: "start-terramino", inline: <<-SHELL
    cd /home/vagrant/terramino-go
    docker compose up -d
  SHELL

  # Restart Terramino (can be rerun with vagrant provision --provision-with restart-terramino)
  # For quick changes that doesn't require rebuilding (e.g. frontend changes)
  config.vm.provision "shell", name: "restart-terramino", run: "never", inline: <<-SHELL
    docker compose restart
  SHELL

  # Reload Terramino (can be rerun with vagrant provision --provision-with reload-terramino)
  # For changes that require rebuilding (e.g. backend changes)
  config.vm.provision "shell", name: "reload-terramino", run: "never", inline: <<-SHELL
    /usr/local/bin/reload-terramino
  SHELL
end
```

(Explain the four provisioning files here. Naming the provisioning step lets you target a specific provisioning step to apply.)

Run `vagrant provision` to provision the box.

```
❯ vagrant provision
```

(Talk about different ways to 
provision your box, and its behavior. We recommend you write your provisioning 
script to be idempotent -- that way you can rerun your provisioning
steps multiple times. Otherwise, it may produce an error since Vagrant just
runs the provisioning step again. Alternatively, you can run 
`vagrant up --provision`. If you want to start from a new box, destroy your 
current box (`vagrant destroy`) and recreate it (`vagrant up`)).

Once the provisioning scripts finish, SSH into your box.

```
❯ vagrant ssh
```

In the guest machine, test the Terramino demo app backend.

```
❯ curl localhost:8080/info
Terramino - HashiCorp Demo App
https://developer.hashicorp.com/
```

Enter `play` in the shell to use the Terramino CLI client to play the game.

```
❯ play
```

Terramino will show you the instructions. Press `Enter` to start the game.

```
Terramino CLI
Controls:
← →   : Move left/right
↑     : Rotate
↓     : Soft drop
Space : Hard drop
q     : Quit

Press Enter to start...
```

Mention provisioning tools here like Chef, Ansible, etc.

#### Share resources between host and guest machines

You can share networks and files between your host and guest machines.

First, modify your Vagrantfile to forward the Terramino frontend code.

```
# Forward ports for Terramino (8081 for frontend, 8080 for backend)
config.vm.network "forwarded_port", guest: 8080, host: 8080
config.vm.network "forwarded_port", guest: 8081, host: 8081
```

Reload your machine to apply the changes. This will restart your machine with
the latest Vagrantfile configuration. This is similar to running a
`vagrant halt` followed by a `vagrant up`.

```
❯ vagrant reload --provision
```

You can synchronize the files between the guest and host machine. This lets you make changes on your local computer and apply those changes to your guest machine.

A synced folder creates a bi-directional link between a directory on your host  machine and a directory in the VM. Changes in either location are reflected in the other location in real-time. The sync is active only while the VM is running

Destroying the box with `vagrant destroy` only destroys the VM. Your local directory remains untouched, because the local directory is the "source of truth".

If you run vagrant up after a destroy, Vagrant will create the VM. Vagrant will immediately mount the synced folder, copying over all your local files to the VM. In this case, Vagrant will sync your local `./terramino-go` directory to `/home/vagrant/terramino-go` in the VM.

If you delete your local directory, Vagrant will delete the synced folder in the guest machine. However, if you created files directly in the VM's directory (outside the sync), those would remain. In this case, if you delete your local directory and restart the VM, the provisioning script will detect the missing Git directory and clone a fresh copy.

Update the `Vagrantfile` to enable folder synching from the host machine's `./terramino-go` directory with the guest machine's `/home/vagrant/terramino-go` directory.

```
# Sync the terramino-go directory
config.vm.synced_folder "./terramino-go", "/home/vagrant/terramino-go"
```

Reload the box to sync the two directories.

```
❯ vagrant reload --provision
```

Add a health check handler at `/health` for the backend.

```
http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("OK"))
})
```

The guest machine is using `docker compose up` to run the services. Since you have made changes to the backend, you need to rebuild the backend and restart the services. The `reload-terramino` provisioning step does this. 

Rebuild the backend and restart the services to apply your changes.

```
vagrant provision --provision-with reload-terramino
```

Confirm that the Terramino backend has a health check.

```
❯ curl localhost:8080/health
OK
```

#### Manage multi-machine environments

In a real-world scenario, you often want to run different services on different machines. This helps with:
- Isolation: Each service runs independently
- Scalability: Services can be scaled individually
- Resource management: Better control over resource allocation
- Security: Network segmentation between services

Terramino is split into three services, each running on its own VM:

1. **Redis Server (redis)** stores high scores and runs on port 6379. Other services connect to it using hostname `redis`

1. **Backend Server (backend)** handles game logic and API. It runs on port 8080.
   - Connects to Redis for data storage
   - Provides CLI interface for terminal-based gameplay

1. **Frontend Server (frontend)** serves the web interface and runs on port 8081.
   - Proxies API requests to `backend`
   - Handles static file serving

Destroy your existing machine. Confirm the destroy with a `y`. We
recommend running destroying your existing machine if you introduce significant 
changes to the Vagrantfile, since they may conflict if they use the same 
resources (for example, ports, names, etc)

```
❯ vagrant destroy
```

Update the Vagrantfile with the following configuration. 

Each VM has its own Docker installation, maintains its own copy of the repository, runs only its designated service, and can be updated independently.

This setup mirrors a production environment where services are deployed to separate machines, each service can be scaled and managed independently, network segmentation provides better security, and resource contention is minimized.

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

# This Vagrantfile requires the vagrant-hostmanager plugin.
# Install it with: vagrant plugin install vagrant-hostmanager
unless Vagrant.has_plugin?("vagrant-hostmanager")
  raise "Please install vagrant-hostmanager plugin: vagrant plugin install vagrant-hostmanager"
end

Vagrant.configure("2") do |config|
  # Common configuration
  config.vm.box = "im2nguyen/ubuntu-24-04"
  config.vm.box_version = "0.1.0"

  # Configure hostmanager
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true

  # Common provisioning script for all VMs
  config.vm.provision "shell", name: "common", inline: <<-SHELL
    # Install Docker
    apt-get update
    apt-get install -y ca-certificates curl gnupg git
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker vagrant

    # Clone repo
    if [ ! -d "/home/vagrant/terramino-go/.git" ]; then
      git clone https://github.com/hashicorp-education/terramino-go.git /home/vagrant/terramino-go
      cd /home/vagrant/terramino-go
      git checkout containerized
    fi
  SHELL

  # Redis Server
  config.vm.define "redis" do |redis|
    redis.vm.hostname = "redis"
    redis.vm.network "private_network", type: "dhcp"
    redis.vm.network "forwarded_port", guest: 6379, host: 6379
    redis.vm.synced_folder "./redis/terramino-go", "/home/vagrant/terramino-go", create: true

    redis.vm.provision "shell", name: "start-redis", inline: <<-SHELL
      cd /home/vagrant/terramino-go
      docker compose up -d redis
    SHELL

    redis.vm.provision "shell", name: "reload-redis", run: "never", inline: <<-SHELL
      cd /home/vagrant/terramino-go
      docker compose stop redis
      docker compose rm -f redis
      docker compose up -d redis
    SHELL
  end

  # Backend Server
  config.vm.define "backend" do |backend|
    backend.vm.hostname = "backend"
    backend.vm.network "private_network", type: "dhcp"
    backend.vm.network "forwarded_port", guest: 8080, host: 8080
    backend.vm.synced_folder "./backend/terramino-go", "/home/vagrant/terramino-go", create: true

    backend.vm.provision "shell", name: "start-backend", inline: <<-SHELL
      cd /home/vagrant/terramino-go

      # Configure backend to use Redis host
      echo "REDIS_HOST=redis" > .env
      echo "REDIS_PORT=6379" >> .env
      
      docker compose up -d backend

      # Add CLI alias
      echo 'alias cli="docker compose exec backend ./terramino-cli"' >> /home/vagrant/.bashrc
    SHELL

    backend.vm.provision "shell", name: "reload-backend", run: "never", inline: <<-SHELL
      cd /home/vagrant/terramino-go
      docker compose stop backend
      docker compose rm -f backend
      docker compose build backend
      docker compose up -d backend
    SHELL
  end

  # Frontend Server
  config.vm.define "frontend" do |frontend|
    frontend.vm.hostname = "frontend"
    frontend.vm.network "private_network", type: "dhcp"
    frontend.vm.network "forwarded_port", guest: 8081, host: 8081
    frontend.vm.synced_folder "./frontend/terramino-go", "/home/vagrant/terramino-go", create: true

    frontend.vm.provision "shell", name: "start-frontend", inline: <<-SHELL
      cd /home/vagrant/terramino-go
      docker compose up -d frontend
    SHELL

    frontend.vm.provision "shell", name: "reload-frontend", run: "never", inline: <<-SHELL
      cd /home/vagrant/terramino-go
      docker compose stop frontend
      docker compose rm -f frontend
      docker compose build frontend
      docker compose up -d frontend
    SHELL
  end
end
```

Each VM is connected through a private network:

```
config.vm.network "private_network", type: "dhcp"
```

This allows service discovery using hostnames, isolated communication between services, and port forwarding for external access:
  - Redis: 6379 → 6379
  - Backend: 8080 → 8080
  - Frontend: 8081 → 8081


You can extend Vagrant's functionality using plugins. For this project, use the `vagrant-hostmanager` plugin to manage hostname resolution between VMs.

Install the required plugin.

```
❯ vagrant plugin install vagrant-hostmanager
Installing the 'vagrant-hostmanager' plugin. This can take a few minutes...
Fetching vagrant-hostmanager-1.8.10.gem
Installed the plugin 'vagrant-hostmanager (1.8.10)'!
```

The `vagrant-hostmanager` plugin:
- Automatically manages `/etc/hosts` files on both host and guest machines
- Enables hostname resolution between VMs
- Updates when VMs are created, started, or have IP changes
- Requires sudo password on the host machine (for updating host's `/etc/hosts`)

Start the environment. You may need to enter your host password to update the hosts file on your workstation.

```
❯ vagrant up
```

Alternatively, you can machines individually.

```
❯ vagrant up redis
❯ vagrant up backend
❯ vagrant up frontend
```

Access different machines:

```
❯ vagrant ssh redis
❯ vagrant ssh backend
❯ vagrant ssh frontend
```

Reload services after making changes:

```
❯ vagrant provision redis --provision-with reload-redis
❯ vagrant provision backend --provision-with reload-backend
❯ vagrant provision frontend --provision-with reload-frontend
```

List the boxes that are currently active.

```
❯ vagrant status
Current machine states:

redis                     running (virtualbox)
backend                   running (virtualbox)
frontend                  not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

