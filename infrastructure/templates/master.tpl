
#!/bin/bash

exec > >(tee /var/log/k8s-install.log) 2>&1

echo "************************ Update packages *******************"
apt-get update

echo "************************ Install curl, ca and https packages *******************"
apt-get install -y apt-transport-https ca-certificates curl net-tools

echo "************************ Update /etc/modules-load.d/k8s.conf to set up kerner modules *******************"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "************************ enable overlay and netfilter modules *******************"
modprobe overlay
modprobe br_netfilter

echo "************************ Update /etc/sysctl.d/k8s.conf to configure network *******************"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

echo "************************ configure apt-repo and signing key *******************"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list    

echo "************************ Install the container runtime *******************"
apt-get install -y containerd

echo "************************ Configure the container runtime to use systemd Cgroups *******************"
mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | tee /etc/containerd/config.toml
systemctl restart containerd

echo "************************ Download Signing key for k8s packages *******************"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

echo "************************ Install k8s tools *******************"
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "************************ Configure crictl *******************"
crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock

echo "************************ Display IP Address *******************"
PUBLIC_IP=`curl "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google"`
echo $PUBLIC_IP

PRIVATE_IP=`ifconfig ens4 | grep "inet " | awk -F' ' '{ print $2 }'`
echo $PRIVATE_IP

echo "************************ Initialize k8s Cluster *******************"
sudo kubeadm init \
   --apiserver-cert-extra-sans=$PUBLIC_IP \
   --apiserver-advertise-address $PRIVATE_IP \
   --pod-network-cidr=10.244.0.0/16

echo "************************ Setup default kubeconfig *******************"
mkdir ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config

echo "************************ Install k8s networking *******************"
export KUBECONFIG=/etc/kubernetes/admin.conf
#kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "************************ Print kubadm join command *******************"
JOIN_COMMAND=`kubeadm token create --print-join-command`
echo $JOIN_COMMAND > /tmp/k8sjoin.sh

echo "************************ update cluster ip to public ip *******************"
sed "s/$PRIVATE_IP/$PUBLIC_IP/g" /etc/kubernetes/admin.conf > /tmp/kubeconfig

echo "************************ Copy config to storagebucket *******************"
gcloud storage cp /tmp/k8sjoin.sh gs://k8sconfigstorage/
gcloud storage cp /tmp/kubeconfig gs://k8sconfigstorage/kubeconfig

echo "************************ Configure Cloud Provider in kube-controller *******************"

MANIFEST_DIR="/etc/kubernetes/manifests"
CLOUD_PROVIDER="gce"

# Backup the current manifests
cp -r $MANIFEST_DIR $MANIFEST_DIR_backup_$(date +%Y%m%d)

# Function to add cloud-provider to a manifest file
add_cloud_provider() {
    local file=$1
    if grep -q "cloud-provider" "$file"; then
        echo "cloud-provider is already set in $file"
    else
        sed -i "/- kube-/a \    - --cloud-provider=$CLOUD_PROVIDER" "$file"
    fi
}

# Add cloud-provider to API server and Controller manager
#add_cloud_provider "$MANIFEST_DIR/kube-apiserver.yaml"
add_cloud_provider "$MANIFEST_DIR/kube-controller-manager.yaml"

echo "************************ Install Helm *******************"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

echo "************************ Install Ingress Controller *******************"
helm install nginx-ic oci://registry-1.docker.io/bitnamicharts/nginx-ingress-controller