#!/bin/bash
while getopts ":q:" o; do
    case "${o}" in
        q)
            clustername=${OPTARG}
#            ;;
#        b)
#            buildname=${OPTARG}
#            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${clustername}" ]; then
  echo "ERROR: must provide cluster name with -q"
  exit 1
fi

ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/provision_starcluster.yml --extra-vars "clustername=${clustername}"
if [ $? -eq 0 ]
then
  echo "playbook run OK..."
  echo "refreshing inventory file"
  sleep 5
  /etc/ansible/hosts --refresh-cache|grep -A 10 "security_group__sc-${clustername}"
  sleep 5
  echo ${clustername}
  echo "now configuring starcluster hosts"
  echo ""
  sleep 5
  ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/conf_starcluster.yml --extra-vars "clustername=${clustername}"
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

