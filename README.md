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
# 5. Validate kubernets cluster
   chmod +x scripts/k8s-validate.sh
   ./scripts/k8s-validate.sh
   You’ll get a clean PASS/FAIL summary for every subsystem.

   The API server health endpoint is the first and most important signal that your control plane is stable.  run `kubectl get --raw='/readyz`
   Once/healthz returns ok, you can proceed with the rest of the validation steps:

      Node Ready
      Control-plane pods Running
      etcd healthy
      Flannel Running
      kube-proxy Running
      DNS resolution
      Pod scheduling
      Service creation
      Kubelet identity
      Load test
   Your cluster is considered “fully ready” only when all of these pass.

   if /helthz failes
      run `sudo kubectl get pods -n kube-system -o wide` and check for 
         kube-apiser-* is Running
         etcd-* is Running
         No CrashLoopBackOff in status column

# 6. CNI + ArgoCD on master
# 7. Jenkins VM
# 8. SonarQube VM
# 9. GitOps + ArgroCD app + Jenkinsfile

# If cluster broken fix is----


1. Reset the broken control plane
   `sudo kubeadm reset -f`
   `sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /etc/kubernetes /var/lib/etcd`
   `sudo systemctl restart containerd kubelet`

2. Reinitialize Kubernetes

   `sudo kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --apiserver-advertise-address=192.168.56.10 \
      --apiserver-cert-extra-sans=127.0.0.1,192.168.56.10`
   
   Note: ips may be varie, chack ips in your configs.

3. Reinstall Kubeconfig

   `mkdir -p ~/.kube`
   `sudo cp /etc/kubernetes/admin.conf ~/.kube/config`
   `sudo chown vagrant:vagrant ~/.kube/config`

4. Restore CNI binaries
   `sudo cp /usr/lib/cni/* /opt/cni/bin/`

5. Apply Flannel
   `kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.25.5/Documentation/kube-flannel.yml`

6. Confirm the cluster is ready
   `kubectl get nodes`
   `kubectl get pods -n kube-system`
   `kubectl get --raw='/healthz'`

   Expected:
      Node = Ready
      All control-plane pods = Running
      /healthz = ok
      Only then is the cluster ready for the full validation script.


vagrant@k8s-master:~$ ip addr show | grep "inet " | grep -v 127.0.0.1~
    inet 127.0.0.1/8 scope host lo
    inet 10.0.2.15/24 metric 100 brd 10.0.2.255 scope global dynamic enp0s3
    inet 192.168.56.10/24 brd 192.168.56.255 scope global enp0s8
    inet 10.244.0.0/32 scope global flannel.1

vagrant@k8s-master:~$ kubeadm token list
kubectl -n kube-system get configmap kubeadm-config -o yaml | grep "cluster-info"
failed to list bootstrap tokens: Get "https://10.0.2.15:6443/api/v1/namespaces/kube-system/secrets?fieldSelector=type%3Dbootstrap.kubernetes.io%2Ftoken": tls: failed to verify certificate: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
To see the stack trace of this error execute with --v=5 or higher
Unable to connect to the server: tls: failed to verify certificate: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")

# 10. How to use the inrastructure end‑to‑end

How This Works Now

Requirements:
   Install VirtualBox, Vagrant, Git on your host.
   Clone your repo:
   bash
   git clone https://github.com/isaradhi24/devops-lab.git
   cd devops-lab
   Bring up the lab:
   bash
   When you run:
   vagrant up k8s-master k8s-worker1 k8s-worker2 jenkins-ci sonarqube
   Flow becomes:
   Master initializes cluster
   Master writes join command into shared folder
   Workers wait for that file
   Workers auto-join
   Swap configured
   Done

After it finishes:

Jenkins: http://192.168.56.20:8080

SonarQube: http://192.168.56.30:9000

ArgoCD: https://192.168.56.10:<nodeport> (get via kubectl -n argocd get svc argocd-server on master)

In Jenkins:

Add credentials: GitHub, Docker Hub, Sonar token, kubeconfig.

Create a pipeline job using Jenkinsfile.sample.

Push code to your app repo → run pipeline → ArgoCD deploys to K8s.


  