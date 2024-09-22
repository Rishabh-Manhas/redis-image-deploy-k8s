# redis-image-deploy-k8s
**DEPLOYING A REDIS BASED DOCKER IMAGE TO KUBERNETES  


**Purpose**

The purpose of this project is to enable efficient data storage and caching using Redis within a Kubernetes environment. By deploying a Redis instance on Kubernetes, the organization aims to leverage the scalability, reliability, and management features of Kubernetes to support application performance and data integrity.

**Objectives**

1. **Create a Custom Redis Docker Image**: Develop a tailored Docker image based on the official Redis image, ensuring it meets specific organizational requirements.
2. **Publish the Docker Image**: Upload the custom Redis image to Docker Hub, allowing easy access for team members and facilitating version control.
3. **Set Up a Kubernetes Cluster**: Deploy a Kubernetes cluster on Azure to host the Redis instance, utilizing managed services for ease of maintenance.
4. **Deploy Redis on Kubernetes**: Implement a deployment strategy to run Redis in a pod, ensuring that it can handle data storage and caching efficiently.

&nbsp;

**Procedure**

1. **Create a Docker Hub Account**

- Go to Docker Hub and sign up for a new account if you don’t have one.
- Verify your email and log in to your account.

1. **Create a Redis Docker Image**

- Ensure you have Docker installed on your local machine.
- Create a file named Dockerfile with the following content:

```
# Taking redis as base image

FROM redis

# Exposing redis default port to the Host OS

EXPOSE 6379

# Starting the redis service in the container

CMD \["redis-server"\]
```

- Now build the docker image by running the docker build command and it’s name should follow this syntax for it be uploaded on dockerhub otherwise you can’t upload it in dockerhub:  
    Syntax : &lt;dockerhub-username&gt;/&lt;image-name&gt;

```
labsuser@ip-172-31-46-42:~/redis_project$ sudo docker build -t rishabhmanhas/redis .

DEPRECATED: The legacy builder is deprecated and will be removed in a future release.

&nbsp;           Install the buildx component to build images with BuildKit:

&nbsp;           <https://docs.docker.com/go/buildx/>

Sending build context to Docker daemon  14.85kB

Step 1/3 : FROM redis

latest: Pulling from library/redis

a2318d6c47ec: Pull complete

ed7fd66f27f2: Pull complete

410a3d5b3155: Pull complete

9312cf3f6b3e: Pull complete

c39877ab23d0: Pull complete

01394ffc7248: Pull complete

4f4fb700ef54: Pull complete

5a03cb6163ab: Pull complete

Digest: sha256:eadf354977d428e347d93046bb1a5569d701e8deb68f090215534a99dbcb23b9

Status: Downloaded newer image for redis:latest

&nbsp;---> 590b81f2fea1

Step 2/3 : EXPOSE 6379

&nbsp;---> Running in 35d7ad5f2764

Removing intermediate container 35d7ad5f2764

&nbsp;---> 9e1475e49555

Step 3/3 : CMD \["redis-server"\]

&nbsp;---> Running in 4a5ecc1f94f1

Removing intermediate container 4a5ecc1f94f1

&nbsp;---> 19136460b830

Successfully built 19136460b830

Successfully tagged rishabhmanhas/redis:latest
```

- Verify whether the image is created successfully or not:

```
labsuser@ip-172-31-46-42:~/redis_project$ docker images

REPOSITORY            TAG       IMAGE ID       CREATED          SIZE

rishabhmanhas/redis   latest    19136460b830   27 minutes ago   117MB

redis                 latest    590b81f2fea1   6 weeks ago      117MB
```
1. **Push the Docker Image to Docker Hub**

- Use the Docker CLI to log in to dockerhub:
- Enter your Docker Hub username when prompted.
- Now go to dockerhub website and go to your account settings and create personal access token, copy that token and paste it in the cli in place of password when prompted.

```
labsuser@ip-172-31-46-42:~/redis_project$ docker login

Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to <https://hub.docker.com> to create one.

Username: 

Password:

WARNING! Your password will be stored unencrypted in /home/labsuser/.docker/config.json.

Configure a credential helper to remove this warning. See

<https://docs.docker.com/engine/reference/commandline/login/#credentials-store>

Login Succeeded

- After successfully logging in, push your image to Docker Hub
```
```
labsuser@ip-172-31-46-42:~/redis_project$ docker push rishabhmanhas/redis

Using default tag: latest

The push refers to repository \[docker.io/rishabhmanhas/redis\]

950a085c0a1c: Mounted from library/redis

5f70bf18a086: Mounted from library/redis

e4dbf0bd9d9d: Mounted from library/redis

15ef09f03230: Mounted from library/redis

40710ab1222c: Mounted from library/redis

a64e92ee1239: Mounted from library/redis

9a978e3d8066: Mounted from library/redis

8e2ab394fabf: Mounted from library/redis

latest: digest: sha256:f3f9dbcddabb85c0744a3e2f9fe731c747a3f8e61ef17917a4cd0897390c3dc5 size: 1987
```

- Start the container using the image we built to make sure that image can be instantiated as container with no issues (make sure that the image uploaded in dockerhub is publicly accessible).

```
labsuser@ip-172-31-46-42:~/redis_project$ docker run -dit --name redis_server rishabhmanhas/redis:latest

15ef21127cd6e62cc915416a5495a0bf09ea95a688bfb566a37e70be8aff9979

labsuser@ip-172-31-46-42:~/redis_project$ docker ps -a

CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS          PORTS      NAMES

15ef21127cd6   rishabhmanhas/redis:latest   "docker-entrypoint.s…"   19 seconds ago   Up 17 seconds   6379/tcp   redis_server
```

Now, we’re done with the image creation part and the next phase is to deploy this image as a Kubernetes object i.e. a pod to be specific.

For that we need a Kubernetes cluster, I’ve setup a single master multi-node cluster over Azure Cloud

using virtual machines. For this setup we need to install kubectl, kubelet and kubeadm on all of those nodes and then initialize the master in master node.

1. **Setting Up the Kubernetes Cluster on Azure:  
    **

- Log into your Azure portal and create a virtual network (VNet) for the cluster.

Note: Make sure the VM you’re using meet the following requirements:

- One or more machines running a deb/rpm-compatible Linux OS; for example: Ubuntu or CentOS.
- 2 GiB or more of RAM per machine--any less leaves little room for your apps.
- At least 2 CPUs on the machine that you use as a control-plane node.
- Full network connectivity among all machines in the cluster. You can use either a public or a private network.
- Create three Virtual Machines (VMs) for your Kubernetes master and worker nodes. Use Ubuntu as the operating system and ensure all VMs are part of the VNet.
- SSH into each VM and install required dependencies:
```
sudo apt update

sudo apt install -y apt-transport-https curl

curl -s <https://packages.cloud.google.com/apt/doc/apt-key.gpg> | sudo apt-key add -

sudo apt-add-repository "deb <http://apt.kubernetes.io/> kubernetes-xenial main"

sudo apt update

sudo apt install -y kubelet kubeadm kubectl
```
- Install a Container Runtime Interface, We’re using containerd in this case:
  
`sudo apt-get install -y containerd`

- Configure containerd to run with Kubernetes add below changes to the /etc/containerd/config.toml file and restart containerd :
```
\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc\]

 ...

 \[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]

  SystemdCgroup = true
```
`sudo systemctl restart containerd`

- Set Up the Kubernetes Master Node:

`sudo kubeadm init --pod-network-cidr=10.2.0.0/16`

# add your vnet cidr in above parameter

After running this command, cluster will be intialised and there we’ll be some intructions written in the output execute those intructions in order to complete the setup. It’ll also display a cmd to add worker nodes to the cluster copy that command and execute it in the worker nodes.
```
mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Now, install and configure a network plugin to communicate within the pods, we’ve used calico plugin.

`kubectl apply -f <https://docs.projectcalico.org/manifests/calico.yaml>`

On the master node, you’ll receive a command to join worker nodes. It will look something like this

`kubeadm join &lt;master-node-ip&gt;:6443 --token &lt;token&gt; --discovery-token-ca-cert-hash sha256:&lt;hash&gt;`

Run this command on each worker node to join them to the cluster.

- Verify that all nodes are in the Ready state:

![image](https://github.com/user-attachments/assets/9f474619-fd06-484c-a949-a6a0511bcbd9)


1. **Deploy Redis on Kubernetes**

- Now that our cluster is ready it’s time to deploy our redis based image.
- Create a Kubernetes manifest file (redis-pod.yaml) to deploy the Redis image from Docker Hub.
```
apiVersion: v1

kind: Pod

metadata:

name: redis-pod

spec:

containers:

  - name: redis-container

    image: rishabhmanhas/redis:latest

    ports:

    - containerPort: 6379
```
- Use kubectl to deploy the Redis pod.

![image](https://github.com/user-attachments/assets/1a379b2f-5aed-410c-83d5-7a0df17c9e45)


- Verify Pod Creation

![image](https://github.com/user-attachments/assets/b311d479-824d-422c-b463-bdb737a7d8a5)

![image](https://github.com/user-attachments/assets/3e38e692-22be-4ae2-9c7f-230cdce77058)


**Conclusion**

By following these steps,we’ve have successfully created a custom Redis-based Docker image, pushed it to Docker Hub, and deployed it on a Kubernetes cluster on Azure. The Redis image is now available for use in our organization’s Kubernetes environments
