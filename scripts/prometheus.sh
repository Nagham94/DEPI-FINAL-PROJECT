#!/bin/bash
sudo hostnamectl set-hostname prometheus-node

# Log file path
LOG_FILE="kubernetes_setup_log.txt"

# Disable swap
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

# Check if lsb_release is installed
if ! command -v lsb_release &> /dev/null; then
  echo "lsb_release command is not installed. Please install it to continue."
  exit 1
fi

# Check for necessary commands
commands=(curl tee modprobe sysctl apt-key)
for cmd in "${commands[@]}"; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd is not installed. Please install it to continue."
    exit 1
  fi
done

# Cool ASCII art for the script header - Happy Smiley Face
cat << "EOF"
:-) Kubernetes Cluster Setup :-)

EOF

# Update and upgrade the system
echo "Updating and upgrading system..."
sudo apt-get update && sudo apt-get upgrade -y

# Load the Kernel modules on all the nodes
echo "Loading required kernel modules..."
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set Kernel params for Kubernetes
echo "Setting Kernel params for Kubernetes..."
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload the system changes
sudo sysctl --system
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings


# Add Kubernetes repository
echo "Adding Kubernetes repository..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# Kubernetes repository URL
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
# Update apt index after adding the repository
echo "Updating apt index..."
sudo apt-get update -y

# Install Kubernetes components (kubelet, kubeadm, kubectl)
echo "Installing the latest Kubernetes components (kubelet, kubeadm, kubectl)..."
sudo apt-get install -y kubelet kubeadm kubectl

# Mark Kubernetes packages to hold to prevent upgrading
echo "Marking Kubernetes packages on hold..."
sudo apt-mark hold kubelet kubeadm kubectl

# Install containerd (Kubernetes runtime)
sudo apt-get install -y containerd
sudo systemctl enable containerd
sudo systemctl start containerd

# Install Docker (if needed, not via snap)
sudo apt-get install -y docker.io

# Cool ASCII art for the end of the script - Happy Smiley Face
cat << "EOF"
:-) Kubernetes Cluster Setup :-)

EOF
