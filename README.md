This is a copy of: https://github.com/gitleaks/gitleaks-action/tree/v1.6.0
and will probably have limited support.


Gitleaks Action provides a simple way to run gitleaks in your CI/CD pipeline.


### Sample Workflow
```
name: gitleaks

on: [push,pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
    - name: gitleaks-action
      uses: giantswarm/gitleaks-action@main
```

### Using your own .gitleaks.toml configuration
```
name: gitleaks

on: [push,pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
    - name: gitleaks-action
      uses: giantswarm/gitleaks-action@main
      with:
        config-path: security/.gitleaks.toml
```
    > The `config-path` is relative to your GitHub Worskpace

### NOTE!!!
You must use `actions/checkout` before the gitleaks-action step. If you are using `actions/checkout@v2` you must specify a commit depth other than the default which is 1. 

ex: 
```
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: '0'
    - name: gitleaks-action
      uses: giantswarm/gitleaks-action@main
```

using a fetch-depth of '0' clones the entire history. If you want to do a more efficient clone, use '2', but that is not guaranteed to work with pull requests.   