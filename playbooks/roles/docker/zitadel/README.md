# Zitadel Docker role

This role provisions a Zitadel stack with Postgres, optional TLS termination, login frontend, Nginx proxy, and Certbot assets. Templates from `templates/` and static assets from `files/` are rendered into `{{ zitadel_workspace }}` and the Docker Compose stack is started.

## Layout
```
files/
├── certbot/
│   ├── conf/
│   └── www/
├── docker-compose.yaml
├── nginx/
│   ├── conf.d/
│   │   └── default.conf
│   └── nginx.conf
└── run.sh
```

## Defaults
- `zitadel_deploy_dir`: `/opt/zitadel`
- `zitadel_workspace`: `{{ zitadel_deploy_dir }}`
- `zitadel_domain`: `auth.svc.plus`
- `zitadel_masterkey`: `MasterkeyNeedsToHave32Characters`
