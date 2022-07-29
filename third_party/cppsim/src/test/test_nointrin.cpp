#include "nointrin/kernels.hpp"

namespace generated {

#include "generated/nointrin/kernel1.hpp"
#include "generated/nointrin/kernel2.hpp"
#include "generated/nointrin/kernel3.hpp"
#include "generated/nointrin/kernel4.hpp"
#include "generated/nointrin/kernel5.hpp"

} // namespace generated

#include <array>
#include <random>

#include "gtest/gtest.h"

template<int nqubits>
bool compare()
{
	constexpr auto dim = 1UL << nqubits;
	
	std::default_random_engine dre;
	std::uniform_int_distribution<int> uid(0, 1000);

	// TODO Generate m matrix as integers.
	std::array<std::array<int, nqubits>, nqubits> m;
	for (int j = 0; j < m.size(); j++)
		for (int i = 0; i < m.size(); i++)
			m[j][i] = uid(dre);
	
	// TODO Generate id_0...id_nq integers (unsorted).
	unsigned id0 = 0, id1 = 1, id2 = 2, id3 = 3, id4 = 4;

	// TODO Generate psi matrix as integers.
	std::array<int, nqubits> psi;
	for (int i = 0; i < m.size(); i++)
		psi[i] = uid(dre);

	// Generate control mask.	
	std::size_t ctrlmask = uid(dre); 
	
	// TODO Compare kernel against generated kernel
	kernel(psi, id0, m, ctrlmask);
	kernel(psi, id1, id0, m, ctrlmask);
	kernel(psi, id2, id1, id0, m, ctrlmask);
	kernel(psi, id3, id2, id1, id0, m, ctrlmask);
	kernel(psi, id4, id3, id2, id1, id0, m, ctrlmask);
	return true;
}

TEST(nointrin, kernel1)
{
	ASSERT_TRUE(compare<1>());
}

TEST(nointrin, kernel2)
{
	ASSERT_TRUE(compare<2>());
}

TEST(nointrin, kernel3)
{
	ASSERT_TRUE(compare<3>());
}

TEST(nointrin, kernel4)
{
	ASSERT_TRUE(compare<4>());
}

TEST(nointrin, kernel5)
{
	ASSERT_TRUE(compare<5>());
}

int main(int argc, char* argv[])
{
	::testing::InitGoogleTest( & argc, argv);
	return RUN_ALL_TESTS();
}

