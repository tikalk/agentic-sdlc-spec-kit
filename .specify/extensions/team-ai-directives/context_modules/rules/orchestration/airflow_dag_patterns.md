# Generic Airflow DAG Patterns

**Rule Overview**: Standard patterns for Airflow DAG development including DAG structure, imports, registration, and KubernetesPodOperator usage.

**Rationale**: Consistent DAG organization, maintainability, performance, and Airflow best practices across data engineering projects.

## Core Patterns

### DAG Directory Structure

**Rule**: Organize DAGs in `dags/` directory with `dags/__init__.py` for package initialization

**Rationale**: Proper package structure, Airflow auto-discovery, clear separation of concerns

**Implementation**:
```
dags/
├── __init__.py              # Empty file for package initialization
├── helpers/                 # Reusable utility modules
│   ├── api_client.py      # Generic API client patterns
│   ├── config_helper.py   # Configuration management
│   └── validation_helper.py # Data validation utilities
├── dag1.py                 # Simple pipeline DAG
├── dag2.py                 # Complex DAG with task groups
├── config.yml               # Configuration for dynamic DAGs
└── tests/                  # Unit tests for helpers
```

**Reference**: @example:testing/pytest_class_based.md

### DAG Registration

**Rule**: Use `globals()[dag_id] = dag` to register DAGs for importability

**Rationale**: Airflow discovers DAGs dynamically, global registration required

**Implementation**:
```python
from airflow import DAG

dag = DAG(
    dag_id='my_dag',
    default_args=default_args,
    description='My data pipeline DAG',
    schedule_interval='@daily',
    catchup=False
)

# Register DAG globally
globals()['my_dag'] = dag
```

**Reference**: @rule:orchestration/airflow_dag_patterns.md

### Default Arguments Standardization

**Rule**: Use consistent default arguments across all DAGs for predictable behavior

**Rationale**: Centralized configuration, maintainability, debugging support

**Implementation**:
```python
# Common default arguments pattern
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=3),
}
```

**Reference**: @example:orchestration/airflow_dag_basic.md

---

## Generic KubernetesPodOperator Patterns

### Pod Operator Configuration

**Rule**: Use KubernetesPodOperator with standardized configuration for cluster task execution

**Rationale**: Task isolation, resource management, security integration

**Implementation**:
```python
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from kubernetes.client import models as k8s
from airflow.kubernetes.secret import Secret

# Define secrets
secret_all_keys = Secret('env', None, 'airflow-dags-secrets')

# Define environment variables
env_vars = [
    k8s.V1EnvVar(name='TARGET_NAME', value='multi'),
    k8s.V1EnvVar(name='DATASET_PREFIX', value='prod'),
]

# Define resource requests
resources = k8s.V1ResourceList(
    requests=[
        k8s.V1ResourceRequirements(cpu='1000m', memory='2Gi')
    ],
    limits=[
        k8s.V1ResourceRequirements(cpu='2000m', memory='6Gi')
    ]
)

task = KubernetesPodOperator(
    namespace=Variable.get("namespace"),
    image='your-registry/your-image:latest',
    image_pull_policy='Always',
    cmds=["/bin/sh", "-c"],
    arguments=["your-command --arg1 --arg2"],
    name="run_task",
    task_id="run_task",
    secrets=[secret_all_keys],
    env_vars=env_vars,
    resources=resources,
    get_logs=True,
    in_cluster=True,
    dag=dag,
)
```

**Reference**: @rule:orchestration/kubernetes_operator_patterns.md

### Namespace and Service Account

**Rule**: Use Variable for namespace and environment-specific service accounts

**Rationale**: Multi-environment support, security

**Implementation**:
```python
# Get namespace from Airflow Variable
namespace = Variable.get("namespace")

# Validate namespace pattern
if not namespace.startswith('airflow-'):
    raise ValueError(f"Namespace '{namespace}' must follow pattern 'airflow-<env>'")

# Determine environment
environment = namespace.replace('airflow-', '')

# Service account selection based on environment
service_account_name = "airflow-prod" if environment == "prod" else "airflow-stg"

task = KubernetesPodOperator(
    namespace=namespace,
    service_account_name=service_account_name,
    # ... other configuration
)
```

### Secret Management

**Rule**: Use Airflow Secret object for environment variables from Kubernetes secrets

**Rationale**: Security, GitOps-friendly, automatic secret rotation

**Implementation**:
```python
from airflow.kubernetes.secret import Secret

# Define secret with environment variable injection
secret_all_keys = Secret(
    deploy_type='env',
    deploy_target='none',
    secret='airflow-dags-secrets'
)

# Use in KubernetesPodOperator
task = KubernetesPodOperator(
    secrets=[secret_all_keys],
    # ... other configuration
)
```

---

## Generic TaskGroup Patterns

### Hierarchical Task Organization

**Rule**: Use TaskGroup for complex DAG organization with parent-child relationships

**Rationale**: Logical grouping, visual clarity, modular maintenance

**Implementation**:
```python
from airflow.utils.task_group import TaskGroup

# Define parent task group
with TaskGroup(group_id="data_pipeline", dag=dag) as data_task_group:
    # Child groups
    with TaskGroup(group_id="source_tests", dag=dag, parent_group=data_task_group) as source_tests:
        dbt_debug = KubernetesPodOperator(..., task_id="dbt_debug")
        dbt_test_sources = KubernetesPodOperator(..., task_id="dbt_test_sources")

    with TaskGroup(group_id="materializations", dag=dag, parent_group=data_task_group) as materializations:
        dbt_run_mart1 = KubernetesPodOperator(..., task_id="run_mart1")
        dbt_test_mart1 = KubernetesPodOperator(..., task_id="test_mart1")

# Define dependencies between groups
source_tests >> materializations
```

**Reference**: @example:orchestration/task_group_pattern.md

### Task Dependencies

**Rule**: Define clear task dependencies using `>>` operator for linear pipelines

**Rationale**: Execution order, failure handling, data dependencies

**Implementation**:
```python
# Linear dependency
task1 >> task2 >> task3

# Branching dependencies
task1 >> [task2a, task2b]
task2a >> task3
task2b >> task3

# TaskGroup dependencies
parent_group >> child_group
```

---

## Generic Dynamic DAG Generation

### Configuration-Driven DAGs

**Rule**: Load DAG configurations from YAML/JSON files and generate DAGs dynamically

**Rationale**: Flexibility, version control of config, reduced code duplication

**Implementation**:
```python
# dags/dynamic_dag.py
import os
import yaml
from datetime import datetime

DAG_DIR = os.path.dirname(os.path.abspath(__file__))

def load_dag_config(config_path):
    """Load DAG configurations from YAML file."""
    with open(config_path, 'r') as f:
        if config_path.endswith('.yaml') or config_path.endswith('.yml'):
            config = yaml.safe_load(f)
        elif config_path.endswith('.json'):
            import json
            with open(config_path, 'r') as f:
                config = json.load(f)
        else:
            raise ValueError(f"Unsupported file type: {config_path}")

    if not isinstance(config, dict) or 'pipelines' not in config:
        raise ValueError("Configuration must be a dictionary with 'pipelines' key")

    return config['pipelines']

def create_dag_task(dag, pipeline_config):
    """Create a dynamic DAG task for a pipeline configuration."""
    return KubernetesPodOperator(
        namespace=Variable.get("namespace"),
        image=pipeline_config['image'],
        cmds=pipeline_config['cmds'],
        arguments=pipeline_config['args'],
        name=pipeline_config['name'],
        task_id=pipeline_config['task_id'],
        secrets=[secret_all_keys],
        env_vars=pipeline_config.get('env_vars', []),
        dag=dag,
    )

# Default arguments
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=3),
}

# Load configurations
CONFIG_PATH = os.path.join(DAG_DIR, 'pipelines.yml')
try:
    pipelines = load_dag_config(CONFIG_PATH)
except Exception as e:
    print(f"Error loading pipeline configuration: {e}")
    pipelines = []

# Dynamically create DAGs for each pipeline
for pipeline_config in pipelines:
    dag = DAG(
        dag_id=pipeline_config['dag_id'],
        default_args=default_args,
        description=pipeline_config['description'],
        schedule_interval=pipeline_config.get('schedule', '@daily'),
        catchup=False
    )

    # Create task for this pipeline
    create_dag_task(dag, pipeline_config)

    # Register DAG globally
    globals()[pipeline_config['dag_id']] = dag
```

**Reference**: @rule:orchestration/dynamic_dag_generation.md

---

## Generic Best Practices

### Schedule Management

**Rule**: Use cron expressions or Airflow preset schedules for regular DAG execution

**Rationale**: Automated execution, standard patterns, easy to understand

**Implementation**:
```python
# Cron schedules
dag = DAG(
    dag_id='daily_sync',
    schedule_interval='0 1 * * *',  # Daily at 1 AM
)

# Airflow preset schedules
dag = DAG(
    dag_id='hourly_sync',
    schedule_interval='@hourly',  # Every hour
)

# None for manual trigger
dag = DAG(
    dag_id='manual_pipeline',
    schedule_interval=None,
)
```

### Task Failure Handling

**Rule**: Configure appropriate retries and retry delays for transient failures

**Rationale**: Resilience, cost efficiency, predictable behavior

**Implementation**:
```python
# Task-level retries
task = KubernetesPodOperator(
    retries=3,
    retry_delay=timedelta(minutes=3),
)

# DAG-level defaults
default_args = {
    'retries': 2,
    'retry_delay': timedelta(minutes=1),
}
```

### XCom for Data Passing

**Rule**: Use XCom to pass small data between tasks

**Rationale**: Task communication, configuration sharing

**Implementation**:
```python
# Push to XCom
task1 = KubernetesPodOperator(
    do_xcom_push=True,
)

# Pull from XCom
task2 = KubernetesPodOperator(
    bash_command=f"echo '{% raw ti.xcom_pull(task_ids=\"task1\") %}'",
)
```

---

## Generic Testing and Validation

### DAG Loading Issues

**Rule**: Use `airflow dags test` command to validate DAG syntax and imports

**Rationale**: Catch errors early, ensure Airflow can load DAGs

**Implementation**:
```bash
# Validate DAG syntax
python -c "import ast; ast.parse(open('dags/my_dag.py'))"

# Test DAG loading
airflow dags import -dags/dags/
```

### Task Execution Issues

**Rule**: Use proper logging and error handling in DAG tasks

**Rationale**: Debugging support, error visibility, operational monitoring

**Implementation**:
```python
def create_dag_task(dag, task_config):
    """Create a task with proper error handling."""
    try:
        return KubernetesPodOperator(
            task_id=task_config['task_id'],
            dag=dag,
            on_failure_callback=task_failure_callback,
            on_success_callback=task_success_callback,
            **task_config
        )
    except Exception as e:
        dag.logger.error(f"Failed to create task {task_config['task_id']}: {e}")
        raise
```

---

## Generic Integration Examples

### Integration with External Systems

**Rule**: Use generic patterns for integrating with databases, APIs, and file systems

**Implementation**:
```python
# Database integration
def get_database_connection():
    """Generic database connection pattern."""
    connection_string = Variable.get("database_url")
    return create_engine(connection_string)

# API integration
def call_external_api(endpoint, data):
    """Generic API call pattern."""
    api_url = Variable.get("api_base_url") + endpoint
    headers = {"Content-Type": "application/json"}
    
    response = requests.post(api_url, json=data, headers=headers)
    response.raise_for_status()
    return response.json()
```

### Multi-Environment Configuration

**Rule**: Use environment variables and configuration files for different deployments

**Implementation**:
```python
# Environment-specific configuration
ENVIRONMENT = Variable.get("environment", "development")

if ENVIRONMENT == "production":
    image = "prod-registry/app:latest"
    resources = k8s.V1ResourceList(
        requests=[k8s.V1ResourceRequirements(cpu='2000m', memory='4Gi')],
        limits=[k8s.V1ResourceRequirements(cpu='4000m', memory='8Gi')]
else:
    image = "dev-registry/app:latest"
    resources = k8s.V1ResourceList(
        requests=[k8s.V1ResourceRequirements(cpu='500m', memory='1Gi')],
        limits=[k8s.V1ResourceRequirements(cpu='1000m', memory='2Gi')])
```

---

## Rationale

Generic Airflow DAG patterns provide a foundation for consistent, maintainable, and scalable data pipeline orchestration. These patterns ensure:

- **Consistency**: Standard DAG structure and naming across projects
- **Maintainability**: Clear organization and reusable components
- **Scalability**: Patterns that work for small and large deployments
- **Testability**: Proper testing and validation approaches
- **Flexibility**: Generic patterns that adapt to any environment

**Integration Benefits:**
- Works with any Airflow version and deployment
- Integrates with any Kubernetes cluster
- Supports any container registry and image
- Compatible with any secret management system
- Adapts to any external system or database

**Universal Applicability:**
- Generic patterns work with any Airflow setup
- Standalone examples require no external dependencies
- Cloud integration works with any provider
- Local development patterns work with any local cluster
- Templates can be adapted to any DAG structure