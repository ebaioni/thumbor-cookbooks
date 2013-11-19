#
# Cookbook Name:: zanui-thumbor
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "apt"
include_recipe "nginx"
include_recipe "curl"

bash "install_thumbor" do
  user "root"
  cwd "/tmp"
  code <<-EOH
   #test if is necessary
  curl http://python-distribute.org/distribute_setup.py | sudo python

  EOH
end

apt_repository "thumbor" do
  uri           "http://ppa.launchpad.net/thumbor/ppa/ubuntu"
  distribution  node['lsb']['codename']
  components    ["main"]
  keyserver     "keyserver.ubuntu.com"
  key           "C6C3D73D1225313B"
  deb_src       true
end


  #sudo aptitude install -yq thumbor
  #sudo aptitude install -yq redis-server
['thumbor', 'redis-server'].each do |pkg|
    package pkg
end

execute "redis-restart" do
  command 'sudo update-rc.d redis-server enable > /dev/null'
end

template "/etc/nginx/conf.d/thumbor.conf" do
  source 'nginx.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :restart, 'service[thumbor]'
  variables({
    :instances    => node['thumbor']['processes'],
    :base_port    => node['thumbor']['base_port'],
    :server_port  => node["nginx"]["port"],
  })
end

template "/etc/default/thumbor" do
    source 'thumbor.default.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :restart, 'service[thumbor]'
    variables({
    :instances  => node['thumbor']['processes'],
    :base_port  => node['thumbor']['base_port'],
  })
end

template "/etc/thumbor.conf" do
  source 'thumbor.conf.default.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :restart, 'service[thumbor]'
  variables({
    #:instances    => "#{node['thumbor']['processes']}",
    #:base_port    => "#{node['thumbor']['base_port']}",
    #:server_port  => "#{node["nginx"]["port"]}",
  })

end

#sudo mv /etc/thumbor.key /etc/thumbor.key.orig
file "/etc/thumbor.key" do
  content node['thumbor']['key']
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :restart, 'service[thumbor]'
end

service 'thumbor' do
 supports :restart => true
 action   :start
end
