.PHONY: clean
clean:
	rm -rf data/dummy
	rm -rf bids-examples
	mkdir -p bids-examples/


.PHONY: data
data: clean
	sh create_dummy_data_set.sh
	rm -rf bids-examples
	git clone https://github.com/bids-standard/bids-examples.git --depth 1
	touch bids-examples/.gitkeep
