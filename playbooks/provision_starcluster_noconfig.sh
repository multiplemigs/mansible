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
  echo "simple configuration with user configuration and post configuration"
  ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/conf_p_starcluster.yml --extra-vars "clustername=${clustername}" --vault-password-file ~/.testpw
  if [ $? -eq 0 ]
  then
    echo "Successfully ran playbook!"
    echo "inventory refresh complete!"
    echo "now fixing sge"
    ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/fix_my_cluster.yml --extra-vars "clustername=${clustername}"
    echo "sge play ran"
    echo "now running add_cluster_user"
    while read -u 9 scuser; do
      ansible -m shell -a ". /home/ubuntu/nitrcce/bin/starcluster.sh && add_cluster_user $scuser" -s security_group__sc-${clustername} -u root
    done 9< ./scuserlist
    echo "add_cluster_user complete"
    echo "now running adduser"
    while read -u 9 scuser; do
      ansible -m shell -a "adduser --disabled-password --gecos \"\" $scuser" -s security_group__sc-${clustername} -u root
    done 9< ./scuserlist
    if [ $? -eq 0 ]
    then
      echo "Successfully added users"
      while read -u 9 scuser; do
        ansible-playbook -e "cluster=${clustername} name=$scuser" /etc/ansible/playbooks/adduser_tocluster.yml
      done 9< ./scuserlist
      if [ $? -eq 0 ]
      then
        echo "Successfully configured user ssh keys"
        exit 0
      else
        echo "could not configure user ssh keys" >&2
        exit 1
      fi
    else
      echo "Could not add users" >&2
      exit 1
    fi 
  else
    echo "playbook run successful"
    echo "could not add or configure users" >&2
  fi
else
  echo "Could not run playbook" >&2
  exit 1
fi
