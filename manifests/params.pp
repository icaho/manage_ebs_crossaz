# == Class manage_ebs_crossaz::params
#
# This class is meant to be called from manage_ebs_crossaz.
# It sets variables according to platform.
#
class manage_ebs_crossaz::params {
  $region        = 'eu-west-1'
  $instance_id   = 'i-instance'
  $tag_key       = 'role'
  $tag_value     = 'server_role'
  $device        = '/dev/xvdh'
  $mount_point   = '/mnt'
  $handle_format = false
}
