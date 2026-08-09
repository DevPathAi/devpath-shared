-- 광고 슬롯별 소스 설정.
-- 슬롯마다 하우스 광고(HOUSE) / 구글 애드센스(ADSENSE) / 끄기(OFF) 중 하나를 지정한다.
-- 시드 3행이 전부 HOUSE라 적용 직후 동작은 기존과 정확히 같다.
CREATE TABLE ad_slot_config (
    slot            VARCHAR(30) NOT NULL PRIMARY KEY,
    source          VARCHAR(20) NOT NULL DEFAULT 'HOUSE',
    adsense_slot_id VARCHAR(50),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_ad_slot_config_slot   CHECK (slot   IN ('DASHBOARD_TOP','COMMUNITY_FEED','CONTENT_PAGE')),
    CONSTRAINT chk_ad_slot_config_source CHECK (source IN ('HOUSE','ADSENSE','OFF'))
);

INSERT INTO ad_slot_config (slot, source) VALUES
  ('DASHBOARD_TOP','HOUSE'),
  ('COMMUNITY_FEED','HOUSE'),
  ('CONTENT_PAGE','HOUSE');

CREATE TRIGGER ad_slot_config_set_updated_at BEFORE UPDATE ON ad_slot_config
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
