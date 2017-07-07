# EC2 Wannabe

## Descrtiption

This vagrant VM is an attempt to emulate some aspects of an EC2 instance, including user-data and some parts of the metadata service.

## Setup

Choose your Linux distro in `Vagrantfile` by setting these two variables:

```
userdata_file = 'user-data.centos'
box = 'centos/7'
```

or

```
userdata_file = 'user-data.ubuntu'
box = 'ubuntu/xenial64'
```

I've only tested with these two, but it may work on other systemd based distributions if you set these variables appropriately. If it doesn't, please send me a pull request.

## Usage

Start the VM:

```
vagrant up
```

This should provision the VM using the user data script you specified above.

Login:

```
vagrant ssh
```

## AWS Credentials

If you set the following environment variables correctly on your host, your VM should be able to use these by way of the `iam/security-credentials/{role}` metadata endpoint:

```
export AWS_DEFAULT_REGION=
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

These get copied in to the VM so the metadata service can use them. Once the service is running you can use `awscli` and the AWS SDK as if on a real instance.

I use [direnv](https://direnv.net/) to handle this, but as long as the environment variables exist, you should be OK.

## Metadata Service

You can use some of the basic metadata endpoints, e.g.:

```
$ curl http://169.254.169.254/latest/meta-data/local-hostname
ip-10-0-2-15.eu-west-1.compute.internal
```

```
$ curl http://169.254.169.254/latest/meta-data/local-ipv4
10.0.2.15
```

```
$ curl http://169.254.169.254/latest/user-data
#!/usr/bin/env bash

yum install -y epel-release
yum install -y python-pip

pip install --upgrade pip
pip install awscli
pip install boto
pip install boto3
```

```
$ curl http://169.254.169.254/latest/meta-data/iam/security-credentials/iam_role
{
  "AccessKeyId": "AAAAAAAAAAAAAAAAAAAA",
  "Code": "Success",
  "Expiration": "2017-07-08T15:31:58Z",
  "LastUpdated": "2017-07-07T15:31:58Z",
  "SecretAccessKey": "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
  "Token": "",
  "Type": "AWS-HMAC"
}
```

## Tests

If you want to add a new distro, you can use the inspec tests to validate everything works.

Run the inspec tests from your host:

```
$ inspec exec --sudo -t ssh://vagrant@127.0.0.1:$(vagrant ssh-config | grep Port |awk '{print $2}') test/default.rb -i .vagrant/machines/default/virtualbox/private_key

Profile: tests from test/default.rb
Version: (not specified)
Target:  ssh://vagrant@127.0.0.1:2200


  File /etc/default/aws
     ✔  mode should cmp == "0644"
     ✔  owner should cmp == "root"
     ✔  group should cmp == "root"
  Parse Config
     ✔  File /etc/default/aws content should match /AWS_DEFAULT_REGION=.+/
     ✔  File /etc/default/aws content should match /AWS_ACCESS_KEY_ID=.+/
     ✔  File /etc/default/aws content should match /AWS_SECRET_ACCESS_KEY=.+/
  File /etc/systemd/system/metadata.service
     ✔  mode should cmp == "0644"
     ✔  owner should cmp == "root"
     ✔  group should cmp == "root"
  Service metadata
     ✔  should be installed
     ✔  should be enabled
     ✔  should be running
  Port 5000
     ✔  should be listening
     ✔  addresses should include "127.0.0.1"
     ✔  protocols should eq ["tcp"]
     ✔  processes should include "python"
  File /etc/user-data
     ✔  mode should cmp == "0755"
  Command hostname
     ✔  stdout should eq "ip-10-0-2-15.eu-west-1.compute.internal\n"
  Host ip-10-0-2-15.eu-west-1.compute.internal
     ✔  should be resolvable
  Command curl
     ✔  http://169.254.169.254/latest/meta-data/local-hostname stdout should eq "ip-10-0-2-15.eu-west-1.compute.internal"
  Command curl
     ✔  http://169.254.169.254/latest/meta-data/local-ipv4 stdout should eq "10.0.2.15"

Test Summary: 21 successful, 0 failures, 0 skipped```