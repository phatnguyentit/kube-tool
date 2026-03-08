# kube-tool

A menu-driven PowerShell CLI tool for managing applications running on **Kubernetes** (AKS, EKS, GKE, on-prem, or any cluster accessible via `kubectl`). It simplifies day-to-day Kubernetes operations through a **template-driven** approach — most tasks can be added or customized by editing YAML files, with no code changes required.

## Getting Started

### Prerequisites

- **PowerShell 5.1+**
- **kubectl** configured with access to your Kubernetes cluster
- **SQL Server PowerShell module** (for SQL script execution)
- Administrator privileges (first run only, to install the `powershell-yaml` module)

### First-Time Setup

1. Open PowerShell **as Administrator**.
2. Execute `kube-tool.ps1` — this will install the required `powershell-yaml` module.

### Daily Usage

From now on, just run **Start.bat** to start the tool. No admin privileges needed after initial setup.

### Configuration

Edit `appconfig.yaml` to set your target cluster, namespace, tenants, and environments:

```yaml
kube-context: aks-prd
namespace: insurance # default namespace for helm release, if not set, it will be default
helm-release-set:
  - $Environment-$Tenant
  - $Environment-$Tenant-infra

tenant-set:
  - tenant1
  - tenant2
  - tenant3
  - tenant4

environment-set:
  - env1
  - env2
  - env3
  - env4
```

On startup, the tool validates your `kubectl` context and prompts you to select an environment and tenant.

## Features

### 1. Update Configuration

Download `.config` and `.json` files from running pods, edit them locally in your default editor, and upload the changes back.

**Template folder:** `ku-template/ku-app-configuration/`

```yaml
# Example: order api setting.yaml
webapp:
    - 'Order\WebApplication\Web.config'
```

### 2. Upload Files

Copy local files (e.g., hot-compiled DLLs) into running pods for rapid iteration.

**Template folder:** `ku-template/upload/`

```yaml
# Example: upload DLL.yaml
local:
  - 'C:\usr\Web\bin\Release\AnotherDLL.dll'
remote:
  webapp: 'Web\bin'
```

### 3. Download Files

Retrieve logs, database backups, or any other files from pods to your local machine.

**Template folder:** `ku-template/download/`

```yaml
# Example: Log WebApp.yaml
webapp:
  - 'WebApplication\WebApplication_Blazor.log'
```

### 4. Port Forwarding

Set up `kubectl port-forward` tunnels to in-cluster services (databases, RabbitMQ, Memcache, etc.) with automatic port conflict detection and retry.

**Template folder:** `ku-template/port-forward/`

```yaml
# Example: database.yaml
deployment: database
remote-port: 1433
local-port: 1433
```

### 5. Execute SQL Scripts

Run SQL scripts against port-forwarded databases. Supports `[DatabaseName]` token replacement and optional JSON output.

**Template folder:** `ku-template/sql-script/`  
**SQL files:** `ku-template/sql-script/scripts/`

```yaml
# Example: Add table Advice database.yaml
description: 'This is the description for the script'
database: 'OrdersDatabase'
scriptfile: 'Remove unused orders.sql'
json-output: false
```

### 6. Deployment Walkthrough

Interactive dashboard showing all deployments with real-time status (replicas, versions, readiness). From here you can:

- View pod logs
- Edit deployment manifests
- Restart deployments

### 7. Update ConfigMaps

Browse and interactively edit Kubernetes ConfigMaps via `kubectl edit`.

### 8. Execute Shell Scripts

Run PowerShell or Bash commands inside containers. The tool automatically detects the container OS.

**Template folder:** `ku-template/shell-script/`

```yaml
# Example: Clear tmp folder in database.yaml
database:
  description: 'Remove all items in side directory tmp'
  shell-script: 'rm -rf tmp\ -f'
```

### 9. Execute Procedures

Chain multiple templates into multi-step workflows with optional wait periods between steps.

**Template folder:** `ku-template/procedure/`

```yaml
# Example:
procedure:
    - template:
          port-forward: database.yaml
    - template:
          sql-script: "Add table Advice database.yaml"
    - wait: 5
    - template:
          sql-script: "Another script.yaml"
```

## Project Structure

```
kube-tool/
├── Start.bat                  # Entry point
├── kube-tool.ps1              # Main script with interactive menu
├── appconfig.yaml             # Cluster, namespace & environment config
├── ku-watch.ps1               # Watch-mode utility
├── ku-context/                # Temporary local staging for file transfers
├── sql-result/                # SQL query output files
├── modules/                   # PowerShell modules
│   ├── common.psm1            # Shared utilities (menus, console output)
│   ├── ku-command.psm1        # kubectl wrappers (pod discovery, exec, cp)
│   ├── ku-environment.psm1    # Configuration validation & context setup
│   ├── ku-template.psm1       # YAML template loader & parser
│   ├── ku-context.psm1        # Local staging folder management
│   ├── ku-upload.psm1         # File upload to pods
│   ├── ku-download.psm1       # File download from pods
│   ├── ku-port-forward.psm1   # Port forwarding with conflict detection
│   ├── ku-mssql.psm1          # SQL script execution
│   ├── ku-shell-script.psm1   # In-container script execution
│   ├── ku-configmaps.psm1     # ConfigMap editing
│   ├── ku-secrets.psm1        # Secret editing
│   ├── ku-log.psm1            # Pod log retrieval
│   ├── ku-app-configuration.psm1  # App config download/edit/upload
│   ├── ku-deployment-walkthrough.psm1  # Deployment dashboard
│   ├── ku-procedure.psm1      # Multi-step procedure orchestrator
│   ├── ku-job-handler.psm1    # (Reserved)
│   ├── ku-teardown-environment.psm1  # (Reserved)
│   └── net.helper.psm1        # TCP port testing utility
└── ku-template/               # YAML-based task templates
    ├── ku-app-configuration/  # App config file definitions
    ├── upload/          # File upload mappings
    ├── download/        # File download paths
    ├── port-forward/    # Port forward definitions
    ├── sql-script/      # SQL script configurations
    │   └── scripts/           # .sql files
    ├── shell-script/    # In-container commands
    └── procedure/             # Multi-step workflow definitions
```

## Adding New Tasks

To add a new operational task, create a YAML file in the appropriate `ku-template/` subfolder following the format shown in the examples above. The tool will automatically pick it up in the interactive menu — no code changes needed.
