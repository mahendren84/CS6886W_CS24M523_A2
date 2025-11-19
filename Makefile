# ============================================================
# Makefile for Task 7 & Task 8
# ============================================================

MODEL     = ./gpt2-medium/gpt2-medium.gguf

# --- Task 7 ---
OUTDIR7   = $(HOME)/cs6886w_a2/perf_logs/task7
NAIVE     = ./llama.cpp/build_task3/bin/llama-bench
DEFAULT   = ./llama.cpp/build_task4/bin/llama-bench
MKL       = ./llama.cpp/build_task5/bin/llama-bench

VARIANTS  = naive default mkl

# --- Task 8 ---
OUTDIR8   = $(HOME)/cs6886w_a2/perf_logs/task8
THREADS   = 1 2 4 8 12 16 20 24 28 32

# --- Perf Events ---
PERF_EVENTS= fp_arith_inst_retired.scalar_single,fp_arith_inst_retired.scalar_double,fp_arith_inst_retired.128b_packed_single,fp_arith_inst_retired.128b_packed_double,fp_arith_inst_retired.256b_packed_single,fp_arith_inst_retired.256b_packed_double,fp_arith_inst_retired.512b_packed_single,fp_arith_inst_retired.512b_packed_double,fp_arith_inst_retired.vector,fp_arith_inst_retired.4_flops,fp_arith_inst_retired.8_flops,uncore_imc_free_running/data_read/,uncore_imc_free_running/data_write/,uncore_imc_free_running/data_total/,LLC-load-misses,LLC-store-misses,LLC-misses,offcore_requests.demand_data_rd

# ============================================================
# Top-level targets
# ============================================================

all: task7 task8

# ---------------- Task 7 ----------------
task7: prepare7 $(VARIANTS)

prepare7:
	mkdir -p $(OUTDIR7)

naive:
	@echo "=== Task 7: Naive Build ==="
	sudo perf stat -a -e $(PERF_EVENTS) \
		$(NAIVE) -m $(MODEL) -p 0 -n 256 -t 1 \
		| tee $(OUTDIR7)/task7_naive.txt

default:
	@echo "=== Task 7: Default Build ==="
	sudo perf stat -a -e $(PERF_EVENTS) \
		$(DEFAULT) -m $(MODEL) -p 0 -n 256 -t 1 \
		| tee $(OUTDIR7)/task7_default.txt

mkl:
	@echo "=== Task 7: MKL Build ==="
	sudo perf stat -a -e $(PERF_EVENTS) \
		$(MKL) -m $(MODEL) -p 0 -n 256 -t 1 \
		| tee $(OUTDIR7)/task7_mkl.txt

# ---------------- Task 8 ----------------
task8: prepare8 $(THREADS)

prepare8:
	mkdir -p $(OUTDIR8)

$(THREADS):
	@echo "=== Task 8: Scaling Benchmark — $@ threads ==="
	sudo perf stat -a -e $(PERF_EVENTS) \
		$(MKL) -m $(MODEL) -p 0 -n 256 -t $@ \
		| tee $(OUTDIR8)/task8_t$@.txt

# ---------------- Cleanup ----------------
clean:
	rm -rf $(OUTDIR7)/*.txt $(OUTDIR8)/*.txt

.PHONY: all clean prepare7 prepare8 task7 task8 $(VARIANTS) $(THREADS)

