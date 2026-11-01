FROM gsoci.azurecr.io/giantswarm/gitleaks:v8.30.1 AS gitleaks-v7

FROM gsoci.azurecr.io/giantswarm/gitleaks:v8.30.1

LABEL "com.github.actions.name"="gitleaks-action"
LABEL "com.github.actions.description"="runs gitleaks on push and pull request events"
LABEL "com.github.actions.icon"="shield"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/giantswarm/gitleaks-action"

# gitleaks v7 only runs a repository's config that is still in the v7 format.
COPY --from=gitleaks-v7 /usr/bin/gitleaks /usr/bin/gitleaks-v7
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
