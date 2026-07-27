CREATE TABLE beta_allowlist (
  id         bigserial PRIMARY KEY,
  email      varchar(320) NOT NULL UNIQUE,
  note       varchar(255),
  added_by   varchar(320),
  created_at timestamptz NOT NULL DEFAULT now()
);
