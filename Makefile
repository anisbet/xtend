.PHONY: clean pristine production

clean:
	-rm *.lst

pristine: clean
	-rm xtend.log
	-rm *.diff

production:
	scp xtend.sh sirsi@edpl.sirsidynix.net:/software/EDPL/Unicorn/Bincustom
