variable "ec2_master_user_data" {
  description = "EC2 user data for master node"
  type        = string
  default     = <<EEE
#!/bin/bash
sudo swapoff -a
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo hostnamectl set-hostname master
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg containerd
sudo mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
sudo mkdir /etc/containerd/
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sudo sysctl --system
sudo modprobe br_netfilter
sudo systemctl restart containerd
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
sudo kubeadm init --apiserver-advertise-address=$INSTANCE_IP --ignore-preflight-errors=Mem
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.31/net.yaml
export JOIN_CLUSTER=$(kubeadm token create --print-join-command)
echo "{\"join_command\": \"$JOIN_CLUSTER\"}" > /tmp/join_cluster.json
chmod 744 /tmp/join_cluster.json
EEE
}

variable "ec2_worker_user_data" {
  description = "EC2 user data for worker node"
  type        = string
  default     = <<EEE
#!/bin/bash
sudo swapoff -a
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo hostnamectl set-hostname worker
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg containerd
sudo mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
sudo mkdir /etc/containerd/
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sudo sysctl --system
sudo modprobe br_netfilter
sudo systemctl restart containerd
EEE
}

variable "sg_rules" {
    type = list(object({
      cidr_blocks = list(string)
      description = string
      from_port = number
      ipv6_cidr_blocks = list(string)
      prefix_list_ids = list(string)
      protocol = string
      security_groups = list(string)
      self = string
      to_port = number
    }))
    description = "kubernetes sec group rules"
    default = [
    {
        cidr_blocks      = [
            "0.0.0.0/0",
        ]
        description      = null
        from_port        = 22
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = false
        to_port          = 22
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 10248
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 10248
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 10250
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 10250
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 10257
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 10257
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 10259
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 10259
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 2379
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 2380
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 30000
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 32767
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 443
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 443
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 4443
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 4443
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 6443
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 6443
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 6783
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 6783
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 6784
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 6784
    },
    {
        cidr_blocks      = []
        description      = null
        from_port        = 80
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = true
        to_port          = 80
    },
    ]
}   
