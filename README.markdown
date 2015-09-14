#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with manage_ebs_crossaz](#setup)
    * [What manage_ebs_crossaz affects](#what-manage_ebs_crossaz-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with manage_ebs_crossaz](#beginning-with-manage_ebs_crossaz)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

A simple puppet module to manage EBS volumes in AWS across availability zones.      

## Module Description

This module will manage an EBS volume selected by the tag key&value provided and will make it available to the current EC2 instance 
it is running into regardless of availability zone. In case of missing volume or availability zone of the volume being down it will
fallback to using a snapshot identified the same way as the volume. 

- Support for finding an EBS volume based on tag key & value and getting it attached to the current EC2 instance regardless of AZ.
- Support for fallback to a snapshot with the same tag key & value in case of issues with the volume or volume's AZ is down.

## Setup

### What manage_ebs_crossaz affects

* The module will install ruby, rubygems using yum and aws-sdk using ruby gems.
* A custom ruby script into /usr/bin that will be executable for the root user.

### Setup Requirements

The EC2 instance that will use the module need to have the following actions allowed in its IAM role:
```
"Action": [
    "ec2:AttachVolume",
    "ec2:CreateSnapshot",
    "ec2:CreateVolume",
    "ec2:DescribeSnapshotAttribute",
    "ec2:DescribeSnapshots",
    "ec2:DescribeTags",
    "ec2:DescribeVolumeAttribute",
    "ec2:DescribeVolumeStatus",
    "ec2:DescribeVolumes",
    "ec2:DescribeInstances",
    "ec2:CreateTags",
    "ec2:AttachVolume",
    "ec2:DescribeInstanceStatus",
    "ec2:DeleteSnapshot"
],
```


### Beginning with manage_ebs_crossaz

## Usage

Simple example:
```
class { 'manage_ebs_crossaz':
  region => 'eu-west-1',
  instance_id => $::ec2_instance_id,
  tag_key => 'role',
  tag_value => 'server_role',
  device => '/dev/xvdh',
} 
```
## Reference

## Limitations

Currently only tested in CentOS 7 but possibly works with 6 too.

The module only manages things all the way to the volume attachment on the instance.
Volume filesystem and OS device mount need to be handled by the user.

## Development

To run tests, first bundle install:

```shell
$ bundle install
```

Then, for overall spec tests, including syntax, lint, and rspec, run:

```shell
$ bundle exec rake test
```

To run acceptance tests locally, we use vagrant; first set a few environment variables for the target system:

```shell
$ export BEAKER_set=vagrant-centos6
$ export BEAKER_destroy=no
```
Note: Setting `BEAKER_destroy=no` will allow you to login to the vagrant box that get's provisioned.

Then execute the acceptance tests:

```shell
$ bundle exec rake acceptance
```

In order to access the vagrant box that's been provisioner, there are two options:
Obtain the unique ID of the box using `vagrant global-status`, and then use `vagrant ssh [unique_id]`

Alternately, change to the directory of the Beaker generated Vagrantfile:
```
$ cd .vagrant/beaker_vagrant_files/$BEAKER_SET
```
and run `vagrant ssh` - if there are multiple boxes, you may need to use `vagrant ssh [box_name]`
