# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-18.04"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get -q update
    apt-get install -qy librdf-trine-perl librdf-query-perl libxml-libxslt-perl libmodule-build-perl libfile-share-perl cpanminus perl-doc
    cpanm MARC::Record MARC::File::XML
    cd /vagrant && perl Build.PL && ./Build && sudo ./Build install
  SHELL
end
