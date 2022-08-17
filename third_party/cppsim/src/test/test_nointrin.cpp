// Ensure hand-written and generated kernels give equal results.

#include "nointrin/kernels.hpp"

namespace generated {

#include "generated/nointrin/kernel1.hpp"
#include "generated/nointrin/kernel2.hpp"
#include "generated/nointrin/kernel3.hpp"
#include "generated/nointrin/kernel4.hpp"
#include "generated/nointrin/kernel5.hpp"

} // namespace generated

#include <array>
#include <iostream>
#include <random>

#include "gtest/gtest.h"

template<int nqubits, typename Kernels, typename V>
bool compare(Kernels kernels, V& psi1)
{
	std::default_random_engine dre;
	std::uniform_int_distribution<int> uid(0, 1000);

	// Generate m matrix as integers.
	std::array<std::array<int, nqubits>, nqubits> m;
	for (int j = 0; j < m.size(); j++)
		for (int i = 0; i < m.size(); i++)
			m[j][i] = uid(dre);

	// Generate psi matrix as integers.
	for (int i = 0; i < psi1.size(); i++)
		psi1[i] = uid(dre);
	auto psi2 = psi1;

	// Generate control mask.
	std::size_t ctrlmask = 0; // uid(dre);

	// Compare kernel against generated kernel.
	kernels(psi1, psi2, m, ctrlmask);
	auto diff = std::mismatch(psi1.begin(), psi1.end(), psi2.begin());
	if (diff.first == psi1.end())
		return true;

	std::cout << "Mismatch at " << std::distance(psi1.begin(), diff.first) <<
		" : " << *(diff.first) << " != " << *(diff.second) << std::endl;
	return false;
}

TEST(nointrin, kernel1)
{
	unsigned id0 = 0;
	size_t n = 1;
	n += 1UL << id0;
	std::vector<int> psi(n);
	ASSERT_TRUE(compare<1>([&](auto& psi1, auto& psi2, auto m, auto ctrlmask)
	{
		kernel(psi1, id0, m, ctrlmask);
		generated::kernel(&psi2[0], id0, &m[0][0], ctrlmask);
	},
	psi));
}

TEST(nointrin, kernel2)
{
	unsigned id0 = 0, id1 = 1;
	size_t n = 1;
	n += 1UL << id0;
	n += 1UL << id1;
	std::vector<int> psi(n);
	ASSERT_TRUE(compare<2>([&](auto& psi1, auto& psi2, auto m, auto ctrlmask)
	{
		kernel(psi1, id1, id0, m, ctrlmask);
		generated::kernel(&psi2[0], id1, id0, &m[0][0], ctrlmask);
	},
	psi));
}

TEST(nointrin, kernel3)
{
	unsigned id0 = 0, id1 = 1, id2 = 2;
	size_t n = 1;
	n += 1UL << id0;
	n += 1UL << id1;
	n += 1UL << id2;
	std::vector<int> psi(n);
	ASSERT_TRUE(compare<3>([&](auto& psi1, auto& psi2, auto m, auto ctrlmask)
	{
		kernel(psi1, id2, id1, id0, m, ctrlmask);
		generated::kernel(&psi2[0], id2, id1, id0, &m[0][0], ctrlmask);
	},
	psi));
}

TEST(nointrin, kernel4)
{
	unsigned id0 = 0, id1 = 1, id2 = 2, id3 = 3;
	size_t n = 1;
	n += 1UL << id0;
	n += 1UL << id1;
	n += 1UL << id2;
	n += 1UL << id3;
	std::vector<int> psi(n);
	ASSERT_TRUE(compare<4>([&](auto& psi1, auto& psi2, auto m, auto ctrlmask)
	{
		kernel(psi1, id3, id2, id1, id0, m, ctrlmask);
		generated::kernel(&psi2[0], id3, id2, id1, id0, &m[0][0], ctrlmask);
	},
	psi));
}

TEST(nointrin, kernel5)
{
	unsigned id0 = 0, id1 = 1, id2 = 2, id3 = 3, id4 = 4;
	size_t n = 1;
	n += 1UL << id0;
	n += 1UL << id1;
	n += 1UL << id2;
	n += 1UL << id3;
	n += 1UL << id4;
	std::vector<int> psi(n);
	ASSERT_TRUE(compare<5>([&](auto& psi1, auto& psi2, auto m, auto ctrlmask)
	{
		kernel(psi1, id4, id3, id2, id1, id0, m, ctrlmask);
		generated::kernel(&psi2[0], id4, id3, id2, id1, id0, &m[0][0], ctrlmask);
	},
	psi));
}

int main(int argc, char* argv[])
{
	::testing::InitGoogleTest(&argc, argv);
	return RUN_ALL_TESTS();
}

