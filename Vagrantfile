# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # https://atlas.hashicorp.com/centos/boxes/7
  config.vm.box = "centos/7"

  config.vm.hostname = "admiral-stats.dev"

  config.vm.network "forwarded_port", guest: 3000, host: 80

  if defined?(VagrantPlugins::HostsUpdater)
    config.vm.network "private_network", ip: "192.168.33.10"
    config.hostsupdater.remove_on_suspend = false
  end

  if config.vm.networks.any? { |type, options| type == :private_network }
    config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ['rw', 'vers=3', 'tcp']
  else
    config.vm.synced_folder ".", "/vagrant"
  end

  config.vm.provider "virtualbox" do |vb|
    vb.name = "admiral-stats"

    vb.memory = "1024"

    # ホストOSと時刻を合わせる（合わせない場合は 1）
    vb.customize ["setextradata", :id, "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled", 0]

    # Mac をサスペンドしたときの時刻ズレを防ぐための設定（同期される閾値を、デフォルトの20分から1分に変更）
    # vagrant vbguest plugin をインストールしておく必要がある
    # > vagrant plugin install vagrant-vbguest
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 60000]
  end

  # Full provisioning script, only runs on first 'vagrant up' or with 'vagrant provision'
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "vagrant/playbook.yml"
  end
end
