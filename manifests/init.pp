# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include superset
class superset (
  String $install_dir,
  Boolean $manage_python,
  Boolean $manage_webserver,
  Boolean $load_examples,
  String $user,
  Optional[Hash] $admin_config,
  Optional[Hash] $config = undef,
  Optional[Hash] $gunicorn_config,
) {

  group { $user :
    ensure => present
  }

  user { $user:
    ensure     => present,
    gid        => $user,
    managehome => true
  }

  #Install package dependencies 
  include superset::packages

  #Configure Python
  include superset::python

  include superset::config

  include superset::install

  include superset::service

  Class['superset::packages'] -> Class['superset::python'] -> Class['superset::config'] -> Class['superset::install'] -> Class['superset::service']
}
