#!/bin/bash
sudo hostnamectl set-hostname master

# Logs file path
LOG_FILE="kubernetes_setup_log.txt"
LOG_FILE2="kubeadm_join.txt"


echo "Starting Kubernetes setup..." | tee -a $LOG_FILE
echo "Running as user: $(whoami)" | tee -a $LOG_FILE
echo "Home directory: $HOME" | tee -a $LOG_FILE



# Disable swap
echo "Disabling swap..." | tee -a $LOG_FILE
sudo swapoff -a
# this crontab to keep swap off after reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true




# Update and upgrade the system
echo "Updating and upgrading system..." | tee -a $LOG_FILE
sudo apt-get update && sudo apt-get upgrade -y



# Load the Kernel modules on all the nodes
#These modules are necessary for containerd, which Kubernetes relies on to run containers
# overlay This is a filesystem module required for Docker and containerd to implement container images and layers
# br_netfilter This is a module required to filter network traffic between containers in a bridge network

echo "Loading required kernel modules..." | tee -a $LOG_FILE
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
#These commands load the modules into the running system immediately, without needing a reboot
sudo modprobe overlay
sudo modprobe br_netfilter



# Set Kernel params for Kubernetes
#  net.ipv4.ip_forward = 1 This parameter enables IP forwarding, which is required for routing traffic between nodes in the cluster. If this is not set correctly, pods on one node may not be able to communicate with pods on another node
echo "Setting Kernel params for Kubernetes..." | tee -a $LOG_FILE
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF




# Reload the system changes
sudo sysctl --system

# ADD HERE: Set iptables legacy and stop firewall
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy


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
#kubelet interacts with containerd to manage containers
sudo apt-get install -y docker.io

# 8. Initialize Kubernetes
echo "[INFO] Initializing Kubernetes..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 

# 9. Configure kubectl for root user
echo "[INFO] Setting up kubectl config..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config





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

sudo kubeadm token create --print-join-command | tee -a $LOG_FILE2