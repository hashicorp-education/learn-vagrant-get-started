# Install Docker and clone repo (common dependencies for multi-machine tutorial)

# Install Docker
apt-get update
apt-get install -y ca-certificates curl gnupg git avahi-daemon libnss-mdns
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