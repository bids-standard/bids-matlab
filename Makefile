 .PHONY: clean manual
clean:
	rm version.txt

version.txt: CITATION.cff
	grep -w "^version" CITATION.cff | sed "s/version: /v/g" > version.txt

validate_cff: CITATION.cff
	cffconvert --validate

manual:
	cd docs && sh create_manual.sh


update_schema: update_schema_json
	git clone https://github.com/bids-standard/bids-specification.git --depth 1
	rm -rf schema/objects schema/rules
	python convert_schema.py
	rm -Rf bids-specification

update_schema_json:
	wget https://bids-specification.readthedocs.io/en/latest/schema.json -O schema/schema.json
