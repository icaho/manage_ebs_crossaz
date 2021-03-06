#!/usr/bin/env ruby

require 'aws-sdk'

region      = ARGV[0]
instance_id = ARGV[1]
tag_name    = ARGV[2]
tag_val     = ARGV[3]
device      = ARGV[4]


Aws.config.update({
  region: region,
  credentials: Aws::InstanceProfileCredentials.new,
})


client = Aws::EC2::Client.new
resp = client.describe_instance_status({
  instance_ids: [instance_id],
})

az_id = resp.instance_statuses[0].availability_zone


def create_volume(az_id, volume_id, snap_id, tag_name, tag_val)

  if volume_id then

    vol = Aws::EC2::Volume.new(volume_id)

    if vol.availability_zone == az_id then
      return vol.id
    else

      snapshot = vol.create_snapshot({
        description: "ephemeral-snapshot",
      })

      snapshot.wait_until_completed

      client = Aws::EC2::Client.new

      resp = client.create_volume({
        availability_zone: az_id,
        snapshot_id: snapshot.id,
        volume_type: 'gp2',
      })


      new_vol = Aws::EC2::Volume.new(resp.volume_id)

      new_vol.create_tags({
        tags: vol.tags,
      })

      new_vol.wait_until(max_attempts:10, delay:5) {|nvol| nvol.state == 'available' }
      idx = 0
      vol.tags.each_with_index do |tval, tidx|
        if tval['key'] == tag_name then
          idx = tidx
          break
        end
      end

      vol.create_tags({
        tags: [
        {
          key: vol.tags[idx]["key"],
          value: vol.tags[idx]["value"]+"-archived",
        },
        ],
      })
      snapshot.delete

      return new_vol.id

    end

  else

    client = Aws::EC2::Client.new

    unless snap_id.nil? or ! snap_id
      snap = Aws::EC2::Snapshot.new(snap_id)

      resp = client.create_volume({
        availability_zone: az_id,
        snapshot_id: snap.id,
        volume_type: 'gp2',
      })

      tags = snap.tags
    else
      resp = client.create_volume({
        availability_zone: az_id,
        size: 50,
        volume_type: 'gp2',
      })

      tags = [
        {
          key: tag_name,
          value: tag_val,
        },
        {
          key: 'Name',
          value: tag_val,
        }
      ]
    end

    new_vol = Aws::EC2::Volume.new(resp.volume_id)

    new_vol.create_tags({
      tags: tags,
    })

    new_vol.wait_until(max_attempts:10, delay:5) {|nvol| nvol.state == 'available' }

    return new_vol.id

  end

end

def cleanup_volume(az_id, tag_name, tag_val)

  ec2 = Aws::EC2::Resource.new
  volumes = ec2.volumes({
    filters: [
      {
        name: 'tag-key',
        values: [tag_name],
      },
      {
        name: 'tag-value',
        values: [tag_val],
      }
    ],
  })

  # first check we have an attached volume before removing the others
  vol_attached = false
  volumes.each do |vol|
    if ( vol.availability_zone == az_id ) && ( vol.state == 'in-use' )
      vol_attached = true
    end
    break if vol_attached
  end

  fail('ERROR - Volume not attached') unless vol_attached

  volumes.each do |vol|
    if ( vol.availability_zone != az_id ) && ( vol.state == 'available' )
      cleanup_vol = Aws::EC2::Volume.new(vol.id)
      cleanup_vol.delete({
        dry_run: false,
      })
    end
  end

end

def get_vol_for_az(az_id, tag_name, tag_val)

  ec2 = Aws::EC2::Resource.new
  volumes = ec2.volumes({
    filters: [
      {
        name: 'status',
        values: ['available'],
      }
    ],
  })


  vol_id  = nil
  snap_id = nil

  if volumes.count > 0 then
    volumes.each do |vol|
      vol.tags.each do |tags|
        if ( tags['key'] == tag_name ) && ( tags['value'] == tag_val )
          vol_id = vol.id
          break
        end
      end
      break if vol_id != nil
    end

    return create_volume(az_id, vol_id, false, tag_name, tag_val)
  else
    snapshots = ec2.snapshots({
      filters: [
      name: 'tag-key',
      values: tag_name,
      name: 'tag-value',
      values: [tag_val],
      ],
    })

    if snapshots.count > 0 then
      snapshots.each do |snap|
        snap.tags.each do |tags|
          if ( tags['key'] == tag_name ) && ( tags['value'] == tag_val )
            snap_id = snap.id
            break
          end
        end
        break if snap_id != nil
      end
    end

    return create_volume(az_id, false, snap_id, tag_name, tag_val)

  end

end


def attach_volume(inst_id, vol_id, dev='/dev/xvdh')

  vol = Aws::EC2::Volume.new(vol_id)
  vol.attach_to_instance({
    instance_id: inst_id,
    device: dev,
  })

  vol.wait_until(max_attempts:20, delay:5) {|nvol| nvol.state == 'in-use' }

  while !system("file -s #{dev} | grep data > /dev/null")
   sleep 2
  end

end


volume_id = get_vol_for_az(az_id, tag_name, tag_val)

attach_volume(instance_id, volume_id, device)

cleanup_volume(az_id, tag_name, tag_val)
