# Generic Airbyte Integration Patterns

**Rule Overview**: Generic Airbyte integration patterns for triggering data syncs, managing connections, and orchestrating data pipelines via Airflow.

**Rationale**: Programmatic sync triggering, dependency management, error handling, and integration with external systems.

## Core Patterns

### Connection Discovery by Name

**Rule**: Implement helper function to find Airbyte connection ID by name via Airbyte API

**Rationale**: User-friendly configuration, dynamic connection lookups, decoupling from connection IDs

**Implementation**:
```python
def get_connection_id_by_name(connection_name: str, **kwargs) -> str:
    """Get Airbyte connection ID by its name."""
    api = get_airbyte_api()
    workspaces = api.list_workspaces()

    for workspace in workspaces["workspaces"]:
        connections = api.list_connections(workspace["workspaceId"])
        for conn in connections["connections"]:
            if conn["name"] == connection_name:
                return conn["connectionId"]

    raise ValueError(f"Connection with name '{connection_name}' not found")
```

**Reference**: @rule:orchestration/airbyte_integration.md

### Generic Sync Triggering Pattern

**Rule**: Use AirbyteTriggerSyncOperator with appropriate timeout and configuration

**Rationale**: Programmatic sync triggering, dependency management, error handling

**Implementation**:
```python
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator

trigger_airbyte_sync = AirbyteTriggerSyncOperator(
    task_id='trigger_airbyte_sync',
    airbyte_conn_id='airbyte_prod',
    connection_id='{{ ti.xcom_pull(task_ids="get_airbyte_connection") }}',
    asynchronous=False,
    timeout=3600,
    dag=dag,
)
```

**Reference**: @rule:orchestration/airbyte_integration.md

### Connection Configuration Pattern

**Rule**: Use consistent connection naming and configuration across Airflow and Airbyte

**Rationale**: Clear ownership, easy debugging, consistent behavior

**Implementation**:
```yaml
# Connection naming convention
airbyte_connection_mysql = "mysql (PROD)"
airbyte_connection_mysql_dev = "mysql (DEV)"
airbyte_connection_bigquery = "bigquery (PROD)"

# Use these names in Airflow DAGs
connection_id = get_connection_id_by_name("mysql (PROD)")
```

**Reference**: @example:devops/airbyte_connection_module.md

### Generic Timeout Configuration

**Rule**: Set appropriate timeout values based on data volume and sync complexity

**Rationale**: Prevent hanging tasks, cost control, SLA compliance

**Implementation**:
```python
# Short syncs (small datasets)
AirbyteTriggerSyncOperator(
    timeout=1800,  # 30 minutes
    dag=dag,
)

# Long syncs (large historical loads)
AirbyteTriggerSyncOperator(
    timeout=7200,  # 2 hours
    dag=dag,
)
```

**Reference**: @rule:orchestration/airbyte_integration.md

---

## Generic API Client Patterns

### Singleton API Client

**Rule**: Use singleton pattern for Airbyte API client with connection discovery

**Rationale**: Connection pooling, centralized configuration, efficient API calls

**Implementation**:
```python
# helpers/airbyte_api.py
import requests
import json
from urllib.parse import urlparse

class Singleton(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]

class AirbyteApi(metaclass=Singleton):
    def __init__(self, airbyte_url):
        url = urlparse(airbyte_url)

        if not all([url.hostname]):
            raise ValueError(f"Expected airbyte_url to be a valid url, instead got '{airbyte_url}'")

        self.host = f"{'http' if not url.scheme else url.scheme}://{url.hostname}{':' + str(url.port) if url.port else ''}"

    def list_workspaces(self):
        response = self._send_post_request("/api/v1/workspaces/list", dict())
        return response["body"]["workspaces"]

    def list_connections(self, workspace_id):
        response = self._send_post_request("/api/v1/connections/list", dict(workspaceId=workspace_id))
        return response["body"]["connections"]

    def trigger_sync(self, connection_id, sync_mode):
        response = self._send_post_request(f"/api/v1/connections/{connection_id}/sync/trigger", dict(syncMode=sync_mode))
        return response["body"]

    def _send_post_request(self, endpoint, data):
        url = f"{self.host}{endpoint}"
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        return response.json()
```

**Reference**: @rule:orchestration/airbyte_api_client.md

### Generic Error Handling

**Rule**: Implement robust error handling for API failures and connection issues

**Rationale**: Resilience, debugging support, operational monitoring

**Implementation**:
```python
def get_connection_id_by_name_safe(connection_name: str, max_retries=3) -> str:
    """Get connection ID with retry logic and error handling."""
    api = get_airbyte_api()
    
    for attempt in range(max_retries):
        try:
            workspaces = api.list_workspaces()
            break
        except requests.exceptions.RequestException as e:
            if attempt == max_retries - 1:
                raise AirbyteApiError(f"Failed to connect to Airbyte API after {max_retries} attempts: {e}")
            time.sleep(2 ** attempt)  # Exponential backoff
    
    for workspace in workspaces["workspaces"]:
        try:
            connections = api.list_connections(workspace["workspaceId"])
            for conn in connections["connections"]:
                if conn["name"] == connection_name:
                    return conn["connectionId"]
        except requests.exceptions.RequestException as e:
            continue  # Try next workspace
    
    raise ConnectionNotFoundError(f"Connection with name '{connection_name}' not found")
```

---

## Generic Pipeline Orchestration

### Sync Pipeline Pattern

**Rule**: Create standardized sync pipeline with validation and error handling

**Rationale**: Consistent sync workflows, proper error handling, monitoring support

**Implementation**:
```python
def create_sync_pipeline(dag, connection_name, sync_mode="full_refresh"):
    """Create a complete sync pipeline with validation."""
    
    # Step 1: Get connection ID
    get_connection_id = PythonOperator(
        task_id=f'get_{connection_name}_connection',
        python_callable=lambda ti, **kwargs: get_connection_id_by_name_safe(connection_name),
        dag=dag,
    )
    
    # Step 2: Validate connection exists
    validate_connection = PythonOperator(
        task_id=f'validate_{connection_name}_connection',
        python_callable=lambda ti, **kwargs: validate_connection_exists(ti.xcom_pull(task_ids=f'get_{connection_name}_connection'))),
        dag=dag,
    )
    
    # Step 3: Trigger sync
    trigger_sync = AirbyteTriggerSyncOperator(
        task_id=f'trigger_{connection_name}_sync',
        airbyte_conn_id='airbyte_prod',
        connection_id='{{ ti.xcom_pull(task_ids=f"get_{connection_name}_connection") }}',
        sync_mode=sync_mode,
        timeout=3600,
        dag=dag,
    )
    
    # Step 4: Verify sync completion
    verify_sync = PythonOperator(
        task_id=f'verify_{connection_name}_sync',
        python_callable=lambda ti, **kwargs: verify_sync_completion(ti.xcom_pull(task_ids=f'trigger_{connection_name}_sync'))),
        dag=dag,
    )
    
    # Define dependencies
    get_connection_id >> validate_connection >> trigger_sync >> verify_sync

def validate_connection_exists(connection_id):
    """Validate that connection exists and is accessible."""
    api = get_airbyte_api()
    try:
        # Try to get connection details
        connections = api.list_connections("default_workspace")
        for conn in connections["connections"]:
            if conn["connectionId"] == connection_id:
                return True
        return False
    except Exception as e:
        raise AirbyteValidationError(f"Failed to validate connection {connection_id}: {e}")

def verify_sync_completion(sync_job_id):
    """Verify that sync completed successfully."""
    # Implementation would check sync job status
    # This is a placeholder for actual verification logic
    return True
```

**Reference**: @rule:orchestration/sync_pipeline_pattern.md

### Multi-Connection Orchestration

**Rule**: Orchestrate multiple connections with dependency management

**Rationale**: Complex data pipelines, proper sequencing, resource management

**Implementation**:
```python
def create_multi_connection_pipeline(dag, connections_config):
    """Create pipeline for multiple connections with dependencies."""
    
    tasks = {}
    
    for connection_config in connections_config:
        connection_name = connection_config['name']
        
        # Create tasks for each connection
        tasks[f'get_{connection_name}_id'] = PythonOperator(
            task_id=f'get_{connection_name}_id',
            python_callable=lambda ti, **kwargs: get_connection_id_by_name_safe(connection_name),
            dag=dag,
        )
        
        tasks[f'trigger_{connection_name}'] = AirbyteTriggerSyncOperator(
            task_id=f'trigger_{connection_name}',
            airbyte_conn_id='airbyte_prod',
            connection_id='{{ ti.xcom_pull(task_ids=f"get_{connection_name}_id") }}',
            timeout=connection_config.get('timeout', 3600),
            dag=dag,
        )
        
        tasks[f'verify_{connection_name}'] = PythonOperator(
            task_id=f'verify_{connection_name}',
            python_callable=lambda ti, **kwargs: verify_sync_completion(ti.xcom_pull(task_ids=f'trigger_{connection_name}'))),
            dag=dag,
        )
    
    # Define dependencies between connections
    for i, connection_config in enumerate(connections_config):
        connection_name = connection_config['name']
        
        # Basic pipeline for each connection
        tasks[f'get_{connection_name}_id'] >> tasks[f'trigger_{connection_name}'] >> tasks[f'verify_{connection_name}']
        
        # Add cross-connection dependencies if specified
        if 'depends_on' in connection_config:
            for dependency in connection_config['depends_on']:
                tasks[f'verify_{dependency}'] >> tasks[f'trigger_{connection_name}']
```

---

## Generic Configuration Management

### Environment-Specific Configuration

**Rule**: Use environment variables and configuration files for different deployment scenarios

**Implementation**:
```python
# Configuration from environment variables
AIRBYTE_URL = Variable.get("airbyte_url", "http://localhost:8000")
AIRBYTE_USERNAME = Variable.get("airbyte_username", "airbyte")
AIRBYTE_PASSWORD = Variable.get("airbyte_password", "password")

# Configuration from YAML file
def load_config_from_file(config_path):
    """Load Airbyte configuration from YAML file."""
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

# Dynamic API client creation
def get_airbyte_api():
    """Create API client with dynamic configuration."""
    airbyte_url = AIRBYTE_URL
    
    if AIRBYTE_USERNAME and AIRBYTE_PASSWORD:
        # Use basic auth for development
        return AirbyteApiWithAuth(airbyte_url, AIRBYTE_USERNAME, AIRBYTE_PASSWORD)
    else:
        # Use token auth for production
        return AirbyteApiWithToken(airbyte_url, get_airbyte_token())
```

### Connection Management

**Rule**: Use consistent connection naming and lifecycle management

**Implementation**:
```python
class ConnectionManager:
    def __init__(self, api_client):
        self.api = api_client
        self._connections_cache = {}
    
    def get_connection_id(self, connection_name, refresh_cache=False):
        """Get connection ID with caching."""
        if refresh_cache or connection_name not in self._connections_cache:
            self._connections_cache[connection_name] = self._find_connection_id(connection_name)
        return self._connections_cache[connection_name]
    
    def _find_connection_id(self, connection_name):
        """Find connection ID by name across all workspaces."""
        workspaces = self.api.list_workspaces()
        
        for workspace in workspaces["workspaces"]:
            connections = self.api.list_connections(workspace["workspaceId"])
            for conn in connections["connections"]:
                if conn["name"] == connection_name:
                    return conn["connectionId"]
        
        raise ConnectionNotFoundError(f"Connection '{connection_name}' not found")
    
    def list_connections(self, pattern=None):
        """List all connections, optionally filtered by pattern."""
        all_connections = []
        
        workspaces = self.api.list_workspaces()
        for workspace in workspaces["workspaces"]:
            connections = self.api.list_connections(workspace["workspaceId"])
            for conn in connections["connections"]:
                if pattern is None or pattern in conn["name"]:
                    all_connections.append({
                        'name': conn["name"],
                        'connectionId': conn["connectionId"],
                        'workspaceId': workspace["workspaceId"],
                        'sourceType': conn.get('sourceType'),
                        'destinationType': conn.get('destinationType'),
                    })
        
        return all_connections
```

---

## Generic Best Practices

### Error Handling and Resilience

**Rule**: Implement comprehensive error handling for network issues and API failures

**Implementation**:
```python
class ResilientAirbyteClient:
    def __init__(self, base_url, max_retries=3, backoff_factor=2):
        self.base_url = base_url
        self.max_retries = max_retries
        self.backoff_factor = backoff_factor
        self.session = requests.Session()
    
    def _make_request(self, method, endpoint, **kwargs):
        """Make HTTP request with retry logic."""
        url = f"{self.base_url}{endpoint}"
        
        for attempt in range(self.max_retries):
            try:
                response = self.session.request(method, url, **kwargs)
                response.raise_for_status()
                return response
            except requests.exceptions.RequestException as e:
                if attempt == self.max_retries - 1:
                    raise AirbyteApiError(f"Request failed after {self.max_retries} attempts: {e}")
                
                wait_time = self.backoff_factor ** attempt
                time.sleep(wait_time)
    
    def list_workspaces(self):
        """List workspaces with retry logic."""
        return self._make_request("GET", "/api/v1/workspaces/list")["body"]["workspaces"]
```

### Monitoring and Observability

**Rule**: Add logging and monitoring for sync operations and API calls

**Implementation**:
```python
import logging

logger = logging.getLogger(__name__)

class MonitoredAirbyteSync:
    def __init__(self, api_client):
        self.api = api_client
    
    def trigger_sync_with_monitoring(self, connection_id, sync_mode="full_refresh"):
        """Trigger sync with comprehensive monitoring."""
        logger.info(f"Triggering sync for connection {connection_id} with mode {sync_mode}")
        
        start_time = time.time()
        
        try:
            # Trigger the sync
            response = self.api.trigger_sync(connection_id, sync_mode)
            job_id = response["body"]["job"]["id"]
            
            logger.info(f"Sync triggered successfully. Job ID: {job_id}")
            
            # Monitor job completion
            self._monitor_job_completion(job_id, start_time)
            
            return job_id
            
        except Exception as e:
            logger.error(f"Failed to trigger sync for connection {connection_id}: {e}")
            raise
    
    def _monitor_job_completion(self, job_id, start_time):
        """Monitor job completion and log metrics."""
        # Implementation would poll job status and log completion metrics
        completion_time = time.time() - start_time
        logger.info(f"Job {job_id} completed in {completion_time:.2f} seconds")
```

---

## Generic Integration Examples

### Integration with External Databases

**Rule**: Use Airbyte syncs to populate data warehouses and databases

**Implementation**:
```python
def create_database_sync_pipeline(dag, source_connection, target_table):
    """Create pipeline to sync data from Airbyte to database."""
    
    # Step 1: Trigger Airbyte sync
    trigger_sync = AirbyteTriggerSyncOperator(
        task_id='trigger_database_sync',
        airbyte_conn_id='airbyte_prod',
        connection_id='{{ ti.xcom_pull(task_ids="get_source_connection") }}',
        dag=dag,
    )
    
    # Step 2: Wait for sync completion
    wait_for_sync = PythonOperator(
        task_id='wait_for_sync_completion',
        python_callable=lambda ti, **kwargs: wait_for_airbyte_sync(ti.xcom_pull(task_ids="trigger_database_sync")),
        dag=dag,
    )
    
    # Step 3: Update database statistics
    update_stats = PythonOperator(
        task_id='update_database_stats',
        python_callable=lambda ti, **kwargs: update_table_statistics(target_table, ti.xcom_pull(task_ids="trigger_database_sync")),
        dag=dag,
    )
    
    # Define dependencies
    trigger_sync >> wait_for_sync >> update_stats
```

### Integration with Data Quality Tools

**Rule**: Use Airbyte syncs as data sources for data quality validation

**Implementation**:
```python
def create_data_quality_pipeline(dag, connection_name):
    """Create pipeline that syncs data and runs quality checks."""
    
    # Step 1: Sync data
    sync_data = AirbyteTriggerSyncOperator(
        task_id=f'sync_{connection_name}_data',
        airbyte_conn_id='airbyte_prod',
        connection_id='{{ ti.xcom_pull(task_ids=f"get_{connection_name}_connection") }}',
        dag=dag,
    )
    
    # Step 2: Run data quality checks
    run_quality_checks = PythonOperator(
        task_id=f'run_quality_checks_{connection_name}',
        python_callable=lambda ti, **kwargs: run_data_quality_checks(ti.xcom_pull(task_ids=f"sync_{connection_name}_data")),
        dag=dag,
    )
    
    # Step 3: Generate quality report
    generate_report = PythonOperator(
        task_id=f'generate_quality_report_{connection_name}',
        python_callable=lambda ti, **kwargs: generate_quality_report(ti.xcom_pull(task_ids=f"run_quality_checks_{connection_name}"))),
        dag=dag,
    )
    
    # Define dependencies
    sync_data >> run_quality_checks >> generate_report
```

---

## Rationale

Generic Airbyte integration patterns provide a foundation for consistent, maintainable, and scalable data pipeline orchestration. These patterns ensure:

- **Consistency**: Standard sync triggering and connection management
- **Maintainability**: Clear API client patterns and error handling
- **Scalability**: Patterns that work for small and large deployments
- **Testability**: Proper validation and monitoring approaches
- **Flexibility**: Generic patterns that adapt to any environment

**Integration Benefits:**
- Works with any Airbyte version and deployment
- Integrates with any database or data warehouse
- Supports any external system or validation tool
- Compatible with any monitoring or observability system
- Adapts to any connection or source configuration

**Universal Applicability:**
- Generic patterns work with any Airbyte setup
- Standalone examples require no external dependencies
- Cloud integration works with any provider
- Local development patterns work with any setup
- Templates can be adapted to any pipeline structure