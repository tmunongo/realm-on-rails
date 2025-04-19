run-db:
	docker compose -f compose.dev.yml up -d

stop-db:
	docker compose -f compose.dev.yml down