# OP Lab Cloud Tribe

[![Build Status](https://travis-ci.org/mikaturunen/oplab.cloud.svg?branch=master)](https://travis-ci.org/mikaturunen/oplab.cloud)

# Building the Cloud tribe event list

## Development locally

```bash
$ ./script/bootstrap        # install required dependencies
$ bundle exec jekyll serve  # serve the site locally, open http://127.0.0.1:4000/oplab.cloud/
```

## Automated release through Travis

* Create event branch from dev.
  * `dev` -> `event/something`
  * Create your commits into the branch
  * Push them
  * Create Pull Request against `dev``
* Once the PR is approved, contributors can merge `dev` against `master` to have Travis release it

## Manual release

```bash
$ ./script/bootstrap        # install required dependencies
$ ./script/cibuild          # build the project to have static resources available for release
```

Now you can push the `_site` content somewhere and host it as static website.
