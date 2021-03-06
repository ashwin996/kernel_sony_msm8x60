#Android makefile to build kernel as a part of Android Build
PERL		= perl

##########
# Kernel #
##########
ifeq ($(TARGET_PREBUILT_KERNEL),)

KERNEL_OUT := $(ANDROID_PRODUCT_OUT)/obj/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config
TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/arm/boot/zImage
KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_MODULES_INSTALL := system
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules
KERNEL_IMG=$(KERNEL_OUT)/arch/arm/boot/Image

MSM_ARCH ?= $(shell $(PERL) -e 'while (<>) {$$a = $$1 if /CONFIG_ARCH_((?:MSM|QSD)[a-zA-Z0-9]+)=y/; $$r = $$1 if /CONFIG_MSM_SOC_REV_(?!NONE)(\w+)=y/;} print lc("$$a$$r\n");' $(KERNEL_CONFIG))
KERNEL_USE_OF ?= $(shell $(PERL) -e '$$of = "n"; while (<>) { if (/CONFIG_USE_OF=y/) { $$of = "y"; break; } } print $$of;' $(KERNEL_DIR)/arch/arm/configs/$(KERNEL_DEFCONFIG))

ifeq "$(KERNEL_USE_OF)" "y"
DTS_NAME ?= $(MSM_ARCH)
DTS_FILES = $(wildcard $(KERNEL_DIR)/arch/arm/boot/dts/$(DTS_NAME)*.dts)
DTS_FILE = $(lastword $(subst /, ,$(1)))
DTB_FILE = $(addprefix $(KERNEL_OUT)/arch/arm/boot/,$(patsubst %.dts,%.dtb,$(call DTS_FILE,$(1))))
ZIMG_FILE = $(addprefix $(KERNEL_OUT)/arch/arm/boot/,$(patsubst %.dts,%-zImage,$(call DTS_FILE,$(1))))
KERNEL_ZIMG = $(KERNEL_OUT)/arch/arm/boot/zImage
DTC = $(KERNEL_OUT)/scripts/dtc/dtc

define append-dtb
mkdir -p $(KERNEL_OUT)/arch/arm/boot;\
$(foreach d, $(DTS_FILES), \
   $(DTC) -p 1024 -O dtb -o $(call DTB_FILE,$(d)) $(d); \
   cat $(KERNEL_ZIMG) $(call DTB_FILE,$(d)) > $(call ZIMG_FILE,$(d));)
endef
else

define append-dtb
endef
endif

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
$(info Using uncompressed kernel)
TARGET_PREBUILT_KERNEL := $(KERNEL_OUT)/piggy
else
TARGET_PREBUILT_KERNEL := $(TARGET_PREBUILT_INT_KERNEL)
endif

define mv-modules
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`;\
ko=`find $$mpath/kernel -type f -name *.ko`;\
for i in $$ko; do mv $$i $(KERNEL_MODULES_OUT)/; done;\
fi
endef

define clean-module-folder
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`; rm -rf $$mpath;\
fi
endef

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)

$(KERNEL_CONFIG): $(KERNEL_OUT)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) $(KERNEL_DEFCONFIG)

$(KERNEL_OUT)/piggy : $(TARGET_PREBUILT_INT_KERNEL)
	$(hide) gunzip -c $(KERNEL_OUT)/arch/arm/boot/compressed/piggy.gzip > $(KERNEL_OUT)/piggy

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) -j4
#	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) modules
#	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) modules_install
#	$(mv-modules)
#	$(clean-module-folder)
	$(append-dtb)

$(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) headers_install

kerneltags: $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) tags

kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) savedefconfig
	cp $(KERNEL_OUT)/defconfig $(KERNEL_DIR)/arch/arm/configs/$(KERNEL_DEFCONFIG)
endif

########################
# Multi kernel support #
########################
ifeq ($(TARGET_NO_MULTIKERNEL),false)

#############
# Kernel OC #
#############
ifeq ($(BOARD_KERNEL_MSM_OC),true)
ifeq ($(TARGET_PREBUILT_KERNEL_OC),)

KERNEL_OUT_OC := $(ANDROID_PRODUCT_OUT)/obj/KERNEL_OC_OBJ
KERNEL_CONFIG_OC := $(KERNEL_OUT_OC)/.config
TARGET_PREBUILT_INT_KERNEL_OC := $(KERNEL_OUT_OC)/arch/arm/boot/zImage
KERNEL_HEADERS_INSTALL_OC := $(KERNEL_OUT_OC)/usr
KERNEL_MODULES_INSTALL_OC := system
KERNEL_MODULES_OUT_OC := $(TARGET_OUT_OC)/lib/modules
KERNEL_IMG_OC=$(KERNEL_OUT_OC)/arch/arm/boot/Image

MSM_ARCH_OC ?= $(shell $(PERL) -e 'while (<>) {$$a = $$1 if /CONFIG_ARCH_((?:MSM|QSD)[a-zA-Z0-9]+)=y/; $$r = $$1 if /CONFIG_MSM_SOC_REV_(?!NONE)(\w+)=y/;} print lc("$$a$$r\n");' $(KERNEL_CONFIG_OC))
KERNEL_USE_OF_OC ?= $(shell $(PERL) -e '$$of = "n"; while (<>) { if (/CONFIG_USE_OF=y/) { $$of = "y"; break; } } print $$of;' $(KERNEL_DIR)/arch/arm/configs/$(KERNEL_DEFCONFIG_OC))

ifeq "$(KERNEL_USE_OF_OC)" "y"
DTS_NAME_OC ?= $(MSM_ARCH_OC)
DTS_FILES_OC = $(wildcard $(KERNEL_DIR)/arch/arm/boot/dts/$(DTS_NAME_OC)*.dts)
DTS_FILE_OC = $(lastword $(subst /, ,$(1)))
DTB_FILE_OC = $(addprefix $(KERNEL_OUT_OC)/arch/arm/boot/,$(patsubst %.dts,%.dtb,$(call DTS_FILE_OC,$(1))))
ZIMG_FILE_OC = $(addprefix $(KERNEL_OUT_OC)/arch/arm/boot/,$(patsubst %.dts,%-zImage,$(call DTS_FILE_OC,$(1))))
KERNEL_ZIMG_OC = $(KERNEL_OUT_OC)/arch/arm/boot/zImage
DTC_OC = $(KERNEL_OUT_OC)/scripts/dtc/dtc

define append-dtb_OC
mkdir -p $(KERNEL_OUT_OC)/arch/arm/boot;\
$(foreach d, $(DTS_FILES_OC), \
   $(DTC_OC) -p 1024 -O dtb -o $(call DTB_FILE_OC,$(d)) $(d); \
   cat $(KERNEL_ZIMG_OC) $(call DTB_FILE_OC,$(d)) > $(call ZIMG_FILE_OC,$(d));)
endef
else

define append-dtb_OC
endef
endif

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
$(info Using uncompressed kernel)
TARGET_PREBUILT_KERNEL_OC := $(KERNEL_OUT_OC)/piggy
else
TARGET_PREBUILT_KERNEL_OC := $(TARGET_PREBUILT_INT_KERNEL_OC)
endif

define mv-modules_OC
mdpath=`find $(KERNEL_MODULES_OUT_OC) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`;\
ko=`find $$mpath/kernel -type f -name *.ko`;\
for i in $$ko; do mv $$i $(KERNEL_MODULES_OUT_OC)/; done;\
fi
endef

define clean-module-folder_OC
mdpath=`find $(KERNEL_MODULES_OUT_OC) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`; rm -rf $$mpath;\
fi
endef

$(KERNEL_OUT_OC):
	mkdir -p $(KERNEL_OUT_OC)

$(KERNEL_CONFIG_OC): $(KERNEL_OUT_OC)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) $(KERNEL_DEFCONFIG_OC)

$(KERNEL_OUT_OC)/piggy : $(TARGET_PREBUILT_INT_KERNEL_OC)
	$(hide) gunzip -c $(KERNEL_OUT_OC)/arch/arm/boot/compressed/piggy.gzip > $(KERNEL_OUT_OC)/piggy

$(TARGET_PREBUILT_INT_KERNEL_OC): $(KERNEL_OUT_OC) $(KERNEL_CONFIG_OC) $(KERNEL_HEADERS_INSTALL_OC)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) -j4
#	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) modules
#	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL_OC) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) modules_install
#	$(mv-modules_OC)
#	$(clean-module-folder_OC)
	$(append-dtb_OC)

$(KERNEL_HEADERS_INSTALL_OC): $(KERNEL_OUT_OC) $(KERNEL_CONFIG_OC)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) headers_install

kerneltags_OC: $(KERNEL_OUT_OC) $(KERNEL_CONFIG_OC)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) tags

kernelconfig_OC: $(KERNEL_OUT_OC) $(KERNEL_CONFIG_OC)
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) savedefconfig
	cp $(KERNEL_OUT_OC)/defconfig $(KERNEL_DIR)/arch/arm/configs/$(KERNEL_DEFCONFIG_OC)

endif #TARGET_PREBUILT_KERNEL_OC
endif #BOARD_KERNEL_MSM_OC

###################
# Kernel OC Ultra #
###################
ifeq ($(BOARD_KERNEL_MSM_OC_ULTRA),true)
ifeq ($(TARGET_PREBUILT_KERNEL_OC_ULTRA),)

KERNEL_OUT_OC_ULTRA := $(ANDROID_PRODUCT_OUT)/obj/KERNEL_OC_ULTRA_OBJ
KERNEL_CONFIG_OC_ULTRA := $(KERNEL_OUT_OC_ULTRA)/.config
TARGET_PREBUILT_INT_KERNEL_OC_ULTRA := $(KERNEL_OUT_OC_ULTRA)/arch/arm/boot/zImage
KERNEL_HEADERS_INSTALL_OC_ULTRA := $(KERNEL_OUT_OC_ULTRA)/usr
KERNEL_MODULES_INSTALL_OC_ULTRA := system
KERNEL_MODULES_OUT_OC_ULTRA := $(TARGET_OUT_OC_ULTRA)/lib/modules
KERNEL_IMG_OC_ULTRA=$(KERNEL_OUT_OC_ULTRA)/arch/arm/boot/Image

MSM_ARCH_OC_ULTRA ?= $(shell $(PERL) -e 'while (<>) {$$a = $$1 if /CONFIG_ARCH_((?:MSM|QSD)[a-zA-Z0-9]+)=y/; $$r = $$1 if /CONFIG_MSM_SOC_REV_(?!NONE)(\w+)=y/;} print lc("$$a$$r\n");' $(KERNEL_CONFIG_OC_ULTRA))
KERNEL_USE_OF_OC_ULTRA ?= $(shell $(PERL) -e '$$of = "n"; while (<>) { if (/CONFIG_USE_OF=y/) { $$of = "y"; break; } } print $$of;' $(KERNEL_DIR)/arch/arm/configs/$(KERNEL_DEFCONFIG_OC_ULTRA))

ifeq "$(KERNEL_USE_OF_OC_ULTRA)" "y"
DTS_NAME_OC_ULTRA ?= $(MSM_ARCH_OC_ULTRA)
DTS_FILES_OC_ULTRA = $(wildcard $(KERNEL_DIR)/arch/arm/boot/dts/$(DTS_NAME_OC_ULTRA)*.dts)
DTS_FILE_OC_ULTRA = $(lastword $(subst /, ,$(1)))
DTB_FILE_OC_ULTRA = $(addprefix $(KERNEL_OUT_OC_ULTRA)/arch/arm/boot/,$(patsubst %.dts,%.dtb,$(call DTS_FILE_OC_ULTRA,$(1))))
ZIMG_FILE_OC_ULTRA = $(addprefix $(KERNEL_OUT_OC_ULTRA)/arch/arm/boot/,$(patsubst %.dts,%-zImage,$(call DTS_FILE_OC_ULTRA,$(1))))
KERNEL_ZIMG_OC_ULTRA = $(KERNEL_OUT_OC_ULTRA)/arch/arm/boot/zImage
DTC_OC_ULTRA = $(KERNEL_OUT_OC_ULTRA)/scripts/dtc/dtc

define append-dtb_OC_ULTRA
mkdir -p $(KERNEL_OUT_OC_ULTRA)/arch/arm/boot;\
$(foreach d, $(DTS_FILES_OC_ULTRA), \
   $(DTC_OC_ULTRA) -p 1024 -O dtb -o $(call DTB_FILE_OC_ULTRA,$(d)) $(d); \
   cat $(KERNEL_ZIMG_OC_ULTRA) $(call DTB_FILE_OC_ULTRA,$(d)) > $(call ZIMG_FILE_OC_ULTRA,$(d));)
endef
else

define append-dtb_OC_ULTRA
endef
endif

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
$(info Using uncompressed kernel)
TARGET_PREBUILT_KERNEL_OC_ULTRA := $(KERNEL_OUT_OC_ULTRA)/piggy
else
TARGET_PREBUILT_KERNEL_OC_ULTRA := $(TARGET_PREBUILT_INT_KERNEL_OC_ULTRA)
endif

define mv-modules_OC_ULTRA
mdpath=`find $(KERNEL_MODULES_OUT_OC_ULTRA) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`;\
ko=`find $$mpath/kernel -type f -name *.ko`;\
for i in $$ko; do mv $$i $(KERNEL_MODULES_OUT_OC_ULTRA)/; done;\
fi
endef

define clean-module-folder_OC_ULTRA
mdpath=`find $(KERNEL_MODULES_OUT_OC_ULTRA) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`; rm -rf $$mpath;\
fi
endef

$(KERNEL_OUT_OC_ULTRA):
	mkdir -p $(KERNEL_OUT_OC_ULTRA)

$(KERNEL_CONFIG_OC_ULTRA): $(KERNEL_OUT_OC_ULTRA)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC_ULTRA) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) $(KERNEL_DEFCONFIG_OC_ULTRA)

$(KERNEL_OUT_OC_ULTRA)/piggy : $(TARGET_PREBUILT_INT_KERNEL_OC_ULTRA)
	$(hide) gunzip -c $(KERNEL_OUT_OC_ULTRA)/arch/arm/boot/compressed/piggy.gzip > $(KERNEL_OUT_OC_ULTRA)/piggy

$(TARGET_PREBUILT_INT_KERNEL_OC_ULTRA): $(KERNEL_OUT_OC_ULTRA) $(KERNEL_CONFIG_OC_ULTRA) $(KERNEL_HEADERS_INSTALL_OC_ULTRA)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC_ULTRA) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) -j4
#	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC_ULTRA) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) modules
#	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC_ULTRA) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL_OC_ULTRA) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) modules_install
#	$(mv-modules_OC_ULTRA)
#	$(clean-module-folder_OC_ULTRA)
	$(append-dtb_OC_ULTRA)

$(KERNEL_HEADERS_INSTALL_OC_ULTRA): $(KERNEL_OUT_OC_ULTRA) $(KERNEL_CONFIG_OC_ULTRA)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC_ULTRA) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) headers_install

kerneltags_OC_ULTRA: $(KERNEL_OUT_OC_ULTRA) $(KERNEL_CONFIG_OC_ULTRA)
	$(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) tags

kernelconfig_OC_ULTRA: $(KERNEL_OUT_OC_ULTRA) $(KERNEL_CONFIG_OC_ULTRA)
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC_ULTRA) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C $(KERNEL_DIR) O=$(KERNEL_OUT_OC_ULTRA) ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLS_PREFIX) savedefconfig
	cp $(KERNEL_OUT_OC_ULTRA)/defconfig $(KERNEL_DIR)/arch/arm/configs/$(KERNEL_DEFCONFIG_OC_ULTRA)

endif #TARGET_PREBUILT_KERNEL_OC_ULTRA
endif #BOARD_KERNEL_MSM_OC_ULTRA

endif #TARGET_NO_MULTIKERNEL
