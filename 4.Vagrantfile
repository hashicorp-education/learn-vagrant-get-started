# Service configuration reference
SERVICES = {
  'redis' => {
    ip: '192.168.56.10',
    ports: { 6379 => 6379 }
  },
  'backend' => {
    ip: '192.168.56.11',
    ports: { 8080 => 8080 }
  },
  'frontend' => {
    ip: '192.168.56.12',
    ports: { 8081 => 8081 }
  }
}

Vagrant.configure("2") do |config|
  # Common configuration
  config.vm.box = "hashicorp-education/ubuntu-24-04"
  config.vm.box_version = "0.1.0"

  # Common provisioning script for all VMs
  config.vm.provision "shell", name: "common", path: "common-dependencies.sh"

  # Redis Server
  config.vm.define "redis" do |redis|
    redis.vm.hostname = "redis"
    redis.vm.network "private_network", ip: SERVICES['redis'][:ip]
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
    backend.vm.network "private_network", ip: SERVICES['backend'][:ip]
    backend.vm.network "forwarded_port", guest: 8080, host: 8080
    backend.vm.synced_folder "./backend/terramino-go", "/home/vagrant/terramino-go", create: true

    backend.vm.provision "shell", name: "start-backend", inline: <<-SHELL
      cd /home/vagrant/terramino-go

      # Get Redis IP dynamically (with 1 minute timeout)
      for i in {1..30}; do
        if REDIS_IP=$(getent hosts redis.local | awk '{print $1}'); then
          break
        fi
        echo "Waiting for redis.local to be resolvable..."
        sleep 2
      done

      # Run the backend container with Redis host
      docker build -f Dockerfile.backend -t backend .

      docker run -d -p 8080:8080 \
        -e REDIS_HOST=redis.local \
        -e REDIS_PORT=6379 \
        -e TERRAMINO_PORT=8080 \
        --add-host redis.local:${REDIS_IP} \
        backend

      # Add CLI alias
      echo 'alias cli="docker compose exec backend ./terramino-cli"' >> /home/vagrant/.bashrc
    SHELL

    backend.vm.provision "shell", name: "reload-backend", run: "never", inline: <<-SHELL
      cd /home/vagrant/terramino-go

      # Get Redis IP dynamically
      REDIS_IP=$(getent hosts redis.local | awk '{print $1}')

      docker stop backend || true
      docker rm -f backend || true
      docker build -f Dockerfile.backend -t backend .
      docker run -d --network host -p 8080:8080 \
        -e REDIS_HOST=redis.local \
        -e REDIS_PORT=6379 \
        -e TERRAMINO_PORT=8080 \
        --add-host redis.local:${REDIS_IP} \
        --name backend \
        backend
    SHELL
  end

  # Frontend Server
  config.vm.define "frontend" do |frontend|
    frontend.vm.hostname = "frontend"
    frontend.vm.network "private_network", ip: SERVICES['frontend'][:ip]
    frontend.vm.network "forwarded_port", guest: 8081, host: 8081
    frontend.vm.synced_folder "./frontend/terramino-go", "/home/vagrant/terramino-go", create: true

    frontend.vm.provision "shell", name: "start-frontend", inline: <<-SHELL
      cd /home/vagrant/terramino-go

      # Wait for nginx.conf to be available to update backend hostname
      for i in {1..30}; do
        if [ -f nginx.conf ]; then
          break
        fi
        echo "Waiting for nginx.conf to be available..."
        sleep 2
      done
      
      # Update nginx.conf to use backend hostname
      sed -i 's#proxy_pass http://backend:8080#proxy_pass http://backend.local:8080#' nginx.conf || {
        echo "Failed to update nginx.conf"
        exit 1
      }

      # Get backend IP dynamically (with 1 minute timeout)
      for i in {1..30}; do
        if BACKEND_IP=$(getent hosts backend.local | awk '{print $1}'); then
          break
        fi
        echo "Waiting for backend.local to be resolvable..."
        sleep 2
      done

      docker build -f Dockerfile.frontend -t frontend .

      docker run -d -p 8081:8081 \
        --add-host backend.local:${BACKEND_IP} \
        frontend
    SHELL

    frontend.vm.provision "shell", name: "reload-frontend", run: "never", inline: <<-SHELL
      cd /home/vagrant/terramino-go

      # Get backend IP dynamically
      BACKEND_IP=$(getent hosts backend.local | awk '{print $1}')

      docker stop frontend || true
      docker rm -f frontend || true
      docker build -f Dockerfile.frontend -t frontend .
      docker run -d -p 8081:8081 \
        --add-host backend.local:${BACKEND_IP} \
        frontend
    SHELL
  end
end
