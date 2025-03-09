-- Table: public.report_updates

DROP TABLE IF EXISTS public.report_updates;

CREATE TABLE IF NOT EXISTS public.report_updates
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    report_id bigint NOT NULL,
    still_there boolean,
	time timestamp with TIME zone NOT NULL,
    CONSTRAINT report_updates_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.report_updates
    OWNER to bbuser;


-- Table: public.reports

DROP TABLE IF EXISTS public.reports;

CREATE TABLE IF NOT EXISTS public.reports
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    station_id bigint NOT NULL,
    alive boolean NOT NULL DEFAULT true,
    CONSTRAINT reports_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.reports
    OWNER to bbuser;