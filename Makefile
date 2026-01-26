CONTIKI_PROJECT = receiver_root sender
all: $(CONTIKI_PROJECT)

# Include BRPL objective function source
PROJECT_SOURCEFILES += brpl-of.c

CONTIKI = $(CONTIKI_NG_PATH)

# Ensure CONTIKI_NG_PATH is set
ifndef CONTIKI_NG_PATH
  $(error CONTIKI_NG_PATH not defined! Please set it to your Contiki-NG installation path)
endif

include $(CONTIKI)/Makefile.include
