#!/bin/bash

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service

nmcli connection add type ethernet con-name enp2s0 ifname enp2s0 ipv4.addresses 192.168.1.10/24 ipv4.method manual connection.autoconnect yes
nmcli connection up enp2s0
echo "192.168.1.10 control.lab control controller" >> /etc/hosts

systemctl stop firewalld
systemctl disable firewalld


echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers
echo "Checking SSH keys for rhel user..."

RHEL_SSH_DIR="/home/rhel/.ssh"
RHEL_PRIVATE_KEY="$RHEL_SSH_DIR/id_rsa"
RHEL_PUBLIC_KEY="$RHEL_SSH_DIR/id_rsa.pub"

if [ -f "$RHEL_PRIVATE_KEY" ]; then
    echo "SSH key already exists for rhel user: $RHEL_PRIVATE_KEY"
else
    echo "Creating SSH key for rhel user..."
    sudo -u rhel mkdir -p /home/rhel/.ssh
    sudo -u rhel chmod 700 /home/rhel/.ssh
    sudo -u rhel ssh-keygen -t rsa -b 4096 -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N "" -q
    sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*
    
    if [ -f "$RHEL_PRIVATE_KEY" ]; then
        echo "SSH key created successfully for rhel user"
    else
        echo "Error: Failed to create SSH key for rhel user"
    fi
fi

########
## install python3 libraries needed for the Cloud Report
dnf install -y python3-pip python3-libsemanage

# Create a playbook for the user to execute

## install python3 libraries needed for the Cloud Report
dnf install -y python3-pip python3-libsemanage

# Create a playbook for the user to execute
tee /tmp/aws_setup.yml << EOF
---
- name: Deploy credentials and AAP resources
  hosts: localhost
  gather_facts: false
  become: true
  vars:
    username: admin
    admin_password: ansible123!
    ansible_host: localhost
    aws_access_key: "{{ lookup('env', 'AWS_ACCESS_KEY_ID') | default('AWS_ACCESS_KEY_ID_NOT_FOUND', true) }}"
    aws_secret_key: "{{ lookup('env', 'AWS_SECRET_ACCESS_KEY') | default('AWS_SECRET_ACCESS_KEY_NOT_FOUND', true) }}"
    aws_default_region: "{{ lookup('env', 'AWS_DEFAULT_REGION') | default('AWS_DEFAULT_REGION_NOT_FOUND', true) }}"
    quay_username: "{{ lookup('env', 'QUAY_USERNAME') | default('QUAY_USERNAME_NOT_FOUND', true) }}"
    quay_password: "{{ lookup('env', 'QUAY_PASSWORD') | default('QUAY_PASSWORD_NOT_FOUND', true) }}"

  tasks:
  
    - name: Add SSH Controller credential to automation controller
      ansible.controller.credential:
        name: SSH Controller Credential
        description: Creds to be able to SSH the contoller_host
        organization: "Default"
        state: present
        credential_type: "Machine"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false
        inputs:
          username: rhel
          ssh_key_data: "{{ lookup('file','/home/rhel/.ssh/id_rsa') }}"
      register: controller_try
      retries: 10
      until: controller_try is not failed

    - name: Add AWS credential to automation controller
      ansible.controller.credential:
        name: AWS_Credential
        description: Amazon Web Services
        organization: "Default"
        state: present
        credential_type: "Amazon Web Services"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false
        inputs:
          username: "{{ aws_access_key }}"
          password: "{{ aws_secret_key }}"
      register: controller_try
      retries: 10
      until: controller_try is not failed

    - name: Add EE to the controller instance
      ansible.controller.execution_environment:
        name: "AWS Execution Environment"
        image: quay.io/acme_corp/aws_ee
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false

    - name: Add project
      ansible.controller.project:
        name: "AWS Demos Project"
        description: "This is from github.com/ansible-cloud"
        organization: "Default"
        state: present
        scm_type: git
        scm_url: https://github.com/ansible-tmm/awsops25.git
        default_environment: "Default execution environment"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false

    - name: Delete native job template
      ansible.controller.job_template:
        name: "Demo Job Template"
        state: "absent"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false

    - name: Create job template
      ansible.controller.job_template:
        name: "{{ item.name }}"
        job_type: "run"
        organization: "Default"
        inventory: "Demo Inventory"
        project: "AWS Demos Project"
        playbook: "{{ item.playbook }}"
        credentials:
          - "AWS_Credential"
        state: "present"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false
        extra_vars:
          controller_host: "{{ ansible_host }}"
      with_items:
        - { playbook: 'playbooks/aws_resources.yml', name: 'Create AWS Resources' }
        - { playbook: 'playbooks/aws_instances.yml', name: 'Create AWS Instances' }
        
    - name: Launch a job template
      ansible.controller.job_launch:
        job_template: "Create AWS Resources"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false
      register: job

    - name: Wait for job to finish
      ansible.controller.job_wait:
        job_id: "{{ job.id }}"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"        
        validate_certs: false

    - name: Launch a job template
      ansible.controller.job_launch:
        job_template: "Create AWS Instances"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false
      register: job2

    - name: Wait for job2 to finish
      ansible.controller.job_wait:
        job_id: "{{ job2.id }}"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"        
        validate_certs: false

    - name: Add an AWS INVENTORY
      ansible.controller.inventory:
        name: "AWS Inventory"
        description: "Our AWS Inventory"
        organization: "Default"
        state: present
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false

    - name: Add an AWS InventorySource
      ansible.controller.inventory_source:
        name: "AWS Source"
        description: "Source for the AWS Inventory"
        inventory: "AWS Inventory"
        credential: "AWS_Credential"
        source: ec2
        overwrite: "True"
        update_on_launch: "True"
        organization: "Default"
        source_vars:
          private: "false"
          hostnames:
            - 'tag:Name'
          compose: 
            ansible_host: public_ip_address
        state: present
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false

    - name: Update a single inventory source
      ansible.controller.inventory_source_update:
        name: "AWS Source"
        inventory: "AWS Inventory"
        organization: "Default"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false

    - name: Add ansible-1 host
      ansible.controller.host:
        name: "ansible-1"
        inventory: "Demo Inventory"
        state: present
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false
        variables:
            note: in production these passwords would be encrypted in vault
            ansible_user: rhel
            ansible_password: ansible123!
            ansible_host: controller

    - name: Create job templates
      ansible.controller.job_template:
        name: "Deploy Application"
        job_type: "run"
        organization: "Default"
        inventory: "AWS Inventory"
        project: "AWS Demos Project"
        playbook: "playbooks/lab2-deploy-application.yml"
        credentials:
          - "RHEL on AWS - SSH KEY"
        survey_enabled: true
        survey_spec:
          name: Deploy the application SURVEY
          description: Which applications do you want to install?
          spec:
          - type: multiselect
            question_name: "Select the applications you would like to deploy (one or more)"
            question_description: select the application
            variable: application
            required: true
            default: httpd
            choices:
              - httpd
              - nginx
              - htop
              - gdb
          - type: multiselect
            question_name: "Select the hosts you want to deploy the applications to (one or more)"
            question_description: select the host
            variable: HOSTS
            required: true
            default: rhel1
            choices:
              - rhel1
              - rhel2
        state: "present"
        controller_username: "{{ username }}"
        controller_password: "{{ admin_password }}"
        controller_host: "https://{{ ansible_host }}"
        validate_certs: false
            

EOF
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/aws_setup.yml

# curl -fsSL https://code-server.dev/install.sh | sh
# sudo systemctl enable --now code-server@$USER
