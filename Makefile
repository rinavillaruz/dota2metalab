.PHONY: dev-up dev-down

dev-up:
	@echo "Creating Kind Cluster..."
	@kind create cluster --name dota2metalab --config infrastructure/kind/cluster.yaml
	@echo "Cluster created!"
	@./cli/setup-cicd.sh

dev-down:
	@./cli/destroy-cluster.sh