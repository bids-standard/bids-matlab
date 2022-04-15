.PHONY: clean
clean:
	rm -rf data/dummy
	rm -rf bids-examples
	mkdir -p bids-examples && touch bids-examples/.gitkeep

.PHONY: data
data:
	sh create_dummy_data_set.sh
	rm bids-examples/.gitkeep
	git clone https://github.com/bids-standard/bids-examples.git --depth 1
