#
# Cookbook Name:: zanui-thumbor
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
bash "install_thumbor" do
  user "root"
  cwd "/tmp"
  code <<-EOH

    #specify resource and states and chef takes care of transiction from one state to another

  curl http://python-distribute.org/distribute_setup.py | sudo python
  #do it with chef apt cookbook https://github.com/zanui/shop-box2/blob/master/zanui-cookbooks/zanui-web/recipes/php.rb
  sudo echo "deb http://ppa.launchpad.net/thumbor/ppa/ubuntu precise main" | sudo tee -a /etc/apt/sources.list > /dev/null
  sudo echo "deb-src http://ppa.launchpad.net/thumbor/ppa/ubuntu precise main" | sudo tee -a /etc/apt/sources.list > /dev/null
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C6C3D73D1225313B
  sudo aptitude update -yq
  ####
   ##
# Install other php packages
#['php5-dev', 'php-pear', 'php5-memcache'].each do |pkg|
 #   package pkg
#end
  sudo aptitude install -yq thumbor

  sudo aptitude install -yq redis-server
  sudo update-rc.d redis-server enable > /dev/null

  THUMBOR_PORT=`cat host/etc/thumbor.port` //nginx
  THUMBOR_INSTANCES=#{node['thumbor']['processes']}

    #move it into template
  BASE_PORT=#{node['thumbor']['base_port']}
  PORTS=''
  SERVERS=''
  for ((i=1 ; i<=$THUMBOR_INSTANCES ; i++))
  do
      PORTS="${PORTS}$(($BASE_PORT-1 + $i)),"
      SERVERS="${SERVERS}    server 127.0.0.1:$(($BASE_PORT-1 + $i));\n"
  done
  sudo cp host/etc/thumbor.nginx /etc/nginx/conf.d/thumbor.conf
  sudo perl -pi -e "s/SERVER_STUB/$SERVERS/;s/PORT/$THUMBOR_PORT/" /etc/nginx/conf.d/thumbor.conf

#look at the template here https://github.com/zanui/shop-box2/blob/master/zanui-cookbooks/zanui-web/recipes/nginx.rb
  sudo mv /etc/default/thumbor /etc/default/thumbor.orig
#how to restart: define service and call it example https://github.com/zanui/shop-cookbooks/blob/master/nginx/recipes/default.rb
  sudo cp host/etc/thumbor.default /etc/default/thumbor


  echo "port="$PORTS | sudo tee -a /etc/default/thumbor > /dev/null

  sudo mv /etc/thumbor.conf /etc/thumbor.conf.orig

  sudo cp host/etc/thumbor.conf.default /etc/thumbor.conf

  cat host/etc/thumbor.conf.custom | sudo tee -a /etc/thumbor.conf > /dev/null
#template with no source only content
  sudo mv /etc/thumbor.key /etc/thumbor.key.orig

  if [ -s host/etc/thumbor.key ]
  then
      sudo cp host/etc/thumbor.key /etc/thumbor.key
  else
      < /dev/urandom tr -dc a-z0-9 | head -c16 | sudo tee /etc/thumbor.key > /dev/null
  fi


  EOH
end
