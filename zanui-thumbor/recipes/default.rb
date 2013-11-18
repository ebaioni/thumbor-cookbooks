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
  notifies :reload, 'service[thumbor]'
  variables({
    :instances    => #{node['thumbor']['processes']},
    :base_port    => #{node['thumbor']['base_port']},
    :server_port  => #{node["nginx"]["port"]},
  })
end

template "/etc/default/thumbor" do
    source 'thumbor.default.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    variables({
    :instances  => #{node['thumbor']['processes']},
    :base_port  => #{node['thumbor']['base_port']},
  })
end

template "/etc/thumbor.conf" do
  source 'thumbor.conf.default.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :reload, 'service[thumbor]'
  variables({
    #:instances    => #{node['thumbor']['processes']},
    #:base_port    => #{node['thumbor']['base_port']},
    #:server_port  => #{node["nginx"]["port"]},
  })

end

#sudo mv /etc/thumbor.key /etc/thumbor.key.orig
template "/etc/thumbor.key" do
  content #{node['thumbor']['key']}
  owner  'root'
  group  'root'
  mode   '0644'
  #notifies :reload, 'service[thumbor]'
end
