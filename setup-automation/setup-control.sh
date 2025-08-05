#!/bin/bash

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service

nmcli connection add type ethernet con-name enp2s0 ifname enp2s0 ipv4.addresses 192.168.1.10/24 ipv4.method manual connection.autoconnect yes
nmcli connection up enp2s0
echo "192.168.1.10 control.lab control" >> /etc/hosts

# # Setup rhel user
# cp -a /root/.ssh/* /home/rhel/.ssh/.
# chown -R rhel:rhel /home/rhel/.ssh
# mkdir -p /home/rhel/lab_exercises/1.Terraform_Basics
# mkdir -p /home/rhel/lab_exercises/2.Terraform_Ansible
# mkdir -p /home/rhel/lab_exercises/3.Terraform_Provider
# mkdir -p /home/rhel/lab_exercises/4.Terraform_AAP_Provider
# mkdir -p /home/rhel/terraform-ee
# mkdir /tmp/terraform_lab/
# mkdir /tmp/terraform-ansible
# mkdir /tmp/terraform-aap-provider
# mkdir -p /home/rhel/.terraform.d/plugin-cache
# #
# #
# #chown rhel:rhel /home/rhel/.terraformrc
# chown -R rhel:rhel /home/rhel/lab_exercises/
# chown rhel:rhel /home/rhel/.terraform.d/plugin-cache
# chmod -R 777 /home/rhel/lab_exercises/
# #
# firewall-cmd --permanent --add-port=8043/tcp
# firewall-cmd --reload
# #
# yum install -y unzip
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip -qq awscliv2.zip
# sudo ./aws/install
# chown -R rhel:rhel /home/rhel/lab_exercises
# chmod -R 777 /home/rhel/lab_exercises
# #
# yum install -y dnf
# dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
# yum install terraform -y
# #
# #
# tee /home/rhel/lab_exercises/4.Terraform_AAP_Provider/main.tf << EOF
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "6.2.0"
#     }
# ####### UNCOMMENT the lines BELOW #######
# #    aap = {
# #      source = "ansible/aap"
# #    }
#   }
# }
# #
# provider "aws" {
#   region = "us-east-1"
# }
# #
# resource "aws_instance" "tf-instance-aap-provider" {
#   ami           = "ami-0005e0cfe09cc9050"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "tf-instance-aap-provider"
#   }
# }
# ####### UNCOMMENT the lines BELOW #######
# #provider "aap" {
# #  host     = "https://controller"
# #  username = "admin"
# #  password = "ansible123!"
# #  insecure_skip_verify = true
# #}
# ####### UNCOMMENT the lines BELOW #######
# #resource "aap_host" "tf-instance-aap-provider" {
# #  inventory_id = 2
# #  name = "aws_instance_tf"
# #  description = "An EC2 instance created by Terraform"
# #  variables = jsonencode(aws_instance.tf-instance-aap-provider)
# #}
# #
# EOF
# #
# chown rhel:rhel /home/rhel/lab_exercises/4.Terraform_AAP_Provider/main.tf
# #
# #


# # Create directory if it doesn't exist
# mkdir -p /home/rhel/.aws

# # Create the credentials file
# cat > /home/rhel/.aws/credentials << EOF
# [default]
# aws_access_key_id = $AWS_ACCESS_KEY_ID
# aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
# EOF

# # Set proper ownership and permissions
# chown rhel:rhel /home/rhel/.aws/credentials
# chmod 600 /home/rhel/aws/credentials

# cat > /home/rhel/aws/config << EOF
# [default]
# region = $AWS_DEFAULT_REGION
# EOF

# # Set proper ownership and permissions
# chown rhel:rhel /home/rhel/aws/config
# chmod 600 /home/rhel/aws/config

# #
# #Create the DEFAULT AWS VPC
# su - rhel -c "aws ec2 create-default-vpc --region $AWS_DEFAULT_REGION"
# #
# #
# #Create the S3 bucket for the users of this AAP / Terraform lab
# # Variables
# BUCKET_PREFIX="aap-tf-bucket"  # Change this to your desired bucket prefix
# RANDOM_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')  # Generate a random UUID and convert to lowercase
# BUCKET_NAME="${BUCKET_PREFIX}-${RANDOM_ID}"
# AWS_REGION="$AWS_DEFAULT_REGION"  # Change this to your desired AWS region
# #
# #
# # Create the S3 STORAGE BUCKET NEEDED BY THE AAP 2.X CHALLENGE
# echo "Creating S3 bucket: $BUCKET_NAME in region $AWS_DEFAULT_REGION"
# su - rhel -c "aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_DEFAULT_REGION --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION"
# #
# # ## ansible home
# # mkdir /home/$USER/ansible
# # ## ansible-files dir
# # mkdir /home/$USER/ansible-files

# # ## ansible.cfg
# # echo "[defaults]" > /home/$USER/.ansible.cfg
# # echo "inventory = /home/$USER/ansible-files/hosts" >> /home/$USER/.ansible.cfg
# # echo "host_key_checking = False" >> /home/$USER/.ansible.cfg

# # ## chown and chmod all files in rhel user home
# # chown -R rhel:rhel /home/$USER/ansible
# # chmod 777 /home/$USER/ansible
# # chown -R rhel:rhel /home/$USER/ansible-files

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
  
    # - name: Add SSH Controller credential to automation controller
    #   ansible.controller.credential:
    #     name: SSH Controller Credential
    #     description: Creds to be able to SSH the contoller_host
    #     organization: "Default"
    #     state: present
    #     credential_type: "Machine"
    #     controller_username: "{{ username }}"
    #     controller_password: "{{ admin_password }}"
    #     controller_host: "https://{{ ansible_host }}"
    #     validate_certs: false
    #     inputs:
    #       username: rhel
    #       ssh_key_data: "{{ lookup('file','/home/rhel/.ssh/id_rsa') }}"
    #   register: controller_try
    #   retries: 10
    #   until: controller_try is not failed

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
          username: "{{ lookup('env','INSTRUQT_AWS_ACCOUNT_AWSACCOUNT_AWS_ACCESS_KEY_ID') }}"
          password: "{{ lookup('env','INSTRUQT_AWS_ACCOUNT_AWSACCOUNT_AWS_SECRET_ACCESS_KEY') }}"
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

EOF
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/aws_setup.yml

# curl -fsSL https://code-server.dev/install.sh | sh
# sudo systemctl enable --now code-server@$USER
