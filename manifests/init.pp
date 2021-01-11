# @summary Deploy an application using VCS
#
# This defined type will deploy an application that comes from a repository.
#
# At first fetch and on updates, this will run a custom command.
#
# @param source The source URI for the repository
# @param after_fetch_command The command to execute after VCS fetch
# @param ensure Ensure the version control repository
# @param target The target path to fetch repository
# @param revision The revision of the repository
# @param user The user/uid that owns the repository files and run after fetch command
# @param group The group/gid that owns the repository files and run after fetch command
# @param vcsrepo_attributes The additionnal attributes passed to `vcsrepo` resource
# @param after_fetch_command_attributes The additionnal attributes passed to `exec` resource
# @param after_fetch_resources The resources that need to be realized after a fetch
#
# @example
#   vcsdeploy { '/path/to/application':
#     ensure              => latest,
#     source              => 'https://gitlab.com/corporation/application',
#     after_fetch_command => '/path/to/application/bin/deploy',
#   }
define vcsdeploy (
  String[1] $source,
  Stdlib::Absolutepath $after_fetch_command,
  Enum[latest, present, absent] $ensure = latest,
  Stdlib::Absolutepath $target = $name,
  String[1] $revision = 'master',
  Optional[String[1]] $user = undef,
  Optional[String[1]] $group = $user,
  Hash $vcsrepo_attributes = {},
  Hash $after_fetch_command_attributes = {},
  Array[Type[Resource]] $after_fetch_resources = [],
) {
  $empty_target_file = "${target}/.vcsdeploy-up-to-date"

  file { $target:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }
  -> vcsrepo { $target:
    ensure   => $ensure,
    source   => $source,
    revision => $revision,
    provider => git,
    user     => $user,
    group    => $group,
    *        => $vcsrepo_attributes,
  }
  ~> exec { "${name}: Flag deployment as obsolete":
    command     => "/bin/rm ${empty_target_file}",
    cwd         => $target,
    user        => $user,
    group       => $group,
    logoutput   => 'on_failure',
    onlyif      => "/usr/bin/test -f ${empty_target_file}",
    refreshonly => true,
  }

  $default_after_fetch_command_attributes = {
    'cwd'       => $target,
    'user'      => $user,
    'group'     => $group,
    'logoutput' => 'on_failure',
  }

  $real_after_fetch_command_attributes = $default_after_fetch_command_attributes + $after_fetch_command_attributes

  exec { $after_fetch_command:
    unless => "/usr/bin/test -f ${empty_target_file}",
    *      => $real_after_fetch_command_attributes,
  }
  ~> exec { "${name}: Flag deployment as up-to-date":
    command     => "/usr/bin/touch ${empty_target_file}",
    cwd         => $target,
    user        => $user,
    group       => $group,
    refreshonly => true,
  }

  $after_fetch_resources.each |$resource| {
    Exec["${name}: Flag deployment as obsolete"] -> $resource
    $resource -> Exec[$after_fetch_command]
    $resource -> Exec["${name}: Flag deployment as up-to-date"]
  }
}
