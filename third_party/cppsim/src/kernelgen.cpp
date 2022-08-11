#include "kernelgen.hpp"
#include "res_embed.h"

#include <pybind11/eval.h>

namespace py = pybind11;

std::string KernelGen::generate(int nqubits)
{
	// TODO Use embedded Python interpreter to run the script
	// and get the resulting string of source code.
	// We intentionally keep the generator in Python, in order
	// to let the people to customize it more easily.
	py::object scope = py::module_::import("__main__").attr("__dict__");
	py::eval(nointrin, scope);
}

namespace res {

namespace embed {

namespace init {

void nointrin();

} // namespace init

} // namespace embed

} // namespace res

KernelGen::KernelGen()
{
	// Extract the Python script.
	res::embed::init::nointrin();
	size_t size = 0;
	auto source = res::embed::get("nointrin", &size);
	nointrin = std::string(source, size);
}

