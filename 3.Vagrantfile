# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "hashicorp-education/ubuntu-24-04"
  config.vm.box_version = "0.1.0"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Disable the default share of the current code directory. Doing this
  # provides improved isolation between the vagrant box and your host
  # by making sure your Vagrantfile isn't accessible to the vagrant box.
  # If you use this you may want to enable additional shared subfolders as
  # shown above.
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL

  # Forward ports for Terramino
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 8081, host: 8081

  # Sync the terramino-go directory if it exists
  config.vm.synced_folder "./terramino-go", "/home/vagrant/terramino-go", create: true

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
    echo 'alias play="docker compose -f /home/vagrant/terramino-go/docker-compose.yml exec -it backend ./terramino-cli"' >> /home/vagrant/.bashrc
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
