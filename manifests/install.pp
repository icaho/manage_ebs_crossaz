# == Class manage_ebs_crossaz::install
#
# This class is called from manage_ebs_crossaz for install.
#
class manage_ebs_crossaz::install {
  
  package { 'ruby':
    ensure   => installed,
    provider => 'yum',
  }->
  package { 'rubygems':
    ensure   => installed,
    provider => 'yum',
  }->
  package { 'aws-sdk':
    ensure   => installed,
    provider => 'gem',
  }->
  file { '/usr/bin/manage_ebs':
    source => 'puppet:///modules/manage_ebs_crossaz/manage_ebs.rb',
    ensure => 'file',
    owner  => 'root',
    mode   => '0700',
  }
  
}