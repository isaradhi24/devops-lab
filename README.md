# devops-lab
# devops-lab

This is a full Vagrant-based automation lab for entire DevOps + Kubernetes environment

# 1. Repo Structure
devops-lab/
├─ Vagrantfile
└─ scripts/
   ├─ base.sh
   ├─ k8s-master.sh
   ├─ k8s-worker.sh
   ├─ k8s-cni-argocd.sh
   ├─ jenkins.sh
   ├─ sonar.sh
   └─ gitops/
      ├─ argocd_app_demo.yaml
      └─ Jenkinsfile.sample

# 2. Vagrantfile - Creates 5 VMs.
    NODES = { "k8s-master" => { ip: "192.168.56.10", ram: 3072, role: "k8s-master" }, 
              "k8s-worker1" => { ip: "192.168.56.11", ram: 2048, role: "k8s-worker" }, 
              "k8s-worker2" => { ip: "192.168.56.12", ram: 2048, role: "k8s-worker" }, 
              "jenkins-ci" => { ip: "192.168.56.20", ram: 4096, role: "jenkins" }, 
              "sonarqube" => { ip: "192.168.56.30", ram: 4096, role: "sonar" }
# 3. Common base provisioning
# 4. Kubernetes: containerd + kubeadm + master/worker
# 5. CNI + ArgoCD on master
# 6. Jenkins VM
# 7. SonarQube VM
# 8. GitOps + ArgroCD app + Jenkinsfile

# 9. How to use it end‑to‑end

Install VirtualBox, Vagrant, Git on your host.

Clone your repo:

bash
git clone https://github.com/isaradhi24/devops-lab.git
cd devops-lab
Bring up the lab:

bash
vagrant up
After it finishes:

Jenkins: http://192.168.56.20:8080

SonarQube: http://192.168.56.30:9000

ArgoCD: https://192.168.56.10:<nodeport> (get via kubectl -n argocd get svc argocd-server on master)

In Jenkins:

Add credentials: GitHub, Docker Hub, Sonar token, kubeconfig.

Create a pipeline job using Jenkinsfile.sample.

Push code to your app repo → run pipeline → ArgoCD deploys to K8s.


  