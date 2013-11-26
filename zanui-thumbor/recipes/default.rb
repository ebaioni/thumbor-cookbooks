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

['redis-server', 'git', 'python-derpconf', 'python-imaging', 'python-magic', 'python-numpy', 'python-opencv', 'python-tornado', 'python-redis', 'python-magic-dbg', 'libopencv-dev', 'libjpeg-dev', 'python-dateutil'].each do |pkg|
    package pkg
end

service 'redis-server' do
 supports :restart => true, :start => true, :stop => true, :reload => true
 action   [:enable, :start] 
end

python_pip "git+git://github.com/globocom/thumbor.git" do
  action :install
  notifies :restart, 'service[thumbor]'
end

group "thumbor" do
  action :create
end

user "thumbor" do
  gid "thumbor"
  action :create 
end

python_pip "git+git://github.com/globocom/remotecv.git" do
  action :install
  notifies :restart, 'service[thumbor]'
end

template "/etc/init/thumbor.conf" do
  source 'thumbor.ubuntu.upstart.erb'
  owner  'root'
  group  'root'
  mode   '0755'
end

template "/etc/init/thumbor-worker.conf" do
  source 'thumbor.worker.erb'
  owner  'root'
  group  'root'
  mode   '0755'
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

template "/etc/init.d/thumbor" do
  source 'thumbor.init.erb'
  owner  'root'
  group  'root'
  mode   '0755'
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
 supports :restart => true, :start => true, :stop => true, :reload => true
 action   [:enable, :start] 
end



