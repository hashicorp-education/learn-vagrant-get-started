Vagrant.configure("2") do |config|
  # Common configuration
  config.vm.box = "im2nguyen/ubuntu-24-04"
  config.vm.box_version = "0.1.0"

  # Redis Server
  config.vm.define "redis" do |redis|
    redis.vm.hostname = "redis"
    redis.vm.network "private_network", type: "dhcp"
    redis.vm.network "forwarded_port", guest: 6379, host: 6379

    redis.vm.provision "shell", inline: <<-SHELL
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

      # Clone repo and start Redis
      git clone https://github.com/hashicorp-education/terramino-go.git /home/vagrant/terramino-go
      cd /home/vagrant/terramino-go
      git checkout containerized
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

    backend.vm.provision "shell", inline: <<-SHELL
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

      # Clone repo and start Backend
      git clone https://github.com/hashicorp-education/terramino-go.git /home/vagrant/terramino-go
      cd /home/vagrant/terramino-go
      git checkout containerized

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

    frontend.vm.provision "shell", inline: <<-SHELL
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

      # Clone repo and start Frontend
      git clone https://github.com/hashicorp-education/terramino-go.git /home/vagrant/terramino-go
      cd /home/vagrant/terramino-go
      git checkout containerized
      
      # Configure frontend to use Backend host
      sed -i 's/backend:8080/backend:8080/' nginx.conf
      
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
