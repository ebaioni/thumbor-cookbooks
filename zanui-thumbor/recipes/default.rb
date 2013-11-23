#
# Cookbook Name:: zanui-thumbor
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
apt_repository "thumbor" do
  uri           "http://ppa.launchpad.net/thumbor/ppa/ubuntu"
  distribution  node['lsb']['codename']
  components    ["main"]
  keyserver     "keyserver.ubuntu.com"
  key           "C6C3D73D1225313B"
  deb_src       true
end

['thumbor', 'redis-server', 'git'].each do |pkg|
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
    :options    => node['thumbor']['options']
  })
end

file "/etc/thumbor.key" do
  content node['thumbor']['key']
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :restart, 'service[thumbor]'
end

python_pip node['thumbor_aws']['repository_uri'] do
  action :install
  notifies :restart, 'service[thumbor]'
end

service 'thumbor' do
 supports :restart => true
 action   :start
end
