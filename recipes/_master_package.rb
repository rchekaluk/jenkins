#
# Cookbook Name:: jenkins
# Recipe:: _master_package
#
# Author: Guilhem Lettron <guilhem.lettron@youscribe.com>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2013, Youscribe
# Copyright 2014, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform_family']
when 'debian'
  include_recipe 'apt::default'

  apt_repository 'jenkins' do
    uri          node['jenkins']['master']['repository']
    distribution 'binary/'
    key          node['jenkins']['master']['repository_key']
  end

  package 'jenkins' do
    version node['jenkins']['master']['version']
  end

  bash "Modify packaged log rotation directory" do
    code <<-EOH
      sed -i "s|/var/log/jenkins|#{node['jenkins']['master']['log_directory']}|g" /etc/logrotate.d/jenkins
    EOH
    not_if "grep #{node['jenkins']['master']['log_directory']} /etc/logrotate.d/jenkins"
  end

  bash "Modify packaged log rotation file name" do
    code <<-EOH
      sed -i "s|{|#{node['jenkins']['master']['log_directory']}/#{node['jenkins']['master']['access_log']} {|" /etc/logrotate.d/jenkins
    EOH
    not_if "grep #{node['jenkins']['master']['access_log']} /etc/logrotate.d/jenkins"
  end

  template '/etc/default/jenkins' do
    source   'jenkins-config-debian.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end
when 'rhel'
  include_recipe 'yum::default'

  yum_repository 'jenkins-ci' do
    baseurl node['jenkins']['master']['repository']
    gpgkey  node['jenkins']['master']['repository_key']
  end

  package 'jenkins' do
    version node['jenkins']['master']['version']
  end

  bash "Modify packaged log rotation directory" do
    code <<-EOH
      sed -i "s|/var/log/jenkins|#{node['jenkins']['master']['log_directory']}|g" /etc/logrotate.d/jenkins
    EOH
    not_if "grep #{node['jenkins']['master']['log_directory']} /etc/logrotate.d/jenkins"
  end

  bash "Modify packaged log rotation file name" do
    code <<-EOH
      sed -i "s|access_log|#{node['jenkins']['master']['access_log']}|g"          /etc/logrotate.d/jenkins
    EOH
    not_if "grep #{node['jenkins']['master']['access_log']} /etc/logrotate.d/jenkins"
  end

  bash "Modify packaged access log 1" do
    code <<-EOH
      sed -i "/accessLogger/ s|/var/log/jenkins|#{node['jenkins']['master']['log_directory']}|g" /etc/init.d/jenkins
    EOH
    not_if "grep #{node['jenkins']['master']['log_directory']} /etc/init.d/jenkins"
  end

  bash "Modify packaged access log 2" do
    code <<-EOH
      sed -i "/accessLogger/ s|access_log|#{node['jenkins']['master']['access_log']}|g"          /etc/init.d/jenkins
    EOH
    not_if "grep #{node['jenkins']['master']['access_log']} /etc/init.d/jenkins"
  end

  template '/etc/sysconfig/jenkins' do
    source   'jenkins-config-rhel.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end
end

service 'jenkins' do
  supports status: true, restart: true, reload: true
  action  [:enable, :start]
end
