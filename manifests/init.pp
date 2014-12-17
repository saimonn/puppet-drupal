# try to install and configure drupal
class drupal(
  $vhost,
  $drupal_dir     = "${::apache_c2c::root}/${vhost}/private/drupal",
  $owner          = 'www-data',
  $group          = 'www-data',
  $mysql_database = 'drupal',
) {

  file { $drupal_dir:
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'sigdev',
    mode   => '2775',
  }

  cron { 'drupal fix permissions maintenance':
    ensure  => present,
    command => "ionice -c3 chown -R ${owner}:${group} ${drupal_dir} ; ionice -c3 chmod -R u=rwX,g=rwX,o=rX ${drupal_dir}",
    user    => 'root',
    hour    => fqdn_rand(4)+2,
    minute  => fqdn_rand(60),
  }

  if defined(Class['apache::service']) {
    # When using puppetlabs-apache
    include ::apache::mod::php

    file { "/var/www/${vhost}/conf/drupal.conf":
      ensure  => file,
      content => "Alias /portail ${drupal_dir}
RewriteRule ^/$ /portail/ [R]
<Directory \"${drupal_dir}\">
  AllowOverride All
</Directory>",
    }
  } else {
    apache_c2c::directive { 'alias-portail':
      ensure    => present,
      directive => "Alias /portail ${drupal_dir}",
      vhost     => $::georchestra::project_name,
    }

    apache_c2c::directive{ 'rewrite-slash':
      ensure    => present,
      vhost     => $vhost,
      directive => 'RewriteRule ^/$ /portail/ [R]',
    }
    apache_c2c::module { 'php5':
      ensure => present,
    }
  }

  include mysql::server
  $sudo_mysql_admin_cmnd = '/etc/init.d/mysql, /bin/su mysql, /bin/su - mysql, /bin/su mysql -s /bin/bash, /bin/su - mysql -s /bin/bash'
  class { '::administration::mysql':
    sudo_user => '%sigdev',
  }

  package{[
    'php5-mysql',
    'php5-curl',
    'php5-gd',
    'php5-imagick',
    'php5-ldap',
    'php5-mcrypt']:
    ensure => present
  }

  mysql::database{ $mysql_database:
    ensure => present,
  }

  mysql::rights{'Set rights for drupal_georchestra database':
    ensure   => present,
    database => 'drupal_georchestra',
    user     => 'cms',
    password => 'cms',
  }

  include backup::mysql

  mysql::config{'mysqld/max_allowed_packet':
    ensure => present,
    value  => '16M',
  }

}
