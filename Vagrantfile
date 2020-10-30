Vagrant.configure("2") do |config|
  #haproxy server
  config.vm.define :haproxyserver do |haproxyserver|
    haproxyserver.vm.box = "bento/ubuntu-20.04"
    haproxyserver.vm.network :private_network, ip: "192.168.80.20"
    haproxyserver.vm.hostname = "haproxyserver"
    haproxyserver.vm.provision :shell, path: "haproxy.sh"
    haproxyserver.vm.provider "virtualbox" do |v|
      v.name = "haproxyserver"
      v.memory = 1024
      v.cpus = 1
    end
  end

  #numero de servidores web
  NodeCount = 2

  (1..NodeCount).each do |i|
    config.vm.define "webserver#{i}" do |webserver|
      webserver.vm.box = "bento/ubuntu-20.04"
      webserver.vm.hostname = "webserver#{i}"
      webserver.vm.network "private_network", ip: "192.168.80.2#{i}"
      webserver.vm.provision :shell, path: "webserver.sh", args: i
      webserver.vm.provider "virtualbox" do |v|
        v.name = "webserver#{i}"
        v.memory = 1024
        v.cpus = 1
      end
    end
  end

end