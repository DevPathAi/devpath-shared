CREATE TABLE ad_settings (
    id         INT         NOT NULL PRIMARY KEY,
    enabled    BOOLEAN     NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_ad_settings_singleton CHECK (id = 1)
);
INSERT INTO ad_settings (id, enabled) VALUES (1, TRUE);
CREATE TRIGGER ad_settings_set_updated_at BEFORE UPDATE ON ad_settings
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
