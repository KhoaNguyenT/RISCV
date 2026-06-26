# =============================================================
#  🚀 RISC-V RV32I 5-Stage Pipeline - Build System
# =============================================================
#  Flow:  .s → .o → .bin → .mem → Verilator → Simulate
# =============================================================

# ─── 1. DIRECTORY CONFIG ─────────────────────────────────────
HDL_DIR    ?= HDL
INC_DIR    ?= include
SIM_DIR    ?= sim
ASM_DIR    ?= $(SIM_DIR)/asm
HEX_DIR    ?= $(SIM_DIR)/hex
SCRIPT_DIR ?= $(SIM_DIR)/scripts
OBJ_DIR     = $(SIM_DIR)/obj_dir

# ─── 2. TOOLCHAIN CONFIG ────────────────────────────────────
# RISC-V Cross Compiler
TOOLCHAIN_PREFIX = riscv64-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP = $(TOOLCHAIN_PREFIX)objdump
SIZE      = $(TOOLCHAIN_PREFIX)size

# RV32I Architecture with Zicsr
RV_ARCH = rv32i_zicsr
RV_ABI  = ilp32

# Compiler flags: bare-metal RV32I, no stdlib
CFLAGS    = -march=$(RV_ARCH) -mabi=$(RV_ABI) -nostdlib -nostartfiles
CFLAGS   += -T $(SCRIPT_DIR)/link.ld

# Verilator
VERILATOR = verilator

# ─── 3. SIMULATION CONFIG ───────────────────────────────────
TOP_MODULE ?= tb_riscv_core
TEST       ?= testcase_hazards
WAVE_FILE  ?= $(SIM_DIR)/dump.fst

# Derived paths (auto-generated from TEST name)
ASM_FILE   = $(ASM_DIR)/$(TEST).s
ELF_FILE   = $(HEX_DIR)/$(TEST).elf
BIN_FILE   = $(HEX_DIR)/$(TEST).bin
MEM_FILE   = $(HEX_DIR)/$(TEST).mem
DUMP_FILE  = $(HEX_DIR)/$(TEST).dump
EXPECT_FILE= $(HEX_DIR)/$(TEST).expect.mem

# ─── 4. VERILATOR FLAGS ─────────────────────────────────────
VFLAGS  = -Wall
VFLAGS += --trace-fst
VFLAGS += --trace-structs
VFLAGS += --timing
VFLAGS += --binary
VFLAGS += --Mdir $(OBJ_DIR)
VFLAGS += +define+MEM_INIT_FILE=\"$(MEM_FILE)\"
VFLAGS += +define+EXPECT_INIT_FILE=\"$(EXPECT_FILE)\"
VFLAGS += -Wno-EOFNEWLINE -Wno-TIMESCALEMOD -Wno-WIDTHEXPAND
VFLAGS += -Wno-UNUSED -Wno-PINCONNECTEMPTY -Wno-DECLFILENAME -Wno-IMPORTSTAR

# ─── 5. SOURCE FILE DISCOVERY ───────────────────────────────
RTL_SRCS = $(shell find $(INC_DIR) -name "*_pkg.sv") $(shell find $(HDL_DIR) -name "*.sv" ! -name "Core.sv")
SIM_SRCS = $(shell find $(SIM_DIR) -name "*.v" -o -name "*.sv")
INC_FLAGS = +incdir+$(INC_DIR)
EXECUTABLE = $(OBJ_DIR)/V$(TOP_MODULE)

# ─── 6. ALL ASSEMBLY TEST DISCOVERY ─────────────────────────
ASM_TESTS = $(notdir $(basename $(wildcard $(ASM_DIR)/*.s)))

# =============================================================
#  TARGETS
# =============================================================
.PHONY: all asm build sim clean wave disasm list_tests help
.PHONY: $(addprefix test_,$(ASM_TESTS))

# ─── DEFAULT: Full flow ─────────────────────────────────────
all: asm build sim

# ─── STEP 1: Assemble .s → .elf → .bin → .mem ───────────────
asm: $(MEM_FILE)
	@echo ""

$(MEM_FILE): $(ASM_FILE) $(SCRIPT_DIR)/link.ld
	@echo "========================================="
	@echo "📝 Assembling: $(TEST).s"
	@echo "========================================="
	$(CC) $(CFLAGS) -o $(ELF_FILE) $(ASM_FILE)
	$(OBJCOPY) -O binary $(ELF_FILE) $(BIN_FILE)
	$(OBJDUMP) -d -M no-aliases $(ELF_FILE) > $(DUMP_FILE)
	python3 $(SCRIPT_DIR)/bin2mem.py $(BIN_FILE) $(MEM_FILE)
	python3 $(SCRIPT_DIR)/gen_expected.py $(ASM_FILE) $(EXPECT_FILE)
	@echo "📊 Code size:"
	@$(SIZE) $(ELF_FILE)
	@echo ""

# ─── STEP 2: Verilator compile ──────────────────────────────
build: asm
	@echo "========================================="
	@echo "🚀 Compiling RTL with Verilator..."
	@echo "========================================="
	$(VERILATOR) $(VFLAGS) $(INC_FLAGS) $(RTL_SRCS) $(SIM_SRCS) --top $(TOP_MODULE)

# ─── STEP 3: Run simulation ─────────────────────────────────
sim: build
	@echo "========================================="
	@echo "🏃 Running simulation: $(TEST)"
	@echo "========================================="
	./$(EXECUTABLE)

# ─── SHORTCUT: Run any test by name ─────────────────────────
# Usage: make test_hazards, make test_alu, make test_ls, make test_branch
$(addprefix test_,$(ASM_TESTS)):
	$(MAKE) all TEST=$(patsubst test_%,%,$@)

# ─── DISASSEMBLE: View generated machine code ───────────────
disasm: asm
	@echo "========================================="
	@echo "🔍 Disassembly of $(TEST):"
	@echo "========================================="
	@cat $(DUMP_FILE)

# ─── LIST: Show all available tests ─────────────────────────
list_tests:
	@echo "========================================="
	@echo "📋 Available test cases in $(ASM_DIR)/:"
	@echo "========================================="
	@for t in $(ASM_TESTS); do \
		echo "  make test_$$t"; \
	done
	@echo ""

# ─── WAVEFORM VIEWER ────────────────────────────────────────
wave:
	@if [ -f $(WAVE_FILE) ]; then \
		echo "📊 Opening waveform: $(WAVE_FILE)"; \
		gtkwave $(WAVE_FILE) & \
	else \
		echo "❌ Error: $(WAVE_FILE) not found!"; \
		echo "👉 Run a test first: make test_hazards"; \
	fi

# ─── CLEAN ───────────────────────────────────────────────────
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf $(OBJ_DIR)
	rm -f $(HEX_DIR)/*.elf $(HEX_DIR)/*.bin $(HEX_DIR)/*.dump
	rm -f *.vcd *.fst

clean_all: clean
	@echo "🧹 Also removing generated .mem files..."
	rm -f $(HEX_DIR)/*.mem

# ─── HELP ────────────────────────────────────────────────────
help:
	@echo "======================================================="
	@echo "    🚀 RISC-V RV32I+Zicsr PIPELINE BUILD SYSTEM 🚀"
	@echo "======================================================="
	@echo ""
	@echo "🌟 Quick Test — Native Core (default top: tb_riscv_core):"
	@for t in $(ASM_TESTS); do \
		echo "    make test_$$t"; \
	done
	@echo ""
	@echo "🔌 Quick Test — AXI4-Lite Wrapper (top: tb_riscv_axi):"
	@for t in $(ASM_TESTS); do \
		echo "    make test_$$t TOP_MODULE=tb_riscv_axi"; \
	done
	@echo ""
	@echo "🔧 Build Flow (.s → .elf → .bin → .mem → Verilator → sim):"
	@echo "    make all   TEST=<name>                : Full flow"
	@echo "    make asm   TEST=<name>                : Assemble only"
	@echo "    make build TEST=<name>                : Assemble + compile"
	@echo "    make sim   TEST=<name>                : Run simulation"
	@echo ""
	@echo "⚙️  Override Options:"
	@echo "    TOP_MODULE=tb_riscv_core              : Native pipeline (default)"
	@echo "    TOP_MODULE=tb_riscv_axi               : AXI4-Lite wrapper"
	@echo "    TEST=<name>                           : Test case name (default: $(TEST))"
	@echo ""
	@echo "🛠️  Utilities:"
	@echo "    make disasm TEST=<name>               : View disassembly"
	@echo "    make list_tests                       : List all .s tests"
	@echo "    make wave                             : Open waveform in GTKWave"
	@echo "    make clean                            : Remove build artifacts (keep .mem)"
	@echo "    make clean_all                        : Remove everything including .mem"
	@echo ""
	@echo "⚙️  Configuration:"
	@echo "    HDL_DIR    = $(HDL_DIR)"
	@echo "    SIM_DIR    = $(SIM_DIR)"
	@echo "    ASM_DIR    = $(ASM_DIR)"
	@echo "    TOP_MODULE = $(TOP_MODULE)"
	@echo "    TEST       = $(TEST)"
	@echo ""
	@echo "📌 Sample Runs:"
	@echo "  ┌──────────────────────────────────────────────────────────┐"
	@echo "  │ # Run hazard test on native core                         │"
	@echo "  │ $$ make test_testcase_hazards                            │"
	@echo "  │                                                          │"
	@echo "  │ # Run same test through AXI4-Lite wrapper                │"
	@echo "  │ $$ make test_testcase_hazards TOP_MODULE=tb_riscv_axi    │"
	@echo "  │                                                          │"
	@echo "  │ # Run CSR / trap / IRQ tests                             │"
	@echo "  │ $$ make test_testcase_csr                                │"
	@echo "  │ $$ make test_testcase_trap                               │"
	@echo "  │ $$ make test_testcase_irq                                │"
	@echo "  │                                                          │"
	@echo "  │ # Assemble only, no simulation                           │"
	@echo "  │ $$ make asm TEST=testcase_branch                         │"
	@echo "  │                                                          │"
	@echo "  │ # View generated machine code                            │"
	@echo "  │ $$ make disasm TEST=testcase_hazards                     │"
	@echo "  │                                                          │"
	@echo "  │ # Add a custom test: create sim/asm/my_test.s            │"
	@echo "  │ # then run it instantly:                                 │"
	@echo "  │ $$ make test_my_test                                     │"
	@echo "  └──────────────────────────────────────────────────────────┘"
	@echo "======================================================="