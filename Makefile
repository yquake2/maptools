# Check the OS type
OSTYPE := $(shell uname -s)

# Some plattforms call it "amd64" and some "x86_64"
ARCH := $(shell uname -m | sed -e s/i.86/i386/ -e s/amd64/x86_64/)

# Refuse all other plattforms as a firewall against PEBKAC
# (You'll need some #ifdef for your unsupported  plattform!)
ifneq ($(ARCH),i386)
ifneq ($(ARCH),x86_64)
$(error arch $(ARCH) is currently not supported)
endif
endif

# ----------

# The compiler
CC := gcc

# ---------- 

# Base CFLAGS. 
#
# -O2 are enough optimizations.
# 
# -fno-strict-aliasing since the source doesn't comply
#  with strict aliasing rules and it's next to impossible
#  to get it there...
#
# -fomit-frame-pointer since the framepointer is mostly
#  useless for debugging Quake II and slows things down.
#
# -g to build allways with debug symbols. Please do not
#  change this, since it's our only chance to debug this
#  crap when random crashes happen!
#
# -MMD to generate header dependencies.
CFLAGS := -O2 -fno-strict-aliasing -fomit-frame-pointer \
		  -Wall -pipe -g -MMD

# ----------

# Base include path.
ifeq ($(OSTYPE),Linux)
INCLUDE := -I/usr/include -I./common
else ifeq ($(OSTYPE),FreeBSD)
INCLUDE := -I/usr/local/include -I./common
endif

# ----------

# When make is invoked by "make VERBOSE=1" print
# the compiler and linker commands.

ifdef VERBOSE
Q :=
else
Q := @
endif 

# ---------- 

# Builds everything
all: qdata1
	
# ---------- 

# Cleanup
clean:
	@echo "===> CLEAN"
	${Q}rm -Rf build release
 
# ----------

# qdata
qdata1:
	@echo '===> Building qdata'
	${Q}mkdir -p release
	$(MAKE) release/qdata

build/qdata/%.o: %.c
	@echo '===> CC $<'
	${Q}mkdir -p $(@D)
	${Q}$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $<

# ----------

# Used by qdata
QDATA_OBJS_ = \
		common/cmdlib.o \
		common/scriplib.o \
		common/lbmlib.o \
		common/mathlib.o \
		common/trilib.o \
		common/l3dslib.o \
		common/threads.o \
		qdata/qdata.o \
        qdata/models.o \
		qdata/sprites.o \
		qdata/images.o \
		qdata/tables.o

# ----------

# Rewrite pathes to our object directory
QDATA_OBJS = $(patsubst %,build/qdata/%,$(QDATA_OBJS_))

# ----------

# Generate header dependencies
QDATA_DEPS= $(QDATA_OBJS:.o=.d)

# ----------

-include $(QDATA_DEPS) 

# ----------

# release/qdata
release/qdata : $(QDATA_OBJS) 
	@echo '===> LD $@'
	${Q}$(CC) $(QDATA_OBJS) $(LDFLAGS) -o $@

