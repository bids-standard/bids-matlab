.PHONY: clean
clean:
	rm -rf data/dummy
	rm -rf bids-examples
	mkdir -p bids-examples/

install:
	pip install pandas

.PHONY: data
data: clean install
	python create_dummy_data_set.py
	rm -rf bids-examples
	git clone https://github.com/bids-standard/bids-examples.git --depth 1
	touch bids-examples/.gitkeep
