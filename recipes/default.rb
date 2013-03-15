#
# Cookbook Name:: apache-multisite
# Recipe:: default
#
# Copyright 2013, Hello Future Ltd
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apache2"
include_recipe "mysql::server"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "apache2::mod_php5"

package "libssh2-php" do
  action :install
end

# Our 
sites = data_bag('apache-sites')
 
sites.each do |site|
  opts = data_bag_item('apache-sites', site)
 
  if opts.has_key?('path')
    # Maybe we want to be live at beta.blah.com rather than www.blah.com
    # to start with but keep the directory sensible for the future.
    path = node['apache-multisite']['dir'] + '/' + opts['path']
  else
    path = node['apache-multisite']['dir'] + '/' + opts['host']
  end
 
  if opts.has_key?('aliases')
    aliases = opts['aliases'] 
  else
    aliases = []
  end

  if opts.has_key?('redirects')
    redirects = opts['redirects'] 
  else
    redirects = {}
  end

  if opts.has_key?('manage_user') and opts['manage_user'] == true
    user opts['user'] do
      comment opts['user_fullname']
      uid opts['uid'] 
      gid opts['group']
      home path
      shell "/usr/lib/sftp-server"
      password opts['passwd']
     end
  end

  if opts.has_key?('db')
    mysql_database opts['db'] do
      connection ({:host => 'localhost', :username => 'root', :password => node['mysql']['server_root_password']})
      action :create
    end

    mysql_database_user opts['db_user'] do
      connection ({:host => 'localhost', :username => 'root', :password => node['mysql']['server_root_password']})
      password opts['db_passwd']
      database_name opts['db']
      privileges [:select,:update,:insert,:create,:delete]
     action :grant
    end
  end

  directory path do
    owner opts['user']
    group opts['group']
    mode "0775"
    action :create
  end

  directory path + '/www' do
    owner opts['user']
    group opts['group']
    mode "0775"
    action :create
  end

  web_app site do
    template "site.conf.erb"
    docroot path
    server_name opts['host']
    server_aliases aliases
    url_redirects redirects
  end

end

