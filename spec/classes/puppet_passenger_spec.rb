require 'spec_helper'

describe 'puppet::passenger', :type => :class do
      let (:params) do
            {
                :puppet_passenger_port         => '8140',
                :puppet_passenger_ssl_protocol => 'TLSv1.2',
                :puppet_passenger_ssl_cipher   => 'AES256+EECDH:AES256+EDH',
                :puppet_docroot                => '/etc/puppet/rack/public/',
                :apache_serveradmin            => 'root',
                :puppet_conf                   => '/etc/puppet/puppet.conf',
                :puppet_ssldir                 => '/var/lib/puppet/ssl',
                :certname                      => 'test.test.com',
                :conf_dir                      => '/etc/puppet',
                :dns_alt_names                 => 'puppet',
                :passenger_max_pool_size       => '4',
                :passenger_high_performance    => true,
                :passenger_max_requests        => '1000',
                :passenger_stat_throttle_rate  => '30',
                :passenger_root                => nil,
        }
        end
    context 'on Debian' do
        let(:facts) do
            {
                :osfamily               => 'debian',
                :operatingsystem        => 'debian',
                :operatingsystemrelease => '5',
                :concat_basedir         => '/dne',
                :lsbdistcodename        => 'lenny',
            }
        end
         it {
                #should include_class('apache')
                should contain_class('puppet::params')
                should contain_class('apache::mod::passenger')
                should contain_class('apache::mod::ssl')
                should contain_exec('Certificate_Check').with(
                    :command =>
                      "puppet cert clean #{params[:certname]} ; " +
                      "puppet certificate --ca-location=local --dns_alt_names=#{params[:dns_alt_names]} generate #{params[:certname]}" +
                      " && puppet cert sign --allow-dns-alt-names #{params[:certname]}" +
                      " && puppet certificate --ca-location=local find #{params[:certname]}",
                    :unless  => "/bin/ls #{params[:puppet_ssldir]}/certs/#{params[:certname]}.pem",
                    :path    => '/usr/bin:/usr/local/bin',
                    :require  => "File[#{params[:puppet_conf]}]"
                )
                should contain_file(params[:puppet_docroot]).with(
                    :ensure => 'directory',
                    :owner  => 'puppet',
                    :group  => 'puppet',
                    :mode   => '0755'
                )
                should contain_file('puppet_passenger.conf').with(
                    :ensure => 'file',
                )
                should contain_file('puppet_passenger.conf').without_content(/PassengerTempDir/)
                should contain_file('/etc/puppet/rack').with(
                    :ensure => 'directory',
                    :owner  => 'puppet',
                    :group  => 'puppet',
                    :mode   => '0755'
                )
                 should contain_file('/etc/puppet/rack/config.ru').with(
                    :ensure => 'present',
                    :owner  => 'puppet',
                    :group  => 'puppet',
                    :mode   => '0644'
                )
                should contain_ini_setting('puppetmastersslclient').with(
                    :ensure  => 'present',
                    :section => 'master',
                    :setting => 'ssl_client_header',
                    :path    => params[:puppet_conf],
                    :value   =>'SSL_CLIENT_S_DN',
                    :require => "File[#{params[:puppet_conf]}]"
                )
                should contain_ini_setting('puppetmastersslclientverify').with(
                    :ensure  => 'present',
                    :section => 'master',
                    :setting => 'ssl_client_verify_header',
                    :path    => params[:puppet_conf],
                    :value   =>'SSL_CLIENT_VERIFY',
                    :require => "File[#{params[:puppet_conf]}]"
                )
        }
    end
    context 'on Redhat' do
      let(:facts) do
        {
          :osfamily               => 'Redhat',
          :operatingsystem        => 'Redhat',
          :operatingsystemrelease => '5',
          :concat_basedir         => '/dne',
        }
      end
      it {
        should contain_file('/var/lib/puppet/reports')
        should contain_file('/var/lib/puppet/ssl/ca/requests')
      }
    end
    context 'on Redhat with tempdir' do
      let(:facts) do
        {
          :osfamily               => 'Redhat',
          :operatingsystem        => 'Redhat',
          :operatingsystemrelease => '5',
          :concat_basedir         => '/dne',
        }
      end
      let (:params) do
        {
          :puppet_passenger_port         => '8140',
          :puppet_passenger_ssl_protocol => 'TLSv1.2',
          :puppet_passenger_ssl_cipher   => 'AES256+EECDH:AES256+EDH',
          :puppet_docroot                => '/etc/puppet/rack/public/',
          :apache_serveradmin            => 'root',
          :puppet_conf                   => '/etc/puppet/puppet.conf',
          :puppet_ssldir                 => '/var/lib/puppet/ssl',
          :certname                      => 'test.test.com',
          :conf_dir                      => '/etc/puppet',
          :dns_alt_names                 => ['puppet'],
          :puppet_passenger_tempdir      => '/tmp/passenger',
          :passenger_max_pool_size       => '4',
          :passenger_high_performance    => true,
          :passenger_max_requests        => '1000',
          :passenger_stat_throttle_rate  => '30',
          :passenger_root                => nil,
        }
      end
      it {
        should contain_file('puppet_passenger.conf').with_content(/PassengerTempDir/)
      }
    end
end
