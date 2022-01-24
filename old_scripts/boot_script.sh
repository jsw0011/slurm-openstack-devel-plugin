#!/usr/bin/bash
__user=`whoami`
yum install -y python3 centos-release-ansible-29 epel-release jq git

__install_dir="/tmp/slurm-install"
mkdir $__install_dir
__meta_file="$__install_dir/meta_data.json"
curl http://169.254.169.254/openstack/latest/meta_data.json > $__meta_file # download metadata

__slave_ips=`jq -r ".meta.ips" $__meta_file | jq -r ". | to_entries[].value"`
__slave_ips_aligned=""

for _ip in __slave_ips
do
    __slave_ips_aligned="$__slave_ips_aligned            $_ip:\n"
done


_GIT_ACCESS_TOKEN=`jq -r ".meta.access_token" $__meta_file`
_MASTER_IP=`python3 -c "import socket; print(socket.gethostbyname(socket.gethostname()))"`

#repo with playbook and role
__slurm_repo_dir="$__install_dir/slurm-openstack"
mkdir $__slurm_repo_dir
git clone "https://github.com/jsw0011/slurm-openstack-devel-plugin.git" $__slurm_repo_dir 

echo "slurm-master:
    hosts:
        $_MASTER_IP:
    slurm-slaves:
        hosts:
    $__slave_ips_aligned" > $__slurm_repo_dir/openstack_init/ansible/inventory.yml