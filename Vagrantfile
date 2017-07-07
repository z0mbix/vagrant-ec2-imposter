# -*- mode: ruby -*-
# vi: set ft=ruby :

aws = {
  region: ENV['AWS_DEFAULT_REGION'],
  access_key: ENV['AWS_ACCESS_KEY_ID'],
  secret_key: ENV['AWS_SECRET_ACCESS_KEY']
}
hostname = 'ip-10-0-2-15.' + aws[:region] + '.compute.internal'
userdata_file = 'user-data.centos'
# userdata_file = 'user-data.ubuntu'
box = 'centos/7'
# box = 'ubuntu/xenial64'

aws.each do |k, v|
  if v.nil?
    puts "You need to set the aws #{k}"
    exit(1)
  end
end

Vagrant.configure('2') do |config|
  config.vm.box = box
  config.vm.hostname = hostname

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = '1024'
  end

  # Support using a proxy
  if Vagrant.has_plugin?('vagrant-proxyconf')
    proxy = ENV['http_proxy']
    no_proxy = ENV['no_proxy']
    unless proxy.nil?
      puts 'Using Proxy: %s' % proxy
      config.proxy.http     = '%s' % proxy
      config.proxy.https    = '%s' % proxy
      config.proxy.no_proxy = '%s,10.0.2.15,169.254.169.254' % no_proxy
    end
  end

  config.vm.provision :file, source: 'setup/metadata-service', destination: '/tmp/metadata-service'

  # Populate AWS credentials
  $setup_metadata = <<SCRIPT
echo "AWS_DEFAULT_REGION=#{aws[:region]}" > /etc/default/aws
echo "AWS_ACCESS_KEY_ID=#{aws[:access_key]}" >> /etc/default/aws
echo "AWS_SECRET_ACCESS_KEY=#{aws[:secret_key]}" >> /etc/default/aws

if [[ -f /etc/redhat-release ]]; then
  rpm -q python-flask >/dev/null ||
    yum install -y -q python-flask
  rpm -q net-tools >/dev/null ||
    yum install -y -q net-tools
elif [[ -f /etc/debian_version ]]; then
  dpkg-query -W python-flask >/dev/null ||
    apt-get install -y -q python-flask
else
  echo 'Sorry, I really am baffled by your choice of OS!'
  exit 1
fi

mv /tmp/metadata-service /usr/local/bin/metadata-service
chmod 755 /usr/local/bin/metadata-service

ip ad show lo | grep 'inet 169.254.169.254' >/dev/null ||
  /sbin/ip addr add 169.254.169.254/32 dev lo scope host

iptables -t nat -S OUTPUT | grep -e '\-A OUTPUT -d 169.254.169.254/32 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 5000' >/dev/null ||
  iptables -t nat -A OUTPUT -p tcp -d 169.254.169.254/32 --dport 80 -j REDIRECT --to-ports 5000

if [[ ! -f /etc/systemd/system/metadata.service ]]; then
  cat > /etc/systemd/system/metadata.service <<SERVICE
[Unit]
Description=Fake metadata service
After=network.target

[Service]
EnvironmentFile=/etc/default/aws
ExecStart=/usr/local/bin/metadata-service
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable metadata
  systemctl start metadata
fi
SCRIPT

  config.vm.provision 'shell', inline: $setup_metadata

  # Upload and run userdata
  if File.exist?(userdata_file)
    config.vm.provision :file, source: userdata_file, destination: '/tmp/user-data'
    config.vm.provision :shell, inline: 'mv /tmp/user-data /etc/user-data && chmod 755 /etc/user-data'
    config.vm.provision :shell, inline: '/etc/user-data', name: 'user-data'
  end
end
