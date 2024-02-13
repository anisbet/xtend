.PHONY: clean pristine production test

clean:
	-rm *.lst

pristine: clean
	-rm xtend.log
	-rm xtend_charge_changes.diff
	-rm xtend_hold_changes.diff

production:
	scp xtend.sh sirsi@edpl.sirsidynix.net:/software/EDPL/Unicorn/Bincustom

test: test.sh
	./test.sh