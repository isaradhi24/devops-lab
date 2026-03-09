Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # Shared folder between host and all VMs
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox", mount_options: ["dmode=775,fmode=664"]

  NODES = {
    "k8s-master"  => { ip: "192.168.56.10", ram: 6144, cpus: 3, disk: 30, role: "k8s-master" },
    "k8s-worker1" => { ip: "192.168.56.11", ram: 2048, cpus: 2, disk: 20, role: "k8s-worker" },
    "k8s-worker2" => { ip: "192.168.56.12", ram: 2048, cpus: 2, disk: 20, role: "k8s-worker" },
    "jenkins-ci"  => { ip: "192.168.56.20", ram: 4096, cpus: 4, disk: 40, role: "jenkins" },
    "sonarqube"   => { ip: "192.168.56.30", ram: 4096, cpus: 2, disk: 40, role: "sonar" }
  }

  NODES.each do |name, cfg|
    config.vm.define name do |node|
      node.vm.hostname = name
#      node.vm.network "private_network", ip: cfg[:ip]
      node.vm.network "forwarded_port", guest: 80, host: 8080  # optional
      node.vm.network "private_network", ip: cfg[:ip]
    # Add NAT interface
      node.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end

      node.vm.provider "virtualbox" do |vb|
        vb.memory = cfg[:ram]
        vb.cpus   = cfg[:cpus]
        vb.customize ["modifyvm", :id, "--audio", "none"]
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
      end

      node.vm.boot_timeout = 600

      # --------------------------
      # Base system provisioning
      # --------------------------
      node.vm.provision "shell", path: "scripts/base.sh"

      # --------------------------
      # Kubeconfig setup (idempotent)
      # --------------------------
      node.vm.provision "shell", inline: <<-SHELL, run: "always"
        if [ -f /etc/kubernetes/admin.conf ]; then
          mkdir -p /home/vagrant/.kube
          cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
          chown vagrant:vagrant /home/vagrant/.kube/config
        else
          echo "kubeconfig not yet available, skipping..."
        fi
      SHELL

      # --------------------------
      # Role-based provisioning
      # --------------------------
      case cfg[:role]
      when "k8s-master"
        # Reset master if previously exists and initialize
        node.vm.provision "shell", path: "scripts/k8s-master-reset.sh", run: "always"
        # Deploy CNI + optional ArgoCD
        node.vm.provision "shell", path: "scripts/k8s-cni-argocd.sh", run: "always"
      when "k8s-worker"
        # Wait for master join script to exist before joining
        node.vm.provision "shell", inline: <<-SHELL
          echo "Waiting for Kubernetes master join script..."
          while [ ! -f /vagrant/scripts/kubeadm_join.sh ]; do
            sleep 5
          done
          chmod +x /vagrant/scripts/kubeadm_join.sh
          sudo /vagrant/scripts/kubeadm_join.sh || true
        SHELL
      when "jenkins"
        node.vm.provision "shell", path: "scripts/jenkins.sh"
      when "sonar"
        node.vm.provision "shell", path: "scripts/sonar.sh"
      end
    end
  end
end