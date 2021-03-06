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

apt_repository "multiverse" do
  uri           "http://us.archive.ubuntu.com/ubuntu/"
  distribution  node['lsb']['codename']
  components    ["main", "multiverse"]
  deb_src       true
  action        :add
  notifies :run, "execute[apt-get update]", :immediately
end

required_packages = %w{
libevent-dev
libxml2-dev
libcurl4-gnutls-dev
python-pycurl-dbg
librtmp-dev
libatlas-base-dev
gfortran
liblapack-dev
libblas-dev
build-essential
checkinstall
git
pkg-config
cmake
libpng12-0
libpng12-dev
libpng++-dev
libpng3
libpnglite-dev
libfaac-dev
libjack-jackd2-dev
libjasper-dev
libjasper-runtime
libjasper1
libmp3lame-dev
libopencore-amrnb-dev
libopencore-amrwb-dev
libsdl1.2-dev
libtheora-dev
libva-dev
libvdpau-dev
libvorbis-dev
libx11-dev
libxfixes-dev
libxvidcore-dev
texi2html
yasm
zlib1g-dev
zlib1g-dbg
zlib1g
libgstreamer0.10-0
libgstreamer0.10-dev
libgstreamer0.10-0-dbg
gstreamer0.10-tools
gstreamer0.10-plugins-base
libgstreamer-plugins-base0.10-dev
gstreamer0.10-plugins-good
gstreamer0.10-plugins-ugly
gstreamer0.10-plugins-bad
gstreamer0.10-ffmpeg
pngtools
libtiff4-dev
libtiff4
libtiffxx0c2
libtiff-tools
libjpeg8
libjpeg8-dev
libjpeg8-dbg
libjpeg-progs
libavcodec-dev
libavcodec53
libavformat53
libavformat-dev
libxine1-ffmpeg
libxine-dev
libxine1-bin
libunicap2
libunicap2-dev
libdc1394-22-dev
libdc1394-22
libdc1394-utils
swig
libpython2.7
python-dev
python2.7-dev
libjpeg-progs
libjpeg-dev
libgtk2.0-0
libgtk2.0-dev
gtk2-engines-pixbuf
python-numpy
python-opencv
redis-server
libgraphicsmagick++1-dev
libgraphicsmagick++3
libboost-python-dev
tree
webp
libwebp-dev
python-dateutil
}

required_packages.each do |pkg|
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

python_pip "git+git://github.com/zanui/thumbor_aws.git@webp" do
  action :install
  notifies :restart, 'service[thumbor]'
end

service 'thumbor' do
 supports :restart => true, :start => true, :stop => true, :reload => true
 action   [:enable, :start] 
end



