#ifndef KERNELGEN_HPP
#define KERNELGEN_HPP

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

	// Generate the kernel source code.
	auto source = g.generate(ids.size());
	
	// TODO Compile the source code using external compiler.
}

#endif // KERNELGEN_HPP

