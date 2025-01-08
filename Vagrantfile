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
  config.hostmanager.ignore_private_ip = false  # Use private network IPs
  
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
    redis.vm.hostname = "redis.vagrant.local"  # Use FQDN
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
    backend.vm.hostname = "backend.vagrant.local"  # Use FQDN
    backend.vm.network "private_network", type: "dhcp"
    backend.vm.network "forwarded_port", guest: 8080, host: 8080
    backend.vm.synced_folder "./backend/terramino-go", "/home/vagrant/terramino-go", create: true

    backend.vm.provision "shell", name: "start-backend", inline: <<-SHELL
      cd /home/vagrant/terramino-go

      # Configure backend to use Redis host
      echo "REDIS_HOST=redis.vagrant.local" > .env
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
    frontend.vm.hostname = "frontend.vagrant.local"  # Use FQDN
    frontend.vm.network "private_network", type: "dhcp"
    frontend.vm.network "forwarded_port", guest: 8081, host: 8081
    frontend.vm.synced_folder "./frontend/terramino-go", "/home/vagrant/terramino-go", create: true

    frontend.vm.provision "shell", name: "start-frontend", inline: <<-SHELL
      cd /home/vagrant/terramino-go
      
      # Update nginx.conf to use backend hostname
      sed -i 's/proxy_pass http:\/\/backend:8080/proxy_pass http:\/\/backend.vagrant.local:8080/' nginx.conf
      
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
