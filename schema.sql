-- Plaibook AI Outbound Agent - Simplified MySQL DDL Schema
-- CS 452 Final Project - Initial Design
-- Note: Actual system uses MongoDB, this is a relational representation

-- =============================================
-- CORE ENTITIES (10 tables)
-- =============================================

CREATE TABLE organizations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    ai_agent_name VARCHAR(100) DEFAULT 'AI Assistant',
    phone_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role ENUM('site_admin', 'org_admin', 'user') DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id),
    INDEX idx_org_role (organization_id, role)
);

CREATE TABLE playbooks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    current_version VARCHAR(20) DEFAULT '1.0.0',
    csr_model VARCHAR(100),
    csr_system_prompt TEXT,
    visibility ENUM('private', 'organization', 'public') DEFAULT 'organization',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id)
);

CREATE TABLE campaigns (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    playbook_id BIGINT,
    name VARCHAR(255) NOT NULL,
    type ENUM('inbound', 'outbound') NOT NULL,
    status ENUM('draft', 'active', 'paused', 'completed') DEFAULT 'draft',
    sms_phone_number VARCHAR(20),
    daily_limit INT DEFAULT 100,
    fully_ai_managed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id),
    FOREIGN KEY (playbook_id) REFERENCES playbooks(id),
    INDEX idx_org_status (organization_id, status)
);

CREATE TABLE leads (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    current_campaign_id BIGINT,
    phone VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    source ENUM('csv', 'api', 'manual', 'webhook') DEFAULT 'manual',
    consent_sms BOOLEAN DEFAULT FALSE,
    opted_out BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id),
    FOREIGN KEY (current_campaign_id) REFERENCES campaigns(id),
    UNIQUE INDEX idx_org_phone (organization_id, phone)
);

CREATE TABLE conversations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    campaign_id BIGINT,
    lead_id BIGINT NOT NULL,
    ai_model VARCHAR(100),
    current_stage VARCHAR(100),
    current_sentiment ENUM('positive', 'neutral', 'negative', 'not_interested'),
    is_escalation_needed BOOLEAN DEFAULT FALSE,
    total_messages INT DEFAULT 0,
    quality_score DECIMAL(3,2) DEFAULT 3.50,
    total_cost DECIMAL(10,4) DEFAULT 0,
    billable_outcome VARCHAR(100),
    last_activity TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id),
    FOREIGN KEY (lead_id) REFERENCES leads(id),
    INDEX idx_last_activity (last_activity DESC)
);

CREATE TABLE messages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    conversation_id BIGINT NOT NULL,
    role ENUM('assistant', 'user', 'system') NOT NULL,
    content TEXT,
    sent_by ENUM('ai', 'human'),
    sentiment ENUM('positive', 'neutral', 'negative'),
    confidence DECIMAL(3,2),
    cost DECIMAL(10,6),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id),
    INDEX idx_conversation_time (conversation_id, timestamp)
);

CREATE TABLE calls (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    associated_lead_id BIGINT,
    agent_name VARCHAR(255),
    recording_url TEXT,
    duration_seconds INT,
    transcription LONGTEXT,
    overall_sentiment ENUM('positive', 'neutral', 'negative'),
    quality_score DECIMAL(3,2),
    checkpoint_adherence DECIMAL(3,2),
    sales_outcome ENUM('closed_won', 'closed_lost', 'follow_up', 'no_decision'),
    processing_status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending',
    call_start_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id),
    FOREIGN KEY (associated_lead_id) REFERENCES leads(id),
    INDEX idx_org_status (organization_id, processing_status)
);

CREATE TABLE integrations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    organization_id BIGINT NOT NULL,
    provider ENUM('fieldroutes', 'genesys', 'five9', 'ringcentral', 'surge', 'signwell') NOT NULL,
    is_enabled BOOLEAN DEFAULT FALSE,
    credentials_encrypted TEXT,
    settings JSON,
    connected_at TIMESTAMP,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id),
    UNIQUE INDEX idx_org_provider (organization_id, provider)
);

CREATE TABLE notifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_read (user_id, is_read)
);
