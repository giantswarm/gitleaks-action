Gitleaks Action runs [gitleaks](https://github.com/gitleaks/gitleaks) v8.30.1 in your CI/CD pipeline.
It started as a copy of https://github.com/gitleaks/gitleaks-action/tree/v1.6.0 and has limited support.

On a pull request it scans the commits between the base branch and the pull request's head; on a push it scans the whole history.
Giant Swarm repositories run it through the shared `giantswarm/github-workflows` gitleaks workflow.

### Sample Workflow
```
name: gitleaks

on: [pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: '0'
    - name: gitleaks-action
      uses: giantswarm/gitleaks-action@v0.1.0
```

You must use `actions/checkout` before the gitleaks-action step, with a `fetch-depth` of `0`: a pull request's scan needs the base branch's history.

### Allow-listing a false positive

Every finding in the log carries a `Fingerprint:` line, `<commit>:<file>:<rule>:<line>`.
Add that line to a `.gitleaksignore` file in the repository root, commit it to the same pull request, and the finding no longer fails the workflow; no new pull request and no force push is needed:

```
# .gitleaksignore
4b8c0f3e1a2d...:testdata/fixture.yaml:generic-api-key:12
```

For a whole class of false positives (test fixtures, generated files), extend the config instead, as below.

### Using your own gitleaks configuration
The action reads `.github/.gitleaks.toml`, or else `.gitleaks.toml` in the repository root, when one exists. Another path is set with `config-path`:
```
    - name: gitleaks-action
      uses: giantswarm/gitleaks-action@v0.1.0
      with:
        config-path: security/.gitleaks.toml
```
    > The `config-path` is relative to your GitHub workspace

The config is in the [gitleaks v8 format](https://github.com/gitleaks/gitleaks#configuration). To keep the default rules and add an allow-list:
```
[extend]
useDefault = true

[[allowlists]]
description = "Test fixtures contain generated keys"
paths = ['''^testdata/''']
```

A config gitleaks v8 cannot load, one still in the gitleaks v7 format (`[allowlist] files = …`, rules without an `id`), is run with gitleaks v7.4.0, as before, and the job shows a warning to migrate it. gitleaks v7 ignores `.gitleaksignore`.
