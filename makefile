.PHONY: count
cloc:
	cloc --exclude-dir=.git,continue .
count:
	@for i in $$(ls *.md); do \
		s=$$(echo $$i | cut -d_ -f1); \
		echo $$s; \
	done | sort | uniq -c


