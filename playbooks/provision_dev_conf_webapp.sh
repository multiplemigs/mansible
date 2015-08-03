#!/bin/bash
while getopts ":n:b:s:" o; do
    case "${o}" in
        n)
            tagname=${OPTARG}
            ;;
        b)
            buildname=${OPTARG}
            ;;
        s)
            buildname=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${tagname}" ] || [ -z "${buildname}" ]; then
  echo "ERROR: jenkins must provide a tagname and buildname using -n and -b. source must also be provided with -s source"
  exit 1
fi

#ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/provision_dev_conf_ndarweb.yml --vault-password-file /home/jenkins/.vecsss --extra-vars "tagname=${tagname} buildname=${buildname} source=${soure}"
ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/provision_dev_conf_ndarweb.yml --vault-password-file /home/jenkins/.vecsss --extra-vars '{"tagname":"$tagname","buildname":"$buildname"}'
if [ $? -eq 0 ]
then
  echo "playbook run OK..."
  echo "refreshing inventory file"
  /etc/ansible/hosts --refresh-cache|grep -A 10 "Devstack"
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
