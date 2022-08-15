#include "compiler.h"
#include "tempfile.h"
#include "digestpp.hpp"

#include <cstdlib>
#include <dlfcn.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <streambuf>

namespace fs = std::filesystem;

Compiler::Compiler() { }

class Signature
{
	int nqubits;
	std::string source;

	std::string hash_;

public :

	const std::string& hash() const { return hash_; }

	Signature(
		int nqubits_,
		const std::string& source_) :
	
	nqubits(nqubits_),
	source(source_)
	
	{
		std::stringstream ss;
		// TODO Absorb individually.
	       	ss << digestpp::sha512().absorb(reinterpret_cast<char*>(this), sizeof(Signature)).hexdigest();
		hash_ = ss.str();
	}
};

static std::map<std::string, void*> database;

void* Compiler::codegen(
	int nqubits,
	const std::string& source,
	std::string& errmsg)
{
	std::error_code ec;

	// 0) Check whether the kernel has been already compiled for the
	// requested dimensions.
	auto hash = Signature(nqubits, source).hash();
	auto existing = database.find(hash);
	if (existing != database.end())
		return existing->second;

	// 1) Create source file.
	const char* filenameTemplate = "kernelgenXXXXXX";
	std::string filename = TempFile(filenameTemplate).string(ec);
	if (ec) return nullptr;
	{
		std::stringstream ss;

		// Add the content of engine include file.
		ss << "#include <algorithm>";
		ss << std::endl;
		ss << "#include <array>";
		ss << std::endl;
		ss << "#include <complex>";
		ss << std::endl;
		ss << "#include <cstdlib>";
		ss << std::endl;
		ss << std::endl;

		// Add source code.
		ss << source;
		
		// Add template specializations.
		for (auto type : std::array {
			std::make_pair("std::complex<double>", "double"),
			std::make_pair("int", "int")
		})
		{
			// Add specialization.
			ss << "template<> void kernel<";
			ss << type.first;
			ss << "*, std::array<std::array<int, ";
			ss << nqubits;
			ss << ">, ";
			ss << nqubits;
			ss << "> >(";
			ss << type.first;
			ss << "* &psi, " << std::endl;
			for (int i = 0; i < nqubits; i++)
			{
				ss << "unsigned id";
				ss << nqubits - i - 1;
				ss << ", ";
			}
			ss << "std::array<std::array<int, ";
			ss << nqubits;
			ss << ">, ";
			ss << nqubits;
			ss << "> const& m, std::size_t ctrlmask);";
			ss << std::endl << std::endl;
			
			// Adding entrypoint.
			ss << "extern \"C\" void kernel_";
			ss << type.second;
			ss << "(";
			ss << type.second;
			ss << "* psi, std::array<unsigned, ";
			ss << nqubits;
			ss << "> ids, std::array<std::array<int, ";
			ss << nqubits;
			ss << ">, ";
			ss << nqubits;
			ss << "> const& m, std::size_t ctrlmask)";
			ss << std::endl;
			ss << "{";
			ss << std::endl;
			ss << "\tkernel(reinterpret_cast<";
			ss << type.first;
			ss << "*&>(psi), ";
			for (int i = 0; i < nqubits; i++)
			{
				ss << "ids[";
				ss << nqubits - i - 1;
				ss << "], ";
			}
			ss << "m, ctrlmask);";
			ss << std::endl;
			ss << "}";
			ss << std::endl;
		}
			
		const std::string& source = ss.str();
#if 1
		std::cout << source << std::endl;
#endif
		std::ofstream file(filename);
		file << source;
	}

	// 2) Compile source file into a shared library
	std::string binname = TempFile(filenameTemplate).string(ec);
	if (ec) return nullptr;
	{
		std::string errlog = TempFile(filenameTemplate).string(ec);
		if (ec) return nullptr;

		std::stringstream ss;
#ifdef __APPLE__
		ss << "g++-11";
#else
		ss << "g++";
#endif
#if 1
		ss << " -g -O0 -std=c++17 -x c++ ";
#else
		ss << " -g -O3 -ffast-math -fopenmp -std=c++17 -x c++ ";
#endif
		ss << filename;
		ss << " -fPIC -shared -o";
		ss << binname;
		ss << " >";
		ss << errlog;
		
		const std::string command = ss.str();
		system(command.c_str());

		// If the output log file is not empty, read its contents,
		// and put into errmsg.
		if (fs::exists(errlog))
		{
			std::ifstream file(errlog);
			errmsg = std::string((std::istreambuf_iterator<char>(file)),
				std::istreambuf_iterator<char>());
		}
	}

	// 3) Load shared library and bind its entry point
	void* handle = nullptr;
	{
		// If the output file does not exist, return NULL.
		if (!fs::exists(binname))
			return nullptr;

		// If the shared library could not be loaded, return NULL.
		void* lib = dlopen(binname.c_str(), RTLD_NOW);
		if (!lib)
		{
			std::stringstream ss;
			ss << "Could not open \"" << binname <<
				"\" as a shared library: \"" << dlerror() << "\"" << std::endl;
			errmsg += ss.str();
			return nullptr;
		}

		// TODO If the symbol does not exist, return NULL.
		handle = dlsym(lib, "kernel_double");
		if (!handle)
		{
			std::stringstream ss;
			ss << "Could not bind symbol \"model_solve\" in shared library \"" <<
				binname << "\": \"" << dlerror() << "\"" << std::endl;
			errmsg += ss.str();
			return nullptr;
		}
	}

	// 4) Cache the compiled eskew kernel in our internal database,
	// so that we could use it again without recompilation, should the same
	// dimensions be requested.
	database[hash] = handle;

	return handle;
}

Compiler& get_compiler()
{
	static Compiler compiler;
	return compiler;
}

