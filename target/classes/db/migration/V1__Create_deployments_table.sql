-- Create deployments table
CREATE TABLE deployments (
    id BIGSERIAL PRIMARY KEY,
    deployment_id VARCHAR(255) UNIQUE NOT NULL,
    customer_id VARCHAR(255) NOT NULL,
    application_name VARCHAR(255) NOT NULL,
    environment VARCHAR(100) NOT NULL,
    target_revision VARCHAR(255) NOT NULL,
    strategy VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    argo_application_name VARCHAR(255),
    argo_project VARCHAR(255),
    source_repo_url TEXT,
    source_path VARCHAR(500),
    destination_namespace VARCHAR(255),
    destination_server VARCHAR(500),
    parameters TEXT,
    values TEXT,
    sync_policy TEXT,
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    duration_seconds BIGINT
);

-- Create deployment_metadata table for key-value pairs
CREATE TABLE deployment_metadata (
    deployment_id BIGINT NOT NULL,
    metadata_key VARCHAR(255) NOT NULL,
    metadata_value TEXT,
    PRIMARY KEY (deployment_id, metadata_key),
    FOREIGN KEY (deployment_id) REFERENCES deployments(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX idx_deployments_customer_id ON deployments(customer_id);
CREATE INDEX idx_deployments_application_name ON deployments(application_name);
CREATE INDEX idx_deployments_status ON deployments(status);
CREATE INDEX idx_deployments_created_at ON deployments(created_at);
CREATE INDEX idx_deployments_deployment_id ON deployments(deployment_id);

-- Create customer_configs table for caching customer configurations
CREATE TABLE customer_configs (
    id BIGSERIAL PRIMARY KEY,
    customer_id VARCHAR(255) UNIQUE NOT NULL,
    config_data TEXT NOT NULL,
    config_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for customer_configs
CREATE INDEX idx_customer_configs_customer_id ON customer_configs(customer_id);
CREATE INDEX idx_customer_configs_updated_at ON customer_configs(updated_at);

-- Create audit_log table for tracking changes
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id VARCHAR(255),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(255) NOT NULL,
    details TEXT,
    ip_address INET
);

-- Create indexes for audit_log
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_log_action ON audit_log(action);
CREATE INDEX idx_audit_log_resource_type ON audit_log(resource_type);
CREATE INDEX idx_audit_log_resource_id ON audit_log(resource_id); 