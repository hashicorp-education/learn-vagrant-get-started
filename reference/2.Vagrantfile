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
