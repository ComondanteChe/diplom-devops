[all]
%{ for node in master_nodes ~}
${node.name} ansible_host=${node.ansible_host} ip=${node.ip}
%{ endfor ~}
%{ for node in worker_nodes ~}
${node.name} ansible_host=${node.ansible_host} ip=${node.ip}
%{ endfor ~}

[master]
%{ for node in master_nodes ~}
${node.name}
%{ endfor ~}

[etcd]
%{ for node in master_nodes ~}
${node.name}
%{ endfor ~}

[worker]
%{ for node in worker_nodes ~}
${node.name}
%{ endfor ~}

[calico_rr]

[k8s_cluster:children]
master
worker
calico_rr

[all:vars]
ansible_user=${ssh_user}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'