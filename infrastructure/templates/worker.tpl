
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

echo "************************ download kubeadm join script *******************"
filefound="false"
while [ $filefound == "false" ]
do
  gcloud storage cp gs://k8sconfigstorage/k8sjoin.sh /tmp/k8sjoin.sh
  if [ -f /tmp/k8sjoin.sh ]; then
          echo "k8s join script available"
        filefound="true"
  else
          echo "k8s join script not found. will retry in 10 sec.."
        sleep 10
  fi
done
chmod 755 /tmp/k8sjoin.sh

echo "************************ execute kubadm join *******************"
/tmp/k8sjoin.sh