.PHONY: up down logs api worker db-shell zip

up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f

api:
	cd api-server && uvicorn app.main:app --reload

worker:
	cd data-worker && python -m worker.main

db-shell:
	docker exec -it seungyo-postgres psql -U seungyo -d seungyo

zip:
	cd .. && zip -r seungyo-app-starter.zip seungyo-app-starter
