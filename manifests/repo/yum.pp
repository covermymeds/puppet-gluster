# @summary enable the upstream Gluster Yum repo
# @api private
#
# @param release
#    GlusterFS release, such as 3.6, 3.7 or 3.8 (specific package defined with 'gluster::version')
# @param repo_key_source
#    where to find this repo's GPG key
# @param priority
#    YUM priority to set for the Gluster repo
#
# @note Currently only released versions are supported. If you want to use
#   QA releases or pre-releases, you'll need to edit line 47
#
# @author Scott Merrill <smerrill@covermymeds.com>
# @note Copyright 2014 CoverMyMeds, unless otherwise noted
#
class gluster::repo::yum (
  String $release = $gluster::params::release,
  String $repo_key_source = $gluster::params::repo_gpg_key_source,
  Optional[String] $priority = $gluster::params::repo_priority,
) inherits gluster::params {
  # CentOS Gluster repo only supports x86_64
  if $facts['os']['architecture'] != 'x86_64' {
    fail("Architecture ${facts['os']['architecture']} not yet supported for ${facts['os']['name']}.")
  }

  if $priority {
    if ! defined( Package['yum-plugin-priorities']) {
      package { 'yum-plugin-priorities':
        ensure => installed,
        before => Yumrepo["glusterfs-${facts['os']['architecture']}"],
      }
    }
  }

  case $facts['os']['name'] {
    'RedHat': {
      if $facts['os']['release']['major'] == '8' {
        exec { 'Enabling Codeready-Builder repo':
          command => 'dnf config-manager --set-enabled codeready-builder-for-rhel-8-x86_64-rpms',
          path    => ['/usr/bin', '/usr/sbin',],
          unless  => 'rpm -qa | grep -c python3-pyxattr',
        }
      }
    }

    'Rocky', 'CentOS', 'AlmaLinux': {
      if $facts['os']['release']['major'] == '8' {
        exec { 'Enabling PowerTools repo':
          command => 'dnf config-manager --set-enabled powertools',
          path    => ['/usr/bin', '/usr/sbin',],
          unless  => 'rpm -qa | grep -c python3-pyxattr',
        }
      }
    }
  }

  case $facts['os']['family'] {
    'RedHat': {
        $sig_mirror = $facts['os']['release']['major'] ? {
        '8' => 'centos.org/centos/8-stream',
        '9' => 'stream.centos.org/SIGs/9-stream',
        default => "centos.org/centos/${facts['os']['release']['major']}"
        }
      }
    default: {
        $sig_mirror = "centos.org/centos/${facts['os']['release']['major']}"
      }
  }

  $_release = if versioncmp($release, '4.1') <= 0 {
    $release
  } else {
    $release.scanf('%d')[0]
  }

  yumrepo { "glusterfs-${facts['os']['architecture']}":
    enabled  => 1,
    baseurl  => "http://mirror.${sig_mirror}/storage/${facts['os']['architecture']}/gluster-${_release}/",
    descr    => "CentOS-${facts['os']['release']['major']} - Gluster ${_release}",
    gpgcheck => 1,
    gpgkey   => $repo_key_source,
    priority => $priority,
  }

  Yumrepo["glusterfs-${facts['os']['architecture']}"] -> Package<| tag == 'gluster-packages' |>
}
