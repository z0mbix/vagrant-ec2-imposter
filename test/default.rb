describe file('/etc/default/aws') do
  its('mode') { should cmp '0644' }
  its('owner') { should cmp 'root' }
  its('group') { should cmp 'root' }
end

describe parse_config_file('/etc/default/aws') do
  its('content') { should match /AWS_DEFAULT_REGION=.+/ }
  its('content') { should match /AWS_ACCESS_KEY_ID=.+/ }
  its('content') { should match /AWS_SECRET_ACCESS_KEY=.+/ }
end

describe file('/etc/systemd/system/metadata.service') do
  its('mode') { should cmp '0644' }
  its('owner') { should cmp 'root' }
  its('group') { should cmp 'root' }
end

describe systemd_service('metadata') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe port(5000) do
  it { should be_listening }
  its('addresses') { should include '127.0.0.1' }
  its('protocols') { should eq ['tcp'] }
  its('processes') { should include 'python' }
end

describe file('/etc/user-data') do
  its('mode') { should cmp '0755' }
end

describe command('hostname') do
  its('stdout') { should eq "ip-10-0-2-15.eu-west-1.compute.internal\n" }
end

describe host('ip-10-0-2-15.eu-west-1.compute.internal') do
  it { should be_resolvable }
end

describe command('curl http://169.254.169.254/latest/meta-data/local-hostname') do
  its('stdout') { should eq 'ip-10-0-2-15.eu-west-1.compute.internal' }
end

describe command('curl http://169.254.169.254/latest/meta-data/local-ipv4') do
  its('stdout') { should eq '10.0.2.15' }
end
