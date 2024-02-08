.PHONY: clean pristine production

clean:
	-rm *.lst

pristine: clean
	-rm xtend.log

production:
	scp xtend.sh sirsi@edpl.sirsidynix.net:/software/EDPL/Unicorn/Bincustom
