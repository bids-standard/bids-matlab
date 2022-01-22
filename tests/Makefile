.PHONY: clean
clean:
	rm -rf data/dummy
	rm -rf bids-examples

.PHONY: data
data:
	sh create_dummy_data_set.sh
	git clone https://github.com/bids-standard/bids-examples.git --depth 1
