#!/bin/bash

# Log file path
LOG_FILE="kubernetes_setup_log.txt"
echo "Starting Kubernetes setup..." | tee -a $LOG_FILE

echo "Running as user: $(whoami)" | tee -a $LOG_FILE
echo "Home directory: $HOME" | tee -a $LOG_FILE

# Disable swap
echo "Disabling swap..." | tee -a $LOG_FILE
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

# Check if lsb_release is installed
if ! command -v lsb_release &> /dev/null; then
  echo "lsb_release command is not installed. Please install it to continue." | tee -a $LOG_FILE
  exit 1
fi

# Check for necessary commands
commands=(curl tee modprobe sysctl apt-key)
for cmd in "${commands[@]}"; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd is not installed. Please install it to continue." | tee -a $LOG_FILE
    exit 1
  fi
done

# Cool ASCII art for the script header
cat << "EOF" | tee -a $LOG_FILE
:-) Kubernetes Cluster Setup :-)

EOF

# Update and upgrade the system
echo "Updating and upgrading system..." | tee -a $LOG_FILE
sudo apt-get update && sudo apt-get upgrade -y

# Load the Kernel modules on all the nodes
echo "Loading required kernel modules..." | tee -a $LOG_FILE
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Set Kernel params for Kubernetes
echo "Setting Kernel params for Kubernetes..." | tee -a $LOG_FILE
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
echo "Adding Kubernetes repository..." | tee -a $LOG_FILE
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt index after adding the repository
echo "Updating apt index..." | tee -a $LOG_FILE
sudo apt-get update -y

# Install Kubernetes components (kubelet, kubeadm, kubectl)
echo "Installing the latest Kubernetes components..." | tee -a $LOG_FILE
sudo apt-get install -y kubelet kubeadm kubectl

# Mark Kubernetes packages to hold to prevent upgrading
echo "Marking Kubernetes packages on hold..." | tee -a $LOG_FILE
sudo apt-mark hold kubelet kubeadm kubectl

# Install containerd
echo "Installing containerd..." | tee -a $LOG_FILE
sudo apt-get install -y containerd
sudo systemctl enable containerd
sudo systemctl start containerd


# 8. Initialize Kubernetes
echo "[INFO] Initializing Kubernetes..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 

# 9. Configure kubectl for root user
echo "[INFO] Setting up kubectl config..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# 7. Set KUBELET flags
# echo "[INFO] Setting KUBELET_KUBEADM_ARGS..."
#echo 'KUBELET_KUBEADM_ARGS="--node-ip=172.31.0.36 --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9"' | \
#sudo tee /var/lib/kubelet/kubeadm-flags.env > /dev/null

#sudo systemctl daemon-reexec
#sudo systemctl restart kubelet





# Apply the Flannel network plugin
echo "Applying Flannel network..." | tee -a $LOG_FILE
if kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml; then
    echo "✅ Flannel applied successfully." | tee -a $LOG_FILE
else
    echo "❌ Failed to apply Flannel." | tee -a $LOG_FILE
    exit 1
fi

# End of script - logging success
echo "Kubernetes Cluster setup completed!" | tee -a $LOG_FILE

# Cool ASCII art for the end of the script
cat << "EOF" | tee -a $LOG_FILE
:-) Kubernetes Cluster Setup Complete :-)

EOF

sudo kubeadm token create --print-join-command
