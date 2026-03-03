Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

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
      node.vm.network "private_network", ip: cfg[:ip]

      node.vm.provider "virtualbox" do |vb|
        vb.memory = cfg[:ram]
        vb.cpus   = cfg[:cpus]

        # Disable audio
        vb.customize ["modifyvm", :id, "--audio", "none"]

        # Use virtio network adapter for speed
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]

        # Enable promiscuous mode (helps CNI)
        vb.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]

        # Resize disk (only works before first boot)
        # vb.customize ["modifyvm", :id, "--disk", "size=#{cfg[:disk] * 1024}"]
      end

      node.vm.provision "shell", path: "scripts/base.sh"

      case cfg[:role]
      when "k8s-master"
        node.vm.provision "shell", path: "scripts/k8s-master.sh"
        node.vm.provision "shell", path: "scripts/k8s-cni-argocd.sh", run: "always"
      when "k8s-worker"
        node.vm.provision "shell", path: "scripts/k8s-worker.sh"
      when "jenkins"
        node.vm.provision "shell", path: "scripts/jenkins.sh"
      when "sonar"
        node.vm.provision "shell", path: "scripts/sonar.sh"
      end
    end
  end
end
