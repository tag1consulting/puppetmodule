#"
# This module is used to setup the puppetlabs repos
# that can be used to install puppet.
#
class puppet::repo::puppetlabs() {

  if($::osfamily == 'Debian') {
    Apt::Source {
      location    => 'http://apt.puppetlabs.com',
      key         => {
        'id'     => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
        'server' => 'pgp.mit.edu',
      },
    }
    apt::source { 'puppetlabs':      repos => 'main' }
    apt::source { 'puppetlabs-deps': repos => 'dependencies' }
  } elsif $::osfamily == 'Redhat' {
    if $::operatingsystem == 'Fedora' {
      $ostype='fedora'
      $prefix='f'
    } else {
        $ostype='el'
        $prefix=''
    }
    yumrepo { 'puppetlabs-deps':
      baseurl  => "http://yum.puppetlabs.com/${ostype}/${prefix}\$releasever/dependencies/\$basearch",
      descr    => 'Puppet Labs Dependencies $releasever - $basearch ',
      enabled  => '1',
      gpgcheck => '1',
      gpgkey   => 'https://yum.puppetlabs.com/RPM-GPG-KEY-puppet',
    }

    yumrepo { 'puppetlabs':
      baseurl  => "http://yum.puppetlabs.com/${ostype}/${prefix}\$releasever/products/\$basearch",
      descr    => 'Puppet Labs Products $releasever - $basearch',
      enabled  => '1',
      gpgcheck => '1',
      gpgkey   => 'https://yum.puppetlabs.com/RPM-GPG-KEY-puppet',
    }
  } else {
    fail("Unsupported osfamily ${::osfamily}")
  }
}
