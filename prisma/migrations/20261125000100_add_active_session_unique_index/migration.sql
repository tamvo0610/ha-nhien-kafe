-- One active dining session per table
CREATE UNIQUE INDEX "one_active_session_per_table"
ON "dining_sessions"("tableId", "status")
WHERE "status" = 'ACTIVE';