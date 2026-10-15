BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tasks" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "description" text,
    "completed" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--
-- MIGRATION VERSION FOR karazin_ci_cd
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('karazin_ci_cd', '20261015093547675', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261015093547675', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
