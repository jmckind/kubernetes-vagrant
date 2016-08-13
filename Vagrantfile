# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'

Vagrant.require_version ">= 1.6.0"

CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "user-data")
CONFIG = File.join(File.dirname(__FILE__), "config.rb")

# Defaults for config options defined in CONFIG
$num_master_nodes = 1
$num_worker_nodes = 2
$instance_name_prefix = "kube"
$master_name_prefix = "master"
$worker_name_prefix = "worker"
$update_channel = "alpha"
$image_version = "current"
$share_home = false
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1
$vm_cpuexecutioncap = 100
$shared_folders = {}
$forwarded_ports = {}

if File.exist?(CONFIG)
    require CONFIG
end

Vagrant.configure("2") do |config|
    # use vagrant's insecure key
    config.ssh.insert_key = false

    # forward ssh agent to easily ssh into the different machines
    config.ssh.forward_agent = true

    config.vm.box = "coreos-%s" % $update_channel
    if $image_version != "current"
        config.vm.box_version = $image_version
    end
    config.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]

    # disable guest additions and vboxsf
    config.vm.provider :virtualbox do |v|
        v.check_guest_additions = false
        v.functional_vboxsf     = false
    end

    # prevent plugin conflict
    if Vagrant.has_plugin?("vagrant-vbguest") then
        config.vbguest.auto_update = false
    end

    # create master nodes
    (1..$num_master_nodes).each do |i|
        config.vm.define vm_name = "%s-%s-n%02d" % [$instance_name_prefix, $master_name_prefix, i] do |config|
            config.vm.hostname = vm_name

            if $expose_docker_tcp
                config.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), host_ip: "127.0.0.1", auto_correct: true
            end

            $forwarded_ports.each do |guest, host|
                config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
            end

            config.vm.provider :virtualbox do |vb|
                vb.name = vm_name
                vb.gui = $vm_gui
                vb.memory = $vm_memory
                vb.cpus = $vm_cpus
                vb.customize ["modifyvm", :id, "--cpuexecutioncap", "#{$vm_cpuexecutioncap}"]
            end

            ip = "172.17.8.#{i+100}"
            config.vm.network :private_network, ip: ip

            # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
            #config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
            $shared_folders.each_with_index do |(host_folder, guest_folder), index|
                config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
            end

            if $share_home
                config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
            end

            cloud_config_path = "#{CLOUD_CONFIG_PATH}/master"
            if File.exist?(cloud_config_path)
                config.vm.provision :file, :source => "#{cloud_config_path}", :destination => "/tmp/vagrantfile-user-data"
                config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
            end
        end
    end

    # create worker nodes
    (1..$num_worker_nodes).each do |i|
        config.vm.define vm_name = "%s-%s-n%02d" % [$instance_name_prefix, $worker_name_prefix, i] do |config|
            config.vm.hostname = vm_name

            if $expose_docker_tcp
                config.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), host_ip: "127.0.0.1", auto_correct: true
            end

            $forwarded_ports.each do |guest, host|
                config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
            end

            config.vm.provider :virtualbox do |vb|
                vb.name = vm_name
                vb.gui = $vm_gui
                vb.memory = $vm_memory
                vb.cpus = $vm_cpus
                vb.customize ["modifyvm", :id, "--cpuexecutioncap", "#{$vm_cpuexecutioncap}"]
            end

            ip = "172.17.8.#{$num_master_nodes+i+100}"
            config.vm.network :private_network, ip: ip

            # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
            #config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
            $shared_folders.each_with_index do |(host_folder, guest_folder), index|
                config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
            end

            if $share_home
                config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
            end

            cloud_config_path = "#{CLOUD_CONFIG_PATH}/worker"
            if File.exist?(cloud_config_path)
                config.vm.provision :file, :source => "#{cloud_config_path}", :destination => "/tmp/vagrantfile-user-data"
                config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
            end
        end
    end
end
