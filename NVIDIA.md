# NVIDIA and CUDA Install for OpenShift and RHEL7 on Power

Links for power 8/9

- https://www.ibm.com/support/knowledgecenter/en/SSRU69_1.1.3/base/vision_install_prereq.html

## Setup RHEL7

Enable common, optional, and extra repo channels.

```
subscription-manager repos --enable=rhel-7-for-power-9-optional-rpms
subscription-manager repos --enable=rhel-7-for-power-9-extras-rpms
subscription-manager repos --enable=rhel-7-for-power-9-rpms
```

Install DKMS (dynamic kernel module suppoert) from epel (epel can be disabled after this)

```
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -ihv epel-release-latest-7.noarch.rpm
```

Load the latest kernel or do a full update:

```
yum -y install kernel kernel-devel kernel-tools kernel-tools-libs kernel-bootwrapper
yum -y update kernel kernel-devel kernel-tools kernel-tools-libs kernel-bootwrapper
reboot
```

## NVIDIA Components: IBM POWER9 specific udev rules (Red Hat only)

- https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#power9-setup

Disable a udev rule installed by default in some Linux distributions that cause hot-pluggable memory
to be automatically onlined when it is physically probed. This behavior prevents NVIDIA software
from bringing NVIDIA device memory online with non-default settings. This udev rule must be
disabled in order for the NVIDIA CUDA driver to function properly on POWER9 systems.

Copy the /lib/udev/rules.d/40-redhat.rules file to the directory for user overridden rules.

```
cp /lib/udev/rules.d/40-redhat.rules /etc/udev/rules.d 
```

Edit / Comment out the entire "Memory hotadd request" section and save the change:

```
sed -i 's/SUBSYSTEM!="memory", ACTION!="add", GOTO="memory_hotplug_end"/SUBSYSTEM=="*", GOTO="memory_hotplug_end"/' /etc/udev/rules.d/40-redhat.rules
```

Reboot

```
sudo reboot
```

## Install the GPU driver (Red Hat)

Download the NVIDIA GPU driver:

Go to NVIDIA Driver Download

- https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=ppc64le&target_distro=RHEL&target_version=7&target_type=rpmlocal

| Selection        | Value           |
| ---------------- |:---------------:|
| Select Product Type | Tesla |
| Select Product Series | P-Series (for Tesla P100) or V-Series (for Tesla V100) |
| Select Product | Tesla P100 or Tesla V100 |
| Select Operating System | Linux POWER LE RHEL 7 for POWER or Linux 64-bit RHEL7 for x86, depending on your cluster architecture. Click Show all Operating Systems if your version is not available |
| Select CUDA Toolkit | 10.1 |
| Click | SEARCH to go to the download link |
| Click | Download to download the driver |


Install driver

```
./NVIDIA-Linux-ppc64le-418.87.00.run
```

## NVIDIA Persistenced Daemon

- https://docs.nvidia.com/deploy/driver-persistence/index.html#persistence-daemon

A Persistence Daemon is available to keep a target GPU initialized even when no clients are connected to it.

```
wget http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-rhel7-10-1-local-10.1.243-418.87.00-1.0-1.ppc64le.rpm
yum -y install cuda-repo-rhel7-10-1-local-10.1.243-418.87.00-1.0-1.ppc64le.rpm
```

Enable and Start Daemon

```
systemctl status nvidia-persistenced
systemctl enable nvidia-persistenced
systemctl start nvidia-persistenced
```

## Check Status of the NVIDIA GPU Driver from GPU Host

At this point you chould be able to check that NVIDIA drivers are loaded via dkms:

```
dkms status
nvidia, 418.87.00, 4.14.0-115.13.1.el7a.ppc64le, ppc64le: installed
```

And that the NVIDIA devices are visible, in this lab, we can also see NVLINK status

```
nvidia-smi
Mon Oct 14 09:12:39 2019       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.87.00    Driver Version: 418.87.00    CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla V100-SXM2...  On   | 00000004:04:00.0 Off |                    0 |
| N/A   35C    P0    38W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
|   1  Tesla V100-SXM2...  On   | 00000004:05:00.0 Off |                    0 |
| N/A   38C    P0    40W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
|   2  Tesla V100-SXM2...  On   | 00000035:03:00.0 Off |                    0 |
| N/A   34C    P0    36W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
|   3  Tesla V100-SXM2...  On   | 00000035:04:00.0 Off |                    0 |
| N/A   40C    P0    36W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

We have 4 Tesla V100 GPU's with NVLINK

```
nvidia-smi nvlink --status -i 0,1,2,3
GPU 0: Tesla V100-SXM2-16GB (UUID: GPU-09101d09-2345-0823-9f93-c9f49b9aebac)
	 Link 0: 25.781 GB/s
	 Link 1: 25.781 GB/s
	 Link 2: 25.781 GB/s
	 Link 3: 25.781 GB/s
	 Link 4: 25.781 GB/s
	 Link 5: 25.781 GB/s
GPU 1: Tesla V100-SXM2-16GB (UUID: GPU-2f472f47-2093-5eb6-6eb1-a2cce2e0c5ee)
	 Link 0: 25.781 GB/s
	 Link 1: 25.781 GB/s
	 Link 2: 25.781 GB/s
	 Link 3: 25.781 GB/s
	 Link 4: 25.781 GB/s
	 Link 5: 25.781 GB/s
GPU 2: Tesla V100-SXM2-16GB (UUID: GPU-c7816ea6-809b-d606-8689-ab279b29d6f1)
	 Link 0: 25.781 GB/s
	 Link 1: 25.781 GB/s
	 Link 2: 25.781 GB/s
	 Link 3: 25.781 GB/s
	 Link 4: 25.781 GB/s
	 Link 5: 25.781 GB/s
GPU 3: Tesla V100-SXM2-16GB (UUID: GPU-5686108a-c647-af17-0a65-3d1b5fbb69c6)
	 Link 0: 25.781 GB/s
	 Link 1: 25.781 GB/s
	 Link 2: 25.781 GB/s
	 Link 3: 25.781 GB/s
	 Link 4: 25.781 GB/s
	 Link 5: 25.781 GB/s
```

Check driver version

```
cat /proc/driver/nvidia/version
NVRM version: NVIDIA UNIX ppc64le Kernel Module  418.87.00  Thu Aug  8 15:32:09 CDT 2019
GCC version:  gcc version 4.8.5 20150623 (Red Hat 4.8.5-36) (GCC)
```

## Container Runtime Hook for NVIDIA Docker

- https://nvidia.github.io/nvidia-container-runtime/

The version of docker shipped by Red Hat (1.13.1) includes support for OCI runtime hooks. Because of this, we only need to install the `nvidia-container-runtime-hook` package and create a hook file. On other distributions of docke (such as docker-ce) require you to run `nvidia-docker`. `Do not install docker-ce`. We want to stick with the supported docker version from RH.

Repo

```
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo
```

Install Hook rpm

```
yum -y install nvidia-container-runtime-hook.ppc64le
reboot
```

Configure Hook runtime file

Edit `toml` file, e.g. enable debug

```
cat /etc/nvidia-container-runtime/config.toml
disable-require = false
#swarm-resource = "DOCKER_RESOURCE_GPU"

[nvidia-container-cli]
#root = "/run/nvidia/driver"
#path = "/usr/bin/nvidia-container-cli"
environment = []
debug = "/var/log/nvidia-container-runtime-hook.log"
#ldcache = "/etc/ld.so.cache"
load-kmods = true
#no-cgroups = false
user = "root:root"
ldconfig = "@/sbin/ldconfig"
```

Set config for use by runtime hook

```
cat <<'EOF' > /usr/libexec/oci/hooks.d/oci-nvidia-hook
#!/bin/bash
/usr/bin/nvidia-container-runtime-hook -config /etc/nvidia-container-runtime/config.toml $@
EOF

chmod +x /usr/libexec/oci/hooks.d/oci-nvidia-hook
```

## Privilege and SELINUX and LDCONFIG

Selinux is not setup for NVIDIA and containers on ppc64le. We need to run containers as privileged (`BUG ?`)

```
sudo chcon -t container_file_t  /dev/nvidia*
```

To make permanent (`THIS NEEDS TO BE FIXED/WORKING`)

```
semanage fcontext -a -t container_file_t "/dev/nvidia*"
cat /etc/selinux/targeted/contexts/files/file_contexts.local
restorecon -R -v /dev/nvidia*
```

Test using the NVIDIA container. We need to use `ldconfig` to load the bind mounted NVIDIA libraries (`WHY? - NOT SURE IF THIS IS A BUG`)

```
docker run --rm nvidia/cuda-ppc64le ldconfig && nvidia-smi

Mon Oct 14 09:38:23 2019       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.87.00    Driver Version: 418.87.00    CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla V100-SXM2...  On   | 00000004:04:00.0 Off |                    0 |
| N/A   35C    P0    38W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
|   1  Tesla V100-SXM2...  On   | 00000004:05:00.0 Off |                    0 |
| N/A   38C    P0    40W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
|   2  Tesla V100-SXM2...  On   | 00000035:03:00.0 Off |                    0 |
| N/A   33C    P0    36W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
|   3  Tesla V100-SXM2...  On   | 00000035:04:00.0 Off |                    0 |
| N/A   39C    P0    36W / 300W |      0MiB / 16130MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

Errors and logs for the runtime hook should be available here:

```
cat /var/log/nvidia-container-runtime-hook.log
```

## OpenShift GPU Device Plugin

- https://blog.openshift.com/how-to-use-gpus-with-deviceplugin-in-openshift-3-10/

To schedule the Device Plugin on nodes that include GPUs, label the node as follows:

```
oc label node ocp-wvm1.syd.iic.ihost.com openshift.com/gpu-accelerator=true --overwrite
```

Deploy the OpenShift Device Plugin Dameonset

```
oc new-project nvidia-device-plugin
oc create -f nvidia-device-plugin/files/nvidia-device-plugin-scc.yaml
oc create serviceaccount nvidia-deviceplugin
oc create -f nvidia-device-plugin/files/nvidia-device-plugin-daemonset.yaml
```

Pods with the following resource limits set will now be scheduled to GPU nodes only:

```
     resources:
       limits:
         nvidia.com/gpu: 1 # requesting 1 GPU
```

## Example GPU Container Workloads

Create project (`BUG - privileged, else device plugin cannot mount nvidia libs?`)

Also, need to specify `CUDA_VISIBLE_DEVICES` environment else CUDA errors in intialization (`BUG - cuda should be able to locate devices?`)


```
oc new-project cuda-vector-add
oc adm policy add-scc-to-user privileged -z default -n cuda-vector-add
```

Tensorflow - test GPU devices

```
oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
 name: tensorflow
spec:
 restartPolicy: OnFailure
 containers:
   - name: tensorflow
     image: "docker.io/ibmcom/tensorflow-ppc64le:latest-gpu"
     securityContext:
       privileged: true
     resources:
       limits:
         nvidia.com/gpu: 1 # requesting 1 GPU
     command: [ "/bin/bash", "-c", "python -c 'import tensorflow as tf;import signal;tf.test.gpu_device_name(); signal.pause();'" ]
     env:
       - name: NVIDIA_VISIBLE_DEVICES
         value: all
       - name: NVIDIA_DRIVER_CAPABILITIES
         value: "compute,utility"
       - name: NVIDIA_REQUIRE_CUDA
         value: "cuda>=10.0"
       - name: CUDA_VISIBLE_DEVICES
         value: "0,1,2"
EOF
```

CUDA - test vector add

```
oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
 name: cuda
spec:
 restartPolicy: OnFailure
 containers:
   - name: cuda
     image: "docker.io/nvidia/cuda-ppc64le:10.1-devel"
     securityContext:
       privileged: true
     resources:
       limits:
         nvidia.com/gpu: 1 # requesting 1 GPU
     command: [ "/bin/bash", "-c", "sleep infinity" ]
     env:
       - name: NVIDIA_VISIBLE_DEVICES
         value: all
       - name: NVIDIA_DRIVER_CAPABILITIES
         value: "compute,utility"
       - name: NVIDIA_REQUIRE_CUDA
         value: "cuda>=10.0"	 
       - name: CUDA_VISIBLE_DEVICES
         value: "0,1,2"
EOF

oc rsh cuda
nvidia-smi
nvcc --version
```

Manually compile vector add in container and run

```
cat <<'EOF' > /tmp/vector_add.cu
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <cuda.h>
#include <cuda_runtime.h>

#define N 10000000
#define MAX_ERR 1e-6

__global__ void vector_add(float *out, float *a, float *b, int n) {
    for(int i = 0; i < n; i ++){
        out[i] = a[i] + b[i];
    }
}

int main(){
    float *a, *b, *out;
    float *d_a, *d_b, *d_out; 

    // Allocate host memory
    a   = (float*)malloc(sizeof(float) * N);
    b   = (float*)malloc(sizeof(float) * N);
    out = (float*)malloc(sizeof(float) * N);

    // Initialize host arrays
    for(int i = 0; i < N; i++){
        a[i] = 1.0f;
        b[i] = 2.0f;
    }

    // Allocate device memory
    cudaMalloc((void**)&d_a, sizeof(float) * N);
    cudaMalloc((void**)&d_b, sizeof(float) * N);
    cudaMalloc((void**)&d_out, sizeof(float) * N);

    // Transfer data from host to device memory
    cudaMemcpy(d_a, a, sizeof(float) * N, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, sizeof(float) * N, cudaMemcpyHostToDevice);

    // Executing kernel 
    vector_add<<<1,1>>>(d_out, d_a, d_b, N);
    
    // Transfer data back to host memory
    cudaMemcpy(out, d_out, sizeof(float) * N, cudaMemcpyDeviceToHost);

    // Verification
    for(int i = 0; i < N; i++){
        assert(fabs(out[i] - a[i] - b[i]) < MAX_ERR);
    }
    printf("out[0] = %f\n", out[0]);
    printf("PASSED\n");

    // Deallocate device memory
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_out);

    // Deallocate host memory
    free(a); 
    free(b); 
    free(out);
}
EOF

# compile
nvcc -o vector_add /tmp/vector_add.cu
./vector_add

# profile
nvprof --print-nvlink-topology ./vector_add
```
