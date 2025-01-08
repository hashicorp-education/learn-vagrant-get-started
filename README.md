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

Spin up the environment with `vagrant up`. If Vagrant defaults to another provider,
specify the VirtualBox provider `vagrant up --provider=virtualbox`.

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

From here, you can access the box (`vagrant ssh`), suspend the machine (`vagrant suspend`),
stop the machine (`vagrant halt`), or destroy the machine (`vagrant destroy`).

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

  # Install Docker, git, and set up Terramino
  config.vm.provision "shell", inline: <<-SHELL
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

    # Clone Terramino repository
    cd /home/vagrant
    git clone https://github.com/hashicorp-education/terramino-go.git
    cd terramino-go
    git checkout containerized

    # Start Terramino in the background
    docker compose up -d

    # Create CLI alias
    echo 'alias play="docker compose -f /home/vagrant/terramino-go/docker-compose.yml exec -it backend ./terramino-cli"' >> /home/vagrant/.bashrc
    # Source the updated bashrc
    echo "source /home/vagrant/.bashrc" >> /home/vagrant/.bash_profile
  SHELL
end
```

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
# Forward port 8080 for Terramino
config.vm.network "forwarded_port", guest: 8081, host: 8081
```

Reload your machine to apply the changes. This will restart your machine with
the latest Vagrantfile configuration. This is similar to running a
`vagrant halt` followed by a `vagrant up`.

```
❯ vagrant reload
```