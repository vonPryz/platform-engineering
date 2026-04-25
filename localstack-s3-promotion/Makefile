.PHONY: clean help 

clean:
	rm -f artifacts/*.zip artifacts/*.sha256 || true
	rm -f ../simulate-cicd/artifacts/*.zip ../simulate-cicd/artifacts/*.sha256 ../simulate-cicd/artifacts/*.py || true

help:
	@echo "Available targets:"
	@echo "  make clean - Remove generated artifacts for clean promotion run"
	@echo "  make help - Show this help message"
