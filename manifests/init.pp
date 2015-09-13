# == Class: manage_ebs_crossaz
#
# Full description of class manage_ebs_crossaz here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.

class manage_ebs_crossaz (

  $region      = $::manage_ebs_crossaz::params::region,
  $instance_id = $::manage_ebs_crossaz::params::instance_id,
  $tag_key     = $::manage_ebs_crossaz::params::tag_key,
  $tag_value   = $::manage_ebs_crossaz::params::tag_value,
  $device      = $::manage_ebs_crossaz::params::device,

) inherits ::manage_ebs_crossaz::params {


  # validate parameters here

  validate_string($region)
  validate_string($instance_id)
  validate_string($tag_key)
  validate_string($tag_value)
  validate_string($device)

  class { '::manage_ebs_crossaz::install': } ->
  class { '::manage_ebs_crossaz::config': } ->
  Class['::manage_ebs_crossaz']

  exec { 'manage_ebs':
    command => "/usr/bin/manage_ebs ${region} ${instance_id} ${tag_key} ${tag_value} ${device}",
    creates => $device,
  }


}
