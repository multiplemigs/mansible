#!/bin/bash
#Jenkins will pass tagname, buildname and optionally buildsource/owner information to be used as ec2 Tag Keys
while getopts ":n:b:s:" o; do
    case "${o}" in
        n)
            tagname=${OPTARG}
            ;;
        b)
            buildname=${OPTARG}
            ;;
        s)
            owner=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

#Error if Jenkins does not pass tagname or Buildname
if [ -z "${tagname}" ] || [ -z "${buildname}" ]; then
  echo "ERROR: jenkins must provide a tagname and buildname using -n and -b. owner may be provided with -s"
  exit 1
fi

#Run playbook for node provision
ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/provision_dev_conf_tomcatapp.yml --vault-password-file /home/jenkins/.vecsss --extra-vars "tagname=${tagname} buildname=${buildname} owner=${owner}"

#Error check
if [ $? -eq 0 ]
then
  echo "playbook run OK..."
  echo "refreshing inventory file"
  #refresh ansible-inventory and show new node in inventory
  /etc/ansible/hosts --refresh-cache|grep -A 10 "tag_Name_${tagname}"
  if [ $? -eq 0 ]
  then
    echo "Successfully ran playbook!"
    echo "inventory refresh complete!"
    exit 0
  else
    echo "playbook run successful"
    echo "could not refresh inventory file" >&2
    exit 1
  fi
else
  echo "Could not run playbook" >&2
  exit 1
fi
