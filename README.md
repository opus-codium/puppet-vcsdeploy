# vcsdeploy

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Module Description](#module-description)
* [Rationale](#rationale)
* [Usage](#usage)
  * [With a simple command to run after fetch/update](#with-a-simple-command-to-run-after-fetchupdate)
  * [With additonal resources to realize after fetch/update](#with-additonal-resources-to-realize-after-fetchupdate)

<!-- vim-markdown-toc -->

## Module Description

The vcsdeploy module lets you use Puppet to deploy an application from a _git_ repository.

This vcsdeploy module is a wrapper around [vcsrepo](https://forge.puppet.com/modules/puppetlabs/vcsrepo) which tracks deployment steps and retries them on failure on subsequent agent runs, until it succeeds.

## Rationale

This module allows to escape the usual trap with [vcsrepo](https://forge.puppet.com/modules/puppetlabs/vcsrepo), where you notify resources on repository update, and these resources fail.  On the next puppet run, the repository will be up-to-date and the failed operations are not retried.

Example :
```puppet
vcsrepo { '/path/to/application':
  [...],
}
~> exec { '/path/to/application/scripts/bootstrap':
  refreshonly => true,
}
```
If you use this pattern, the `exec` resource will run on first fetch and on updates… but if `/path/to/application/scripts/bootstrap` fails during its execution, only the first catalog apply will failed.

Using vcsdeploy:
```puppet
vcsdeploy {  '/path/to/application':
  [...],
  after_fetch_command => '/path/to/application/scripts/bootstrap',
}
```
If `/path/to/application/scripts/bootstrap` fails, it will be retried on each `puppet agent` run until successful.

## Usage

### With a simple command to run after fetch/update

```puppet
vcsdeploy { '/path/to/application',
  source              => 'git://example.com/repo.git',
  user                => 'deploy_user',
  after_fetch_command => '/path/to/application/scripts/after-fetch',
}
```

### With additonal resources to realize after fetch/update

```puppet
vcsdeploy { '/path/to/application':
  source                => 'git://example.com/repo.git',
  user                  => 'deploy_user',
  after_fetch_command   => '/path/to/application/scripts/after-fetch',
  after_fetch_resources => [
    File['/path/to/application/tmp'],
    Exec['/path/to/application/scripts/apply-db-migrations'],
  ]
}

file { '/path/to/application/tmp':
  ensure => directory,
  user   => 'application_user',
}

exec { '/path/to/application/scripts/apply-db-migrations',
  user        => 'application_user',
  refreshonly => true,
}
```
