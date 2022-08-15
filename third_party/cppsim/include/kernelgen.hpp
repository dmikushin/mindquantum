#ifndef KERNELGEN_HPP
#define KERNELGEN_HPP

#include "compiler.h"

#include <iostream>
#include <string>

class KernelGen
{
	std::string nointrin;

public :

	std::string generate(int nqubits);

	KernelGen();
};

// bit indices id[.] are given from high to low (e.g. control first for CNOT)
template <class V, class Id, class M>
void kernelgen(V &psi, Id ids, M const& m, std::size_t ctrlmask)
{
	static KernelGen g;

	const auto nqubits = ids.size();

	// Generate the kernel source code.
	auto source = g.generate(nqubits);
	
	// Compile the source code using external compiler.
	std::string errmsg;
	void* handle = get_compiler().codegen(nqubits, source, errmsg);
	if (!handle)
	{
		std::cerr << "Kernel generation has failed, aborting:" << std::endl;
		std::cerr << errmsg;
		exit(-1);
	}
	
	// TODO Call the generated kernel.
	// typedef (*kernel_t)(std::complex<double>* &psi, ???
}

#endif // KERNELGEN_HPP

