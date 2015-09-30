# == Class: manage_ebs_crossaz
#
# Full description of class manage_ebs_crossaz here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.

class manage_ebs_crossaz (

  $region        = $::manage_ebs_crossaz::params::region,
  $instance_id   = $::manage_ebs_crossaz::params::instance_id,
  $tag_key       = $::manage_ebs_crossaz::params::tag_key,
  $tag_value     = $::manage_ebs_crossaz::params::tag_value,
  $device        = $::manage_ebs_crossaz::params::device,
  $mount_point   = $::manage_ebs_crossaz::params::mount_point,
  $handle_format = $::manage_ebs_crossaz::params::handle_format,

) inherits ::manage_ebs_crossaz::params {


  # validate parameters here

  validate_string($region)
  validate_string($instance_id)
  validate_string($tag_key)
  validate_string($tag_value)
  validate_string($device)
  validate_string($mount_point)

  validate_bool($handle_format)

  class { '::manage_ebs_crossaz::install': } ->
  class { '::manage_ebs_crossaz::config': } ->
  Class['::manage_ebs_crossaz']

  if $handle_format {

    exec { 'format_device':
      command  => "mkfs.xfs ${device}",
      provider => 'shell',
      path     => '/bin:/sbin:/usr/bin:/usr/sbin',
      unless   => "file -s ${device} | grep filesystem",
      before   => Exec['mount_device'],
      require  => Exec['create_mountpoint'],
    }
  
  }

  exec { 'manage_ebs':
    command => "/usr/bin/manage_ebs ${region} ${instance_id} ${tag_key} ${tag_value} ${device}",
    creates => $device,
  }->
  exec { 'wait_until_ready':
    command  => "sleep 120",
    provider => 'shell',
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless   => "file -s ${device} | grep data",
  }->
  exec { 'create_mountpoint':
    command  => "mkdir -p ${mount_point}",
    provider => 'shell',
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates  => "${mount_point}",
  }->
  exec { 'mount_device':
    command  => "mount ${device} ${mount_point}",
    provider => 'shell',
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless   => "mountpoint -q ${mount_point}",
  }



}
