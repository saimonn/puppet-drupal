class drupal(
  $vhost,
  $drupal_dir     = "${::apache_c2c::root}/${vhost}/private/drupal",
  $owner          = 'www-data',
  $group          = 'www-data',
  $mysql_database = 'drupal',
) {
  #  $drupal_dir = "${::apache_c2c::root}/${::georchestra::project_name}/private/drupal"

  file { $drupal_dir:
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'sigdev',
    mode   => '2775',
  }

  exec { "chown -R ${owner}:${group} ${drupal_dir}": }
  exec { "chmod -R u=rwX,g=rwX,o=rX ${drupal_dir}": }

  apache_c2c::directive { 'alias-portail':
    ensure    => present,
    directive => "Alias /portail $drupal_dir",
    vhost     => $::georchestra::project_name,
  }

  apache_c2c::directive{ 'rewrite-slash':
    ensure    => present,
    vhost     => $vhost,
    directive => 'RewriteRule ^/$ /portail/ [R]',
  }

  include mysql::server
  $sudo_mysql_admin_cmnd = '/etc/init.d/mysql, /bin/su mysql, /bin/su - mysql, /bin/su mysql -s /bin/bash, /bin/su - mysql -s /bin/bash'
  class { '::mysql::administration':
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

  include mysql::backup

  mysql::config{'mysqld/max_allowed_packet':
    ensure => present,
    value  => '16M',
  }

}