-- Database initialization script for Music Campaign Backend
-- This script ensures proper setup and performance optimizations

-- Create extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Ensure proper collation for text data
ALTER DATABASE music_campaigns SET default_text_search_config = 'english';

-- Create indexes for better performance (these will be created by SQLAlchemy too)
-- but we ensure they exist from the start

-- Performance settings for small to medium workloads (Raspberry Pi)
ALTER SYSTEM SET shared_buffers = '128MB';
ALTER SYSTEM SET effective_cache_size = '512MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

-- Apply the settings
SELECT pg_reload_conf();

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'Music Campaign Database initialized successfully';
    RAISE NOTICE 'Database: music_campaigns';
    RAISE NOTICE 'User: backend_user';
    RAISE NOTICE 'Extensions: uuid-ossp, pg_stat_statements';
    RAISE NOTICE 'Performance optimizations applied for Raspberry Pi';
END $$;
