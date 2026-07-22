CREATE TABLE ad_daily_stats (
    ad_id       BIGINT NOT NULL REFERENCES advertisement(id) ON DELETE CASCADE,
    stat_date   DATE   NOT NULL,
    impressions BIGINT NOT NULL DEFAULT 0,
    clicks      BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (ad_id, stat_date)
);
