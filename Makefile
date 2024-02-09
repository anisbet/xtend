.PHONY: clean pristine production

clean:
	-rm *.lst

pristine: clean
	-rm xtend.log
	-rm xtend_charge_changes.diff

production:
	scp xtend.sh sirsi@edpl.sirsidynix.net:/software/EDPL/Unicorn/Bincustom
