# #-*- mode: ruby -*-
# # vi: set ft=ruby :

# VAGRANTFILE_API_VERSION = "2"
# Vagrant.require_version ">= 2.2.4"

# Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
#  config.vm.box = "bento/debian-9"
#  config.vm.synced_folder ".", "/vagrant/"
#  config.vm.define :waiwera, primary: true do |waiwera|
#    waiwera.vm.provision :shell, inline: "apt install python-pip -y && pip install -U ansible"
#    waiwera.vm.provision "ansible_local" do |ansible|
#      #ansible.limit = 'waiwera'
#      ansible.provisioning_path = "/waiwera/install/ansible"
#      ansible.verbose = "vv"
#      ansible.playbook = "vagrant.yml"
#      ansible.raw_arguments = [
#       '-vv',
#      ]
#    end
#    waiwera.vm.provision :shell, inline: "sh /etc/profile.d/opt_paths.sh; cd /vagrant/waiwera; python unit_tests.py", privileged: false
#    waiwera.vm.hostname = "waiwera-debian"
#  end
#  config.vm.provider :virtualbox do |v|
# #    v.gui = true
#    v.memory = 4096
#  end
#  if Vagrant.has_plugin?("vagrant-cachier")
#    config.cache.scope = :box
#  end
# end

VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2.2.4"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/ubuntu-18.04"
  config.vm.synced_folder ".", "/vagrant/waiwera"
  config.vm.define :waiwera, primary: true do |waiwera|
    waiwera.vm.provision :shell, inline: "apt install python-pip -y && pip install --upgrade ansible"
    # Root access for initial setup
    waiwera.vm.provision "ansible_local" do |ansible|
      ansible.provisioning_path = "/vagrant/waiwera/install/ansible"
      ansible.verbose = "vv"
      ansible.playbook = "vagrant_setup.yml"
      ansible.raw_arguments = [
        '-e "app_user=waiwera"',
        '-e "app_group=waiwera"',
        '-e "base_dir=/home/waiwera"',
      ]
    end
    # Non root for local app install
    waiwera.vm.provision "ansible_local" do |ansible|
      ansible.provisioning_path = "/vagrant/waiwera/install/ansible"
      ansible.verbose = "vv"
      ansible.playbook = "vagrant_remote.yml"
      ansible.raw_arguments = [
        '-e "app_user=waiwera"',
        '-e "app_group=waiwera"',
        '-e "base_dir=/home/waiwera"',
      ]
    end
    waiwera.vm.provision :shell, inline: "su - waiwera -c 'cd /home/waiwera/waiwera; /bin/bash .bashrc; echo $PATH; python unit_tests.py'"
    waiwera.vm.hostname = "waiwera-ubuntu"
  end
  config.vm.provider :virtualbox do |v|
#    v.gui = true
    v.memory = 4096
  end
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end
end