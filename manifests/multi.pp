define manage_ebs_crossaz::multi (

  $region        = 'eu-west-1',
  $instance_id   = undef,
  $tag_key       = undef,
  $tag_value     = undef,
  $device        = undef,
  $mount_point   = undef,
  $handle_format = true,

) {

  # validate parameters here

  validate_string($region)
  validate_string($instance_id)
  validate_string($tag_key)
  validate_string($tag_value)
  validate_string($device)
  validate_string($mount_point)

  validate_bool($handle_format)

  include ::manage_ebs_crossaz::install

  if $handle_format {

    exec { "format_ebs_device_${name}":
      command  => "mkfs.xfs ${device}",
      provider => 'shell',
      path     => '/bin:/sbin:/usr/bin:/usr/sbin',
      unless   => "file -s ${device} | grep filesystem",
      before   => Exec["mount_ebs_device_${name}"],
      require  => Exec["create_ebs_mountpoint_${name}"],
    }

  }

  exec { "manage_ebs_${name}":
    command => "/usr/bin/manage_ebs ${region} ${instance_id} ${tag_key} ${tag_value} ${device}",
    creates => $device,
    timeout => 1200,
  }->
  exec { "wait_until_ebs_ready_${name}":
    command  => "sleep 120",
    provider => 'shell',
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless   => "file -s ${device} | grep data",
  }->
  exec { "create_ebs_mountpoint_${name}":
    command  => "mkdir -p ${mount_point}",
    provider => 'shell',
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates  => "${mount_point}",
  }->
  exec { "mount_ebs_device_${name}":
    command  => "mount ${device} ${mount_point}",
    provider => 'shell',
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless   => "mountpoint -q ${mount_point}",
  }

}
