CREATE TABLE advertisement (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       VARCHAR(200)  NOT NULL,
    image_url   VARCHAR(1000),
    link_url    VARCHAR(1000) NOT NULL,
    slot        VARCHAR(30)   NOT NULL,
    weight      INT           NOT NULL DEFAULT 1,
    status      VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
    starts_at   TIMESTAMPTZ,
    ends_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_ad_slot   CHECK (slot   IN ('DASHBOARD_TOP','COMMUNITY_FEED','CONTENT_PAGE')),
    CONSTRAINT chk_ad_status CHECK (status IN ('ACTIVE','PAUSED')),
    CONSTRAINT chk_ad_weight CHECK (weight >= 1)
);
CREATE INDEX idx_ad_slot_status ON advertisement (slot, status);
CREATE TRIGGER advertisement_set_updated_at BEFORE UPDATE ON advertisement
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
