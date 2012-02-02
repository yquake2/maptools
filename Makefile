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
INCLUDE := -I./src/common
else ifeq ($(OSTYPE),FreeBSD)
INCLUDE := -I./src/common
endif

# ----------

# Base LDFLAGS.
ifeq ($(OSTYPE),Linux)
LDFLAGS := -L/usr/lib -lm
else ifeq ($(OSTYPE),FreeBSD)
LDFLAGS := -L/usr/local/lib -lm
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
all: bspinfo qdata
	
# ---------- 

# Cleanup
clean:
	@echo "===> CLEAN"
	${Q}rm -Rf build release
 
# ----------

# qdata
qdata:
	@echo '===> Building qdata'
	${Q}mkdir -p release
	$(MAKE) release/qdata

build/qdata/%.o: %.c
	@echo '===> CC $<'
	${Q}mkdir -p $(@D)
	${Q}$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $<

# ----------

# bspinfo
bspinfo:
	@echo '===> Building bspinfo'
	${Q}mkdir -p release
	$(MAKE) release/bspinfo

build/bspinfo/%.o: %.c
	@echo '===> CC $<'
	${Q}mkdir -p $(@D)
	${Q}$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $<
 
# ----------

# common stuff
build/common/%.o: %.c
	@echo '===> CC $<'
	${Q}mkdir -p $(@D)
	${Q}$(CC) -c $(CFLAGS) $(INCLUDE) -o $@ $<
 
# ----------

# Common objects
COMMON_OBJS_ = \
		src/common/bspfile.o \
	   	src/common/cmdlib.o \
		src/common/l3dslib.o \
		src/common/lbmlib.o \
		src/common/mathlib.o \
		src/common/mdfour.o \
		src/common/polylib.o \
		src/common/scriplib.o \
		src/common/threads.o \
		src/common/trilib.o

# Used by bspinfo
BSPINFO_OBJS_ = \
		src/bspinfo/bspinfo.o

# Used by qdata
QDATA_OBJS_ = \
		src/qdata/images.o \
        src/qdata/models.o \
		src/qdata/qdata.o \
		src/qdata/sprites.o \
		src/qdata/tables.o \
		src/qdata/video.o

# ----------

# Rewrite pathes to our object directory
COMMON_OBJS = $(patsubst %,build/common/%,$(COMMON_OBJS_))
BSPINFO_OBJS = $(patsubst %,build/common/%,$(BSPINFO_OBJS_))
QDATA_OBJS = $(patsubst %,build/qdata/%,$(QDATA_OBJS_))

# ----------

# Generate header dependencies
COMMON_DEPS= $(COMMON_OBJS:.o=.d)
BSPINFO_DEPS= $(BSPINFO_OBJS:.o=.d)
QDATA_DEPS= $(QDATA_OBJS:.o=.d)

# ----------

-include $(COMMON_DEPS) 
-include $(BSPINFO_DEPS) 
-include $(QDATA_DEPS) 

# ----------

# release/qdata
release/qdata : $(COMMON_OBJS) $(QDATA_OBJS) 
	@echo '===> LD $@'
	${Q}$(CC) $(COMMON_OBJS) $(QDATA_OBJS) $(LDFLAGS) -o $@

# release/bspinfo
release/bspinfo : $(COMMON_OBJS) $(BSPINFO_OBJS) 
	@echo '===> LD $@'
	${Q}$(CC) $(COMMON_OBJS) $(BSPINFO_OBJS) $(LDFLAGS) -o $@
 
