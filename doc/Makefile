.PHONY: build serve index clean

SERVE_HOST ?= 127.0.0.1
SERVE_PORT ?= 1111

# Production build (uses base_url from config.toml).
build:
	zola build
	pagefind --site public

# Build, index, then serve over a simple HTTP server.
# (zola serve cannot be used here because it overwrites public/ on rebuild,
# wiping out the pagefind/ directory.)
serve:
	zola build --base-url http://$(SERVE_HOST):$(SERVE_PORT)
	pagefind --site public
	@cd public && python3 ../scripts/serve.py $(SERVE_HOST) $(SERVE_PORT)

# Re-run the search indexer without rebuilding the site.
index:
	pagefind --site public

clean:
	rm -rf public
