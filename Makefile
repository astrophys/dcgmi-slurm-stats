# To compile :
#   ml load nvhpc-hpcx-cuda12/23.9
#
#
###### mpi_matrix_mult ######
LIB_MPI = -L/${OPAL_PREFIX}/lib -lmpi
CXXFLAGS = -Wall -g
PREFIX_MPI = src/mpi
CC = mpic++
NVCC = nvcc
NVCCFLAGS = --compiler-options ${CXXFLAGS} -I${CPATH} -I${CUDA_INC_PATH}/include 

OBJ_DIR_MPI = $(PREFIX_MPI)/obj
OBJ_MPI = $(OBJ_DIR_MPI)/mpi_matrix_mult.o $(OBJ_DIR_MPI)/functions.o $(OBJ_DIR_MPI)/cpu_mult.o $(OBJ_DIR_MPI)/gpu_mult.o

# E.g. of working compilation nvcc -I/cm/shared/apps/openmpi4/gcc/4.1.2/include -I${CUDA_INC_PATH}/include -L/cm/local/apps/cuda/libs/current/lib64 -L/cm/shared/apps/openmpi4/gcc/4.1.2/lib -lmpi -o mpi_matrix_mult src/obj/mpi_matrix_mult.o


###### hello world ######
OBJ_HELLO=$(OBJ_DIR_MPI)/hello.o $(OBJ_DIR_MPI)/functions.o 



###### nccl_matrix_mult ######
PREFIX_NCCL = src/nccl
LIB_NCCL = -L/home/${USER}/software/hpc_sdk_2023_239/Linux_x86_64/23.9/comm_libs/12.2/nccl/lib/ -lnccl
OBJ_DIR_NCCL = $(PREFIX_NCCL)/obj
OBJ_NCCL = $(OBJ_DIR_NCCL)/nccl_matrix_mult.o

all: mpi_matrix_mult

# Compile straight C++ files
$(OBJ_DIR_MPI)/%.o : $(PREFIX_MPI)/%.cu
	$(NVCC) $(NVCCFLAGS) $(CPLUS_INCLUDE_PATH) -dc $< -o $@

mpi_matrix_mult : $(OBJ_MPI)
	$(NVCC) $(NVCCFLAGS) $(CPLUS_INCLUDE_PATH) -o mpi_matrix_mult $(LIB_MPI) $(OBJ_MPI)

$(OBJ_DIR_NCCL)/%.o : $(PREFIX_NCCL)/%.cu
	$(NVCC) $(NVCCFLAGS) $(CPLUS_INCLUDE_PATH) -dc $< -o $@

clean :
	rm $(OBJ_MPI) mpi_matrix_mult
