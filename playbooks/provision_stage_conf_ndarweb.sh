#!/bin/bash
ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/provision_stage_conf_ndarweb.yml --vault-password-file /home/jenkins/.vecsss
if [ $? -eq 0 ]
then
  echo "playbook run OK..."
  echo "refreshing inventory file"
  /etc/ansible/hosts --refresh-cache|grep -A 10 "security_group_migueltestgroup-stage"
  if [ $? -eq 0 ]
  then
    echo "Successfully ran playbook!"
    echo "inventory refresh complete!"
    exit 0
  else
    echo "playbook run successful"
    echo "could not refresh inventory file" >&2
  fi
else
  echo "Could not run playbook" >&2
  exit 1
fi
