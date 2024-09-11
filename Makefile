.PHONY: clean manual

clean:
	rm version.txt

version.txt: clean CITATION.cff
	grep -w "^version" CITATION.cff | sed "s/version: /v/g" > version.txt

update_schema:
	wget https://bids-specification.readthedocs.io/en/latest/schema.json -O schema.json
# get schema from a PR on the spec
# wget https://bids-specification--1377.org.readthedocs.build/en/1377/schema.json -O schema.json

release: version.txt
	python docs/generate_doc.py
	python docs/add_links_to_changelog.py
